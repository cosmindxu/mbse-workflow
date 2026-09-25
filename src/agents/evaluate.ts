/**
 * Choosing between the architectures, and saying why.
 *
 * Three inputs, deliberately: the measures the brief declared (decided by the
 * solver where they are encodable), the structure of each candidate (size,
 * coupling, how much of the layer above it realises), and a rubric the model
 * scores. The weighted sum picks; the model's own recommendation is one input
 * to that, not the decision — an LLM asked to choose between two things it
 * wrote will choose, and this is where that would go unexamined.
 *
 * The rationale goes into the model as well as the packet. A trade-off that
 * lives only in a report is a trade-off the next reader of the model will
 * re-open.
 */
import { boundText, meets, scoredMoes, worstCase, worstCaseSense } from '../spec/measures.ts';
import { copyFileSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { assemble } from '../model/assembler.ts';
import { insertBeforeClose } from '../model/fragments.ts';
import { matchingBrace } from '../model/statements.ts';
import { EvaluateOutputSchema, type EvaluateOutput } from '../llm/schemas.ts';
import { modelFor } from '../config/load.ts';
import type { Layer } from '../spec/layers.ts';
import type { StepSpec } from '../spec/steps.ts';
import type { AgentContext } from './context.ts';
import { replicaFacts } from '../check/replicas.ts';

export interface AlternativeMetrics {
  k: number;
  elements: number;
  connections: number;
  unconnectedPorts: number;
  orphanDefinitions: number;
  functionsRealised: number;
  functionsAbove: number;
  repairIterations: number;
  warnings: number;
  /** Hazards this alternative's layer tags #Accepted rather than mitigates. */
  acceptedHazards?: number;
  /**
   * Each measure as this alternative states it: the worst case `bounds` finds
   * over the alternative's own `#Estimate`, and whether that meets the target.
   */
  moes: Array<{ name: string; outcome: string; value?: number; sense: 'min' | 'max'; target: number; unit: string; met?: boolean; basis?: string; detail?: string }>;
  /** Where coordination and command and control sit, when the system is a population. */
  population?: { peerLinks: number; onBoard: number; tagged: number; fleet?: string; acceptedHazards: number };
}

/**
 * The two criteria the command-and-control decision is scored on.
 *
 * Named, and weighted on their own: folded into the rubric mean they would be
 * two votes among six, and the decision the brief asks this comparison to make
 * — what survives the ground link dropping, what survives the ground node
 * failing — would be diluted by cohesion and coupling.
 */
export const RESILIENCE_CRITERIA = ['groundLinkLossResilience', 'groundNodeLossResilience'] as const;

export interface EvaluationResult {
  chosen: number;
  metrics: AlternativeMetrics[];
  scores: Array<{ k: number; total: number; moe: number; rubric: number; structure: number; resilience: number }>;
  rubric: EvaluateOutput;
  overrode: boolean;
  rationalePath: string;
}

export async function evaluateAlternatives(
  ctx: AgentContext,
  step: StepSpec,
  layer: Layer,
  candidates: Array<{ k: number; iterations: number }>,
  /** Every alternative the layer attempted, viable or not. */
  attempted: Array<{ k: number; status: string }> = [],
): Promise<EvaluationResult> {
  const metrics: AlternativeMetrics[] = [];
  for (const candidate of candidates) {
    // Serial: one loaded model at a time, and each of these is a full load.
    metrics.push(await measure(ctx, step.id, layer, candidate.k, candidate.iterations));
  }

  const rubric = await ctx.llm.complete({
    tag: `${step.id}:EVALUATE`,
    system: [
      'You are comparing architecture alternatives for one layer of a systems model.',
      'You are not choosing the winner: a weighted score does that, and your rubric is one of its inputs. What is wanted from you is the judgement no measurement makes — whether a split of responsibilities is coherent, whether it will survive the next layer, what it costs to change later.',
      'Score each alternative 1-5 on: cohesion (does each component have one job), coupling (how much has to cross a boundary), realisability (can this be built and procured as separate items), and evolvability (what happens when a requirement changes).',
      ...(ctx.state.brief?.population
        ? [
            `The system is a population of ${ctx.state.brief.population.size} members, and where command and control lives is the decision this comparison exists for. Also score, 1-5, under exactly these names: groundLinkLossResilience (what coordination and command and control keep working, and for how long, when the link to the operations centre drops — hold it against the link-outage measure) and groundNodeLossResilience (what happens when the ground station or ground coordinator itself fails: coverage kept, a controlled landing, or members flying their last assignment — hold it against the coverage-restoration measure and the accepted hazards). Judge what the model says, not what the design could have said.`,
          ]
        : []),
      'Be specific about which component you mean. A reviewer reads your rationale before they read the model.',
    ].join('\n'),
    user: rubricPrompt(ctx, step, layer, metrics),
    schema: EvaluateOutputSchema,
    model: modelFor(ctx.config, 'EVALUATE'),
    timeoutMs: ctx.config.limits.llm_call_timeout_ms,
  });

  const weights = ctx.config.evaluate.weights;
  const scores = metrics.map((m) => {
    const moe = moeScore(m);
    const penalty = acceptancePenalty(m.acceptedHazards ?? 0, ctx.config.evaluate.accepted_hazard_penalty);
    const structure = Math.max(0, structureScore(m, metrics) - penalty);
    const rubricScore = rubricFor(rubric.data, m.k);
    const resilience = resilienceFor(rubric.data, m.k);
    return {
      k: m.k,
      moe,
      rubric: rubricScore,
      structure,
      resilience,
      total: weights.moe * moe + weights.rubric * rubricScore + weights.structure * structure + (weights.resilience ?? 0) * resilience,
    };
  });
  const best = [...scores].sort((a, b) => b.total - a.total || a.k - b.k)[0];
  const chosen = best.k;

  // The chosen alternative becomes the layer, with the comparison written into
  // it. Everything that was measured stays in the packet beside it.
  const source = ctx.layout.fragmentPath(layer, chosen);
  const target = ctx.layout.fragmentPath(layer);
  copyFileSync(source, target);
  // Replace, never add beside: a layer evaluated twice — a resume, a re-run
  // of the alternatives — carried the earlier decision into the head, and the
  // second record was a duplicate name that blocked the step it had just won.
  const previous = readFileSync(target, 'utf8');
  writeFileSync(
    target,
    insertBeforeClose(withoutTradeOff(previous, layer), tradeOffElement(layer, chosen, scores, rubric.data)),
  );

  const auditDir = ctx.layout.auditDirFor(step.id);
  mkdirSync(auditDir, { recursive: true });
  // Its own file: the step's `rationale.md` is the agent's account of the step,
  // and the trade-off is the comparison a reviewer opens first.
  const rationalePath = resolve(auditDir, 'trade-off.md');
  writeFileSync(rationalePath, rationaleFor(layer, chosen, metrics, scores, rubric.data, ctx.config.evaluate.accepted_hazard_penalty, attempted));
  if (metrics.length < 2) {
    ctx.log(
      `  only ${metrics.length} of ${Math.max(attempted.length, metrics.length)} alternative(s) were viable: ` +
        'this decision was made by elimination, not by comparison',
    );
  }

  return {
    chosen,
    metrics,
    scores,
    rubric: rubric.data,
    overrode: rubric.data.recommended !== chosen,
    rationalePath,
  };
}

/** The fragment without its `#prose part <layer>TradeOff { … }`, if it has one. */
export function withoutTradeOff(fragment: string, layer: Layer): string {
  const open = new RegExp(`^[ \\t]*#prose part ${layer.toLowerCase()}TradeOff\\s*\\{`, 'm');
  const m = open.exec(fragment);
  if (!m) return fragment;
  const close = matchingBrace(fragment, fragment.indexOf('{', m.index));
  if (close < 0) return fragment;
  const lineEnd = fragment.indexOf('\n', close);
  return fragment.slice(0, m.index) + fragment.slice(lineEnd < 0 ? fragment.length : lineEnd + 1);
}

/* ────────────────────────────── measurement ─────────────────────────────── */

async function measure(ctx: AgentContext, stepId: StepSpec["id"], layer: Layer, k: number, iterations: number): Promise<AlternativeMetrics> {
  const fragment = readFileSync(ctx.layout.fragmentPath(layer, k), 'utf8');
  const assembly = assemble(ctx.layout, layer, { substitute: { [layer]: fragment } });
  const at = `${ctx.layout.root}::${layer}::`;
  const moeSpecs = scoredMoes(ctx.state.brief?.moes ?? []);

  return ctx.backend.withModel(assembly.text, `alt-${k}`, async (m) => {
    const stats = ctx.backend.stats(m);
    const connectivity = ctx.backend.connectivity(m);
    const orphans = ctx.backend.orphans(m);
    const trace = ctx.backend.trace(m, 'trace');
    const elements = ctx.backend.elements(m);
    // A trace links upper -> lower, so a link whose target is in this layer
    // is this layer realising something above. Counted as distinct FUNCTIONS
    // of the layer, not as links: measured, 44 links over 21 functions gave a
    // completeness of 2.1 and a "0..1" structure score of 1.31.
    const functions = new Set(
      elements
        .filter((e) => e.metaclass === 'ActionUsage' && e.qualifiedName.startsWith(at) && !e.qualifiedName.slice(at.length).includes('::'))
        .map((e) => e.qualifiedName),
    );
    const realised = new Set(trace.links.map((l) => l.toName).filter((qn) => functions.has(qn)));
    const functionsAbove = functions.size;

    const moes: AlternativeMetrics['moes'] = [];
    const boundsDir = resolve(ctx.layout.auditDirFor(stepId), `alt-${k}`);
    for (const moe of moeSpecs) {
      // Reported, never blocking (Q-04); the estimate itself is gated at the
      // alternatives step. What is bounded is this alternative's own
      // `#Estimate`, never Common's attribute: a subsetting attribute gives
      // Common no value, so bounding Common decides nothing (probed).
      const measureName = `${at}${moe.name}`;
      const base = { name: moe.name, sense: moe.sense, target: moe.target, unit: moe.unit };
      const basis = elements.find((e) => e.qualifiedName === measureName)?.doc || undefined;
      try {
        mkdirSync(boundsDir, { recursive: true });
        const result = await worstCase(async (sense) => {
          const report = await ctx.backend.bounds(m, measureName, sense);
          // The worst-case report keeps the name every earlier run used; the
          // other sense, asked only for a derived estimate, gets its own.
          const file = sense === worstCaseSense(moe.sense) ? `bounds-${moe.name}.json` : `bounds-${moe.name}.${sense}.json`;
          writeFileSync(resolve(boundsDir, file), `${JSON.stringify(report, null, 2)}\n`);
          return report.bounds[0];
        }, moe.sense);
        moes.push({ ...base, outcome: result.outcome, value: result.value, met: meets(moe, result.outcome, result.value), basis, detail: result.detail });
      } catch (err) {
        // A name `bounds` cannot resolve is an estimate that was never written.
        moes.push({ ...base, outcome: 'no estimate', basis, detail: err instanceof Error ? err.message : String(err) });
      }
    }

    const tags = ctx.backend.tags(m);
    const acceptedHazards = tags.taggedWith('Accepted').filter((qn) => qn.startsWith(at)).length;
    const p = ctx.state.brief?.population;
    let population: AlternativeMetrics['population'];
    if (p) {
      // Counted by the same helper the gates use, so the score reads the
      // alternative the gates passed.
      const f = replicaFacts(ctx.backend.layerView(m, layer), elements, p);
      population = {
        peerLinks: f.peerLinks.length,
        // By definition: the member halves of an activity sit on the members
        // in any design, and counted by usage they hid the decision.
        onBoard: f.types.filter((t) => t.place === 'on board').length,
        tagged: f.types.length,
        fleet: f.fleet?.multiplicity,
        acceptedHazards,
      };
    }

    return {
      k,
      population,
      elements: stats.nodeCount,
      connections: connectivity.connectionCount,
      unconnectedPorts: connectivity.unconnectedPorts.filter((p) => p.qualifiedName.startsWith(at)).length,
      orphanDefinitions: orphans.orphans.filter((o) => o.qualifiedName.startsWith(at)).length,
      functionsRealised: realised.size,
      functionsAbove,
      repairIterations: iterations,
      warnings: m.report.summary.warnings,
      acceptedHazards,
      moes,
    };
  });
}

/* ──────────────────────────────── scoring ───────────────────────────────── */

/**
 * Measures that score every alternative the same.
 *
 * A trade-off is a comparison, and a measure with the same estimate on both
 * sides contributes nothing to it: it is scored, it moves no score, and it
 * leaves the reader believing the alternatives were examined on it. In v7's PA
 * trade-off, four of the fourteen measures scored both alternatives identically
 * — `reportLatencySeconds`, `reportsLostInLinkGap`, `missedDetectionShare` and
 * `falseAlarmsPerHour` — so a third of the comparison was decided by nothing.
 *
 * This does not say the estimates are wrong, and it is not an accusation that
 * the decisive measure failed: v7's did its job, separating the alternatives
 * 0.55 against 0.91. It says which measures the comparison learned nothing
 * from, which is a fact about the trade-off and belongs in it.
 */
export function measuresThatDoNotDiscriminate(
  metrics: AlternativeMetrics[],
): Array<{ name: string; value?: number; outcome: string }> {
  if (metrics.length < 2) return [];
  const first = metrics[0];
  return first.moes
    .filter((measure) => {
      const others = metrics.slice(1).map((m) => m.moes.find((x) => x.name === measure.name));
      if (others.some((o) => o === undefined)) return false;
      return others.every(
        (o) =>
          o!.outcome === measure.outcome &&
          ((o!.value === undefined && measure.value === undefined) ||
            (o!.value !== undefined &&
              measure.value !== undefined &&
              Math.abs(o!.value - measure.value) <= 1e-9 * Math.max(1, Math.abs(measure.value)))),
      );
    })
    .map((m) => ({ name: m.name, value: m.value, outcome: m.outcome }));
}


/**
 * 0..1 — the mean over measures of 1 when the worst case meets the target, 0
 * when it misses, and ½ when the solver could not decide.
 *
 * Measured, before: the verdict was read from a field the tool does not emit,
 * so every measure was "undecided" and this returned 0.5 for every alternative
 * of every run — a 0.4 weight that never discriminated.
 */
export function moeScore(m: Pick<AlternativeMetrics, 'moes'>): number {
  if (m.moes.length === 0) return 0.5;
  return m.moes.reduce((sum, x) => sum + (x.met === undefined ? 0.5 : x.met ? 1 : 0), 0) / m.moes.length;
}

/** What accepting `n` hazards takes off the structure score. */
export function acceptancePenalty(n: number, cost: { per: number; cap: number }): number {
  return Math.min(cost.cap, Math.max(0, n) * cost.per);
}

/** 0..1 — smaller, less coupled, more complete, fewer repairs. */
function structureScore(m: AlternativeMetrics, all: AlternativeMetrics[]): number {
  const best = (values: number[]): number => Math.min(...values);
  const completeness = m.functionsAbove === 0 ? 1 : Math.min(1, m.functionsRealised / m.functionsAbove);
  const coupling = ratio(best(all.map((x) => x.connections)), m.connections);
  const size = ratio(best(all.map((x) => x.elements)), m.elements);
  const clean = m.unconnectedPorts + m.orphanDefinitions === 0 ? 1 : 0.5;
  const repairs = m.repairIterations === 0 ? 1 : 1 / (1 + m.repairIterations);
  return (completeness * 3 + coupling + size + clean + repairs) / 7;
}

const ratio = (best: number, actual: number): number => (actual <= 0 ? 1 : Math.min(1, best / actual));

const isResilience = (name: string): boolean => (RESILIENCE_CRITERIA as readonly string[]).includes(name);

/** 0..1 — the model's own scores, averaged, resilience excluded (it is weighted on its own). */
function rubricFor(rubric: EvaluateOutput, k: number): number {
  const entry = rubric.scores.find((s) => s.alternative === k);
  const criteria = entry?.criteria.filter((c) => !isResilience(c.name)) ?? [];
  if (criteria.length === 0) return 0.5;
  const mean = criteria.reduce((sum, c) => sum + c.score, 0) / criteria.length;
  return (mean - 1) / 4;
}

/** 0..1 — the two resilience criteria, averaged; neutral when they were not scored. */
export function resilienceFor(rubric: EvaluateOutput, k: number): number {
  const entry = rubric.scores.find((s) => s.alternative === k);
  const criteria = entry?.criteria.filter((c) => isResilience(c.name)) ?? [];
  if (criteria.length === 0) return 0.5;
  const mean = criteria.reduce((sum, c) => sum + c.score, 0) / criteria.length;
  return (mean - 1) / 4;
}

/* ─────────────────────────────── reporting ──────────────────────────────── */

export function rubricPrompt(ctx: AgentContext, step: StepSpec, layer: Layer, metrics: AlternativeMetrics[]): string {
  const lines: string[] = [];
  // What a person said when they rejected this comparison. Their comment used
  // to be written into the layer's fragment, which this step then overwrote
  // with the chosen alternative — so a rejection at G-LA or G-PA re-ran the
  // same rubric on the same inputs and the comment was never read by anything.
  const comments = ctx.state.gateComments?.[step.id] ?? [];
  if (comments.length > 0) {
    lines.push(
      '## What a reviewer said about the last comparison',
      '',
      'This comparison was rejected. Read these first, and say in each rationale what you did about them — agreeing is an answer, as long as it is argued.',
      '',
      ...comments.map((c) => `- ${c}`),
      '',
    );
  }
  lines.push('## The alternatives', '');
  for (const m of metrics) {
    lines.push(
      `### Alternative ${m.k}`,
      '',
      '```',
      readFileSync(ctx.layout.fragmentPath(layer, m.k), 'utf8').trimEnd(),
      '```',
      '',
      `Measured: ${m.elements} elements, ${m.connections} connections, ${m.unconnectedPorts} unconnected ports, ${m.orphanDefinitions} unused definitions, realises ${m.functionsRealised} of ${m.functionsAbove} functions, needed ${m.repairIterations} repair round(s), accepts ${m.acceptedHazards ?? 0} hazard(s) rather than mitigating them (each costs structure score).`,
      ...(m.population
        ? [
            `Command and control: ${m.population.onBoard} of ${m.population.tagged} coordination and C2 function definition(s) entirely on board the members; ${m.population.peerLinks} link(s) between members; fleet ${m.population.fleet ? `[${m.population.fleet}]` : 'absent'}; ${m.population.acceptedHazards} hazard(s) accepted rather than mitigated.`,
          ]
        : []),
      '',
    );
  }
  const moes = scoredMoes(ctx.state.brief?.moes ?? []);
  if (moes.length > 0) {
    lines.push('## The measures these are held to', '');
    for (const moe of moes) lines.push(`- \`${moe.name}\`: target ${boundText(moe)} — ${moe.doc}`);
    lines.push(
      '',
      '## What each alternative claims on them',
      '',
      'These are estimates the author of each architecture stated, with the basis it gave. The score counts targets met at face value; your job is to say where a basis does not hold up — an estimate its architecture cannot deliver should cost it in realisability.',
      '',
    );
    for (const moe of moes) {
      lines.push(`### \`${moe.name}\` (target ${boundText(moe)})`, '');
      for (const m of metrics) {
        const x = m.moes.find((y) => y.name === moe.name);
        lines.push(`- alternative ${m.k}: ${estimateText(x)}${x?.basis ? ` — ${x.basis}` : ''}`);
      }
      lines.push('');
    }
  }
  const rules = ctx.state.brief?.rules ?? [];
  if (rules.length > 0)
    lines.push(
      '## Also weigh',
      '',
      `- The rules the system never breaks — ${rules.map((r) => `\`${r.name}\``).join(', ')} — are checked on each alternative's state machines. Weigh WHICH component enforces them: one that also detects, classifies or decides what to report shares its faults with the rules, and should cost cohesion and realisability; a monitor of its own, whose doc says what it overrides, should not.`,
      '- Where each alternative puts the work the one operator depends on — sorting what reaches them, joining what several members saw, keeping the record of why each report was raised — and what that placement costs the operator and keeps doing when the ground link drops.',
      '',
    );
  lines.push(
    ctx.state.brief?.population
      ? 'Score each alternative on cohesion, coupling, realisability, evolvability, groundLinkLossResilience and groundNodeLossResilience, and say which one you would take.'
      : 'Score each alternative on cohesion, coupling, realisability and evolvability, and say which one you would take.',
  );
  return lines.join('\n');
}

/** `0.97`, or the outcome when there is no value to show. */
function estimateText(x: AlternativeMetrics['moes'][number] | undefined): string {
  if (!x) return 'no estimate';
  return x.value !== undefined ? `${x.value}${x.unit ? ` ${x.unit}` : ''}${x.outcome === 'optimum' ? '' : ` (${x.outcome})`}` : x.outcome;
}

function tradeOffElement(
  layer: Layer,
  chosen: number,
  scores: EvaluationResult['scores'],
  rubric: EvaluateOutput,
): string {
  const table = scores
    .map((s) => `                 alternative ${s.k}: total ${s.total.toFixed(2)} (measures ${s.moe.toFixed(2)}, review ${s.rubric.toFixed(2)}, structure ${s.structure.toFixed(2)}, resilience ${s.resilience.toFixed(2)})`)
    .join('\n');
  return [
    `#prose part ${layer.toLowerCase()}TradeOff {`,
    `    doc /* Architecture trade-off for ${layer}. Alternative ${chosen} was taken.`,
    table,
    '                 The measures term scores the worst case of each alternative\'s own #Estimate: claims its architecture states with their basis, not measurements.',
    `                 ${rubric.rationale.replace(/\*\//g, '* /')} */`,
    '}',
  ].join('\n');
}

export function rationaleFor(
  layer: Layer,
  chosen: number,
  metrics: AlternativeMetrics[],
  scores: EvaluationResult['scores'],
  rubric: EvaluateOutput,
  penaltyCost: { per: number; cap: number } = { per: 0.05, cap: 0.25 },
  attempted: Array<{ k: number; status: string }> = [],
): string {
  const lines = [
    `# ${layer} architecture trade-off`,
    '',
    `**Chosen: alternative ${chosen}**${rubric.recommended === chosen ? '' : ` (the reviewing model preferred ${rubric.recommended}; the weighted score did not)`}`,
    '',
    // Printed before the scores, because a reader who has seen the table will
    // already have taken the comparison at face value.
    ...((viable: number, tried: number) =>
      viable >= 2
        ? []
        : [
            `> **This was not a comparison.** ${viable} of ${tried} alternative(s) were viable, so the ` +
              'decision was made by elimination: what rejected the others decided this layer, and the ' +
              'score below is one candidate measured against itself. ' +
              (attempted.length > 0
                ? `Rejected: ${attempted.filter((a) => a.status !== 'done').map((a) => `alternative ${a.k} (${a.status})`).join(', ')}. `
                : '') +
              'A trade-off is the method\'s reason for generating more than one architecture, and a run ' +
              'that scores a single survivor has skipped it — the number below is not evidence that this ' +
              'architecture beat anything.',
            '',
          ])(metrics.length, Math.max(attempted.length, metrics.length)),
    ...((blind) =>
      blind.length === 0
        ? []
        : [
            `> **${blind.length} measure(s) scored every alternative the same and decided nothing here:** ` +
              `${blind.map((b) => `\`${b.name}\``).join(', ')}. A measure with the same estimate on ` +
              'both sides is still scored and still moves no score, and a reader is left believing the ' +
              'alternatives were examined on it. If one of these is the thing the alternatives differ ' +
              'about, the comparison has not been made on the thing that matters. In v7 four of ' +
              'fourteen measures scored both alternatives the same, so a third of that comparison ' +
              'turned on nothing.',
            '',
          ])(measuresThatDoNotDiscriminate(metrics)),
    '## Score',
    '',
    '| Alternative | Total | Measures | Review | Structure | Resilience |',
    '|---|---|---|---|---|---|',
    ...scores.map((s) => `| ${s.k} | ${s.total.toFixed(3)} | ${s.moe.toFixed(2)} | ${s.rubric.toFixed(2)} | ${s.structure.toFixed(2)} | ${s.resilience.toFixed(2)} |`),
    '',
    ...(metrics.some((m) => m.population)
      ? [
          '## Command and control',
          '',
          '| Alternative | Coordination and C2 on board | Links between members | Fleet | Hazards accepted |',
          '|---|---|---|---|---|',
          ...metrics.map((m) =>
            m.population
              ? `| ${m.k} | ${m.population.onBoard}/${m.population.tagged} | ${m.population.peerLinks} | ${m.population.fleet ? `[${m.population.fleet}]` : '—'} | ${m.population.acceptedHazards} |`
              : `| ${m.k} | — | — | — | — |`,
          ),
          '',
        ]
      : []),
    '## Measured',
    '',
    '| Alternative | Elements | Connections | Unconnected ports | Unused defs | Functions realised | Repairs | Hazards accepted |',
    '|---|---|---|---|---|---|---|---|',
    ...metrics.map(
      (m) =>
        `| ${m.k} | ${m.elements} | ${m.connections} | ${m.unconnectedPorts} | ${m.orphanDefinitions} | ${m.functionsRealised}/${m.functionsAbove} | ${m.repairIterations} | ${m.acceptedHazards ?? 0}${m.acceptedHazards ? ` (structure −${acceptancePenalty(m.acceptedHazards, penaltyCost).toFixed(2)})` : ''} |`,
    ),
    '',
  ];
  const withMoes = metrics.find((m) => m.moes.length > 0);
  if (withMoes) {
    lines.push(
      '## Measures of effectiveness',
      '',
      'Each value is the worst case the solver finds over the alternative\'s own `#Estimate` — a claim the architecture makes, not a measurement.',
      '',
      '| Alternative | Measure | Worst case | Target | Met |',
      '|---|---|---|---|---|',
    );
    for (const m of metrics) {
      for (const moe of m.moes) {
        lines.push(`| ${m.k} | \`${moe.name}\` | ${estimateText(moe)} | ${boundText(moe)} | ${moe.met === undefined ? 'undecided' : moe.met ? 'yes' : 'no'} |`);
      }
    }
    lines.push('');
  }
  lines.push('## Review', '', rubric.rationale, '');
  for (const entry of rubric.scores) {
    lines.push(`### Alternative ${entry.alternative}`, '');
    for (const c of entry.criteria) lines.push(`- **${c.name}** ${c.score}/5 — ${c.reason}`);
    lines.push('');
  }
  return lines.join('\n');
}
