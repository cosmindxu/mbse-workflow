/**
 * The packet that stands on its own.
 *
 * Everything a reader needs to judge the model without having watched it being
 * built: the closure table layer by layer, what is covered, what is reachable,
 * what is still open — and, because a report about oneself is worth less than
 * one anybody can reproduce, the headline checks re-run through the shipped
 * Sysprose CLI, with the commands printed beside their answers.
 */
import { copyFileSync, existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { assemble } from '../model/assembler.ts';
import { topLayer, type Verdict } from '../check/checker.ts';
import { runCheck, runSysprose } from '../sysprose/spawn.ts';
import { AUTHORED_LAYERS, type Layer } from '../spec/layers.ts';
import { isDocumented } from '../check/predicates.ts';
import type { AgentContext } from '../agents/context.ts';
import type { ElementRow, RequirementsPayload, TracePayload } from '../sysprose/types.ts';
import { replicaFacts, type FunctionType } from '../check/replicas.ts';
import { contributionMarkdown, contributionSurface, readCallLog, unrecordedSpend, type ContributionRow } from './contribution.ts';
import { boundText, meets, scoredMoes, worstCase, worstCaseSense } from '../spec/measures.ts';

export interface Reviewability {
  /** Per layer: how much a reader can read. */
  docCoverage: Array<{ layer: Layer; elements: number; documented: number; coverage: number }>;
  /** No doc and no realization link either way: a reader cannot ask why it exists. */
  unexplained: string[];
  /** Lines a reviewer had to read at each step, from the packet's diff. */
  reviewSurface: Array<{ step: string; lines: number }>;
}

export interface FinalAudit {
  dir: string;
  modelPath: string;
  witness: { command: string; exitCode: number; meaning: string; diagnostics: number };
  closure: Array<{ from: Layer; to: Layer; realised: number; total: number }>;
  coverage?: { total: number; satisfied: number; coverage: number };
  todos: string[];
  /** Hazards the model states and deliberately does not mitigate, with a reason in their doc. */
  acceptedHazards: string[];
  reviewability: Reviewability;
  /** The population, layer by layer — present only when the brief declares one. */
  fleet?: FleetRow[];
  fleetError?: string;
  /** What editing each layer and resuming would re-run, and what those steps cost in this run. */
  contribution?: ContributionRow[];
  /** The bonus lane's state-machine sweep and fault tree, read back from its packet. */
  behaviour?: { machines: Array<{ machine: string; property: string; exitCode: number; detail?: string }>; skipped: number };
  faultTree?: { exitCode: number; withCutSets: number; singlePointsOfFailure: number; contracts: number; applicable?: boolean };
  /** Each measure as the chosen architectures state it, LA and PA (CV-17). */
  measures?: MeasureRow[];
  measuresError?: string;
}

export interface MeasureRow {
  name: string;
  target: string;
  /** Per layer: the worst case over the layer's `#Estimate`, or what stood in for it. */
  layers: Array<{ layer: Layer; estimate: string; met?: boolean }>;
  /** Every alternative compared, at every layer, missed the target: `k/n` misses. */
  unreachable?: string;
  /** Every alternative compared met it: the measure decided nothing. `n/n`. */
  metByAll?: string;
  /** The brief marks the target as a placeholder, not the customer's number. */
  placeholder?: boolean;
}

/**
 * Whether every alternative the trade-offs compared missed a measure's target.
 *
 * Read from the bounds reports the evaluation kept per alternative. A target
 * no architecture meets is a fact about the target or the brief — in v5, 12
 * drones on a 40/60 duty keep about 4.8 airborne, so losing one costs about a
 * fifth of the coverage against a 0.1 target — and it is a question for the
 * person who set it, not a reason to prefer one alternative.
 */
export function unreachableTarget(
  moe: { name: string; sense: 'min' | 'max'; target: number },
  reports: Array<{ outcome?: string; value?: number | null }>,
): string | undefined {
  if (reports.length === 0) return undefined;
  const verdicts = reports.map((r) => meets(moe, r.outcome, r.value ?? undefined));
  if (verdicts.some((v) => v !== false)) return undefined;
  return `${verdicts.length}/${reports.length}`;
}

/**
 * `n/n` when every alternative compared met the target: the measure added the
 * same score to each and decided nothing. v7's PA alternative 2 met all 14 and
 * alternative 1 missed one — a verdict resting on one measure, and on targets
 * the brief's planner had set.
 */
export function metByEveryAlternative(
  moe: { name: string; sense: 'min' | 'max'; target: number },
  reports: Array<{ outcome?: string; value?: number | null }>,
): string | undefined {
  if (reports.length === 0) return undefined;
  return reports.every((r) => meets(moe, r.outcome, r.value ?? undefined) === true) ? `${reports.length}/${reports.length}` : undefined;
}

export interface FleetRow {
  layer: Layer;
  memberDef: boolean;
  fleet?: string;
  representatives: string[];
  peerLinks: Array<{ name?: string; type?: string }>;
  /** Each tagged function by definition: its usages, where each is allocated, and where that puts it. */
  placement: Array<{ def: string; tag: 'Coordination' | 'C2'; where: string; place: FunctionType['place'] }>;
}

export async function writeFinalAudit(ctx: AgentContext, verdict: Verdict): Promise<FinalAudit> {
  const dir = ctx.layout.auditDirFor('final');
  mkdirSync(dir, { recursive: true });

  const layer = topLayer(ctx.layout);
  const assembly = assemble(ctx.layout, layer);
  writeFileSync(ctx.layout.finalPath, assembly.text);

  const trace = payload<TracePayload>(verdict, 'trace-trace');
  const requirements = payload<RequirementsPayload>(verdict, 'requirements');
  const allElements = payload<ElementRow[]>(verdict, 'elements') ?? [];

  // The same exemptions the gates apply: this project's own bookkeeping
  // elements and the actors carried down from SA are not things a layer
  // realises. Measured: the first final audit read "14/16" for PA→EPBS where
  // the two were the guidance element and the trade-off record.
  // By tag as well as by name: v5's PA→EPBS read 4/5, the fifth being the
  // carried `#prose part fleetFact`, a note that is nothing to procure.
  const proseNames = new Set([...assembly.text.matchAll(/#(?:prose|prompt)\b[^\n]*?\bpart\s+([A-Za-z_][A-Za-z0-9_]*)/g)].map((m) => m[1]));
  const bookkeeping = new Set(
    allElements.filter((e) => /Guidance$|TradeOff$|^reviewerComment/.test(e.name) || (e.metaclass === 'PartUsage' && proseNames.has(e.name))).map((e) => e.qualifiedName),
  );
  // Actors are the ones the model tags, as the gate reads them — not the ones
  // whose names sound like people. Measured: the second run read "1/6" for
  // PA→EPBS where the five were `#Actor` parts named RecoveryPoint,
  // ChargingInfrastructure, AllocatedRadioLink, AreaOfInterest and
  // OperatingEnvironment; the gate had passed the layer, and rightly.
  const actorTypes = new Set([...assembly.text.matchAll(/#Actor\b[^\n]*?\bpart\s+def\s+([A-Za-z_][A-Za-z0-9_]*)/g)].map((m) => m[1]));
  const closure = AUTHORED_LAYERS.slice(0, -1).map((upper, i) => {
    const lower = AUTHORED_LAYERS[i + 1];
    const kinds = lower === 'EPBS' ? ['PartUsage'] : ['ActionUsage'];
    const at = `${ctx.layout.root}::${upper}::`;
    const total = allElements.filter(
      (e) =>
        kinds.includes(e.metaclass) &&
        e.qualifiedName.startsWith(at) &&
        !e.qualifiedName.slice(at.length).includes('::') &&
        !bookkeeping.has(e.qualifiedName) &&
        !(lower === 'EPBS' && actorTypes.has((e.type ?? '').split('::').pop() ?? '')),
    );
    const realised = new Set(
      (trace?.links ?? [])
        .filter((l) => l.toName.startsWith(`${ctx.layout.root}::${lower}::`))
        .map((l) => l.fromName),
    );
    return { from: upper as Layer, to: lower as Layer, realised: total.filter((e) => realised.has(e.qualifiedName)).length, total: total.length };
  });

  // The independent witness: the same file, through the CLI a reader has.
  const witnessRun = await runCheck({ dir: ctx.config.sysprose.dir }, assembly.text);
  const witness = {
    command: `npm run check -- ${ctx.layout.finalPath} --json`,
    exitCode: witnessRun.exitCode,
    meaning: witnessRun.meaning,
    diagnostics: witnessRun.files[0]?.diagnostics.length ?? 0,
  };
  const requirementsWitness = await runSysprose<RequirementsPayload>(
    { dir: ctx.config.sysprose.dir },
    'requirements',
    [],
    assembly.text,
  );

  const todos = allElements.filter((e) => /\bTODO\b/.test(e.doc ?? '')).map((e) => e.qualifiedName);
  const reviewability = measureReviewability(ctx, allElements, trace);
  // From the tag index the gates read, not a regex over the text: the two must
  // agree on what was accepted, and a tag on its own line defeats a regex.
  const acceptedHazards = await ctx.backend
    .withModel(assembly.text, ctx.layout.finalPath, (m) => {
      const tags = ctx.backend.tags(m);
      const hazards = new Set(tags.taggedWith('Hazard'));
      return tags.taggedWith('Accepted').filter((qn) => hazards.has(qn)).map((qn) => qn.split('::').pop() ?? qn);
    })
    .catch(() => [...assembly.text.matchAll(/#Accepted[^\n]*?\brequirement\s+([A-Za-z_][A-Za-z0-9_]*)/g)].map((m) => m[1]));

  // One more load, for the layer views: the published payloads lift a
  // connection's ends to declared ports, and a link between two members is
  // exactly what that loses.
  const population = ctx.state.brief?.population;
  // Never allowed to cost the run its audit: a failure here is written into the
  // report as what it is, and the rest of the audit stands.
  let fleetError: string | undefined;
  const fleet = population
    ? await ctx.backend.withModel(assembly.text, ctx.layout.finalPath, (m) => {
        const elements = ctx.backend.elements(m);
        return (['SA', 'LA', 'PA', 'EPBS'] as Layer[]).map((l): FleetRow => {
          const f = replicaFacts(ctx.backend.layerView(m, l), elements, population);
          return {
            layer: l,
            memberDef: f.memberDef,
            fleet: l === 'EPBS' ? epbsFleet(assembly.text, elements, ctx.layout.root, population.fleetPart) : f.fleet?.multiplicity,
            representatives: f.representatives,
            peerLinks: f.peerLinks.map((p) => ({ name: p.name, type: p.type })),
            placement: f.types.map((t) => ({
              def: t.def,
              tag: t.tag,
              where: t.usages.map((u) => `\`${u.name}\` → ${u.targets.length > 0 ? u.targets.map((p) => `\`${p}\``).join(', ') : '—'}`).join('<br>'),
              place: t.place,
            })),
          };
        });
      }).catch((err: unknown) => {
        fleetError = err instanceof Error ? err.message : String(err);
        return undefined;
      })
    : undefined;

  // The measures, as the architecture each layer kept states them. Fail-soft
  // like the fleet: an audit is never lost to one more analysis.
  const moeSpecs = scoredMoes(ctx.state.brief?.moes ?? []);
  let measuresError: string | undefined;
  const measures =
    moeSpecs.length > 0
      ? await ctx.backend
          .withModel(assembly.text, ctx.layout.finalPath, async (m) => {
            const rows: MeasureRow[] = [];
            for (const moe of moeSpecs) {
              const layers: MeasureRow['layers'] = [];
              for (const l of ['LA', 'PA'] as Layer[]) {
                try {
                  const name = `${ctx.layout.root}::${l}::${moe.name}`;
                  const row = await worstCase(async (sense) => (await ctx.backend.bounds(m, name, sense)).bounds[0], moe.sense);
                  const shown = row.value !== undefined ? `${row.value}${moe.unit ? ` ${moe.unit}` : ''}${row.outcome === 'derived' ? ' (derived)' : ''}` : row.outcome;
                  layers.push({ layer: l, estimate: shown, met: meets(moe, row.outcome, row.value) });
                } catch {
                  layers.push({ layer: l, estimate: 'no estimate' });
                }
              }
              const reports: Array<{ outcome?: string; value?: number | null }> = [];
              for (const stepId of ['S33', 'S42'] as const) {
                const stepDir = ctx.layout.auditDirFor(stepId);
                if (!existsSync(stepDir)) continue;
                for (const alt of readdirSync(stepDir).filter((d) => /^alt-\d+$/.test(d))) {
                  // Resolved as the evaluator resolved it: a derived estimate's
                  // worst case is only decided once the other sense's report agrees.
                  const read = (file: string) =>
                    existsSync(file)
                      ? (JSON.parse(readFileSync(file, 'utf8')) as { bounds?: Array<{ outcome?: string; value?: number | null }> }).bounds?.[0]
                      : undefined;
                  const worstFile = resolve(stepDir, alt, `bounds-${moe.name}.json`);
                  if (!existsSync(worstFile)) continue;
                  const otherFile = resolve(stepDir, alt, `bounds-${moe.name}.${moe.sense === 'max' ? 'max' : 'min'}.json`);
                  reports.push(await worstCase(async (sense) => read(sense === worstCaseSense(moe.sense) ? worstFile : otherFile), moe.sense));
                }
              }
              rows.push({ name: moe.name, target: boundText(moe), layers, unreachable: unreachableTarget(moe, reports), metByAll: metByEveryAlternative(moe, reports), placeholder: moe.placeholder === true });
            }
            return rows;
          })
          .catch((err: unknown) => {
            measuresError = err instanceof Error ? err.message : String(err);
            return undefined;
          })
      : undefined;

  const audit: FinalAudit = {
    dir,
    modelPath: ctx.layout.finalPath,
    witness,
    closure,
    coverage: requirements
      ? { total: requirements.total, satisfied: requirements.satisfied, coverage: requirements.coverage }
      : undefined,
    todos,
    acceptedHazards,
    reviewability,
    fleet,
    fleetError,
    measures,
    measuresError,
    ...bonusLane(ctx.layout.auditDirFor('S60')),
    contribution: (() => {
      try {
        return contributionSurface(ctx.state, ctx.layout, readCallLog(ctx.layout.llmLogPath));
      } catch {
        return undefined;
      }
    })(),
  };

  writeFileSync(resolve(dir, 'final.json'), `${JSON.stringify(audit, null, 2)}\n`);
  writeFileSync(resolve(dir, 'README.md'), markdown(ctx, verdict, audit, requirementsWitness.payload));
  copyFileSync(ctx.layout.finalPath, resolve(dir, `${ctx.layout.root}.sysml`));
  return audit;
}

/**
 * Reviewability, measured rather than claimed.
 *
 * Three proxies a reader can check: whether each layer's elements say what
 * they are for, which elements nobody could ask "why is this here" about, and
 * how much text each step put in front of a reviewer.
 */
const DOC_EXEMPT = new Set(['MetadataDefinition', 'Package', 'PortUsage', 'ReferenceUsage', 'AttributeUsage']);

function measureReviewability(ctx: AgentContext, elements: ElementRow[], trace?: TracePayload): Reviewability {
  const root = ctx.layout.root;
  const direct = (e: ElementRow, layer: Layer): boolean => {
    const at = `${root}::${layer}::`;
    return e.qualifiedName.startsWith(at) && !e.qualifiedName.slice(at.length).includes('::');
  };
  const counts = (layer: Layer) => elements.filter((e) => direct(e, layer) && !DOC_EXEMPT.has(e.metaclass));

  const docCoverage = (['Common', ...AUTHORED_LAYERS] as Layer[])
    .map((layer) => {
      const own = counts(layer);
      const documented = own.filter((e) => isDocumented(e, elements)).length;
      return { layer, elements: own.length, documented, coverage: own.length === 0 ? 1 : documented / own.length };
    })
    .filter((row) => row.elements > 0);

  const linked = new Set((trace?.links ?? []).flatMap((l) => [l.fromName, l.toName]));
  const unexplained = (AUTHORED_LAYERS as readonly Layer[])
    .flatMap((layer) => counts(layer))
    .filter((e) => !isDocumented(e, elements) && !linked.has(e.qualifiedName))
    .map((e) => e.qualifiedName);

  const reviewSurface: Reviewability['reviewSurface'] = [];
  for (const step of Object.keys(ctx.state.steps)) {
    const diff = resolve(ctx.layout.auditDirFor(step as never), 'fragment.diff');
    if (!existsSync(diff)) continue;
    const lines = readFileSync(diff, 'utf8')
      .split('\n')
      .filter((l) => (l.startsWith('+') || l.startsWith('-')) && !l.startsWith('+++') && !l.startsWith('---')).length;
    reviewSurface.push({ step, lines });
  }
  return { docCoverage, unexplained, reviewSurface };
}

function payload<T>(verdict: Verdict, name: string): T | undefined {
  const file = verdict.checks.find((c) => c.name === name)?.payloadFile;
  if (!file) return undefined;
  try {
    return JSON.parse(readFileSync(file, 'utf8')) as T;
  } catch {
    return undefined;
  }
}

/** How many of the unsatisfied requirements are hazards accepted with their reason. */
export function acceptedNote(reqs: RequirementsPayload, accepted: string[]): string {
  const names = new Set(accepted);
  const open = reqs.rows.filter((r) => r.satisfied === false);
  const acc = open.filter((r) => names.has(r.name)).length;
  if (acc === 0) return '';
  return acc === open.length
    ? `; ${acc === 1 ? 'the 1 unsatisfied is a hazard' : `all ${acc} unsatisfied are hazards`} accepted with ${acc === 1 ? 'its' : 'their'} reason`
    : `; ${acc} of the ${open.length} unsatisfied are hazards accepted with their reason`;
}

function markdown(ctx: AgentContext, verdict: Verdict, audit: FinalAudit, witnessRequirements?: RequirementsPayload): string {
  const state = ctx.state;
  const blocking = verdict.items.filter((i) => i.blocking);
  const notes = verdict.items.filter((i) => !i.blocking);
  const lines = [
    `# ${ctx.layout.root} — final audit`,
    '',
    `Model: \`${audit.modelPath}\` (${verdict.elementCount} elements)`,
    `Sysprose: ${state.sysprose.commit}${state.sysprose.matches ? '' : ` (the checks were calibrated against ${state.sysprose.expected})`}`,
    `Run: ${state.mode} mode, ${state.llm.calls} model call(s), ${state.llm.costUsd.toFixed(2)} USD, ${Math.round(state.llm.durationMs / 1000)} s of model time${(state.legs?.length ?? 1) > 1 ? `, over ${state.legs!.length} legs` : ""}${state.llm.killed ? `; ${state.llm.killed} call(s) killed by the timeout, which may be billed and report no cost — the total is a floor` : ""}${(() => { const note = unrecordedSpend(state.llm, readCallLog(ctx.layout.llmLogPath)); return note ? `; ${note}` : ''; })()}`,
    '',
    '## Checked by the shipped CLI, not by this workflow',
    '',
    `\`${audit.witness.command}\` → exit ${audit.witness.exitCode} (${audit.witness.meaning}), ${audit.witness.diagnostics} diagnostic(s)`,
    witnessRequirements
      ? `\`npm run sysprose -- requirements ${audit.modelPath} --json\` → ${witnessRequirements.satisfied}/${witnessRequirements.total} satisfied (${Math.round(witnessRequirements.coverage * 100)} %)${acceptedNote(witnessRequirements, audit.acceptedHazards)}`
      : '',
    '',
    '## Realization chain',
    '',
    '| From | To | Realised | Of |',
    '|---|---|---|---|',
    ...audit.closure.map((c) => `| ${c.from} | ${c.to} | ${c.realised} | ${c.total} |`),
    '',
    '## Every check this step ran',
    '',
    '| Check | Verdict | Command |',
    '|---|---|---|',
    ...verdict.checks.map((c) => `| \`${c.name}\` | ${c.ok ? 'clear' : `${c.items.length} finding(s)`} | \`${c.cli}\` |`),
    '',
  ];
  const r = audit.reviewability;
  lines.push(
    '## Can a person review this?',
    '',
    '| Layer | Elements | Documented | |',
    '|---|---|---|---|',
    ...r.docCoverage.map((d) => `| ${d.layer} | ${d.elements} | ${d.documented} | ${Math.round(d.coverage * 100)} % |`),
    '',
    r.unexplained.length === 0
      ? 'Every element either says what it is for or is linked to something that does.'
      : `${r.unexplained.length} element(s) carry no doc and no realization link — a reader cannot ask why they exist:`,
    ...r.unexplained.slice(0, 40).map((q) => `- \`${q}\``),
    '',
    '| Step | Lines a reviewer read |',
    '|---|---|',
    ...r.reviewSurface.map((x) => `| ${x.step} | ${x.lines} |`),
    '',
  );
  if (blocking.length > 0) {
    lines.push('## Blocking', '', ...blocking.map((i) => `- \`${i.code}\` ${i.qualifiedName ?? ''}: ${i.message}`), '');
  }
  if (audit.behaviour || audit.faultTree) lines.push(...behaviourMarkdown(audit));
  if (audit.contribution) lines.push(...contributionMarkdown(audit.contribution));
  if (audit.measures) lines.push(...measuresMarkdown(audit.measures));
  if (audit.measuresError) lines.push('## Measures', '', `Could not be measured: ${audit.measuresError}`, '');
  if (audit.fleet) lines.push(...fleetMarkdown(audit.fleet));
  if (audit.fleetError) lines.push('## The fleet', '', `Could not be measured: ${audit.fleetError}`, '');
  if (audit.acceptedHazards.length > 0) {
    lines.push('## Hazards accepted, not mitigated', '', 'Each carries its reason in its doc; a reviewer should read them.', '', ...audit.acceptedHazards.map((h) => `- \`${h}\``), '');
  }
  if (audit.todos.length > 0) {
    lines.push('## Left as TODO', '', ...audit.todos.map((t) => `- \`${t}\``), '');
  }
  if (notes.length > 0) {
    lines.push(
      '## Reported, not blocking',
      '',
      ...notes.slice(0, 60).map((i) => `- \`${i.code}\` ${i.qualifiedName ?? ''}: ${i.message}`),
      '',
    );
  }
  lines.push(
    '## Steps',
    '',
    '| Step | Status | Repairs | Gate |',
    '|---|---|---|---|',
    ...Object.entries(state.steps).map(
      ([id, r]) => `| ${id} | ${r?.status} | ${r?.iterations ?? 0} | ${r?.gate ? `${r.gate.decision}` : '—'} |`,
    ),
    '',
  );
  return lines.join('\n');
}

/**
 * The swarm, as the model has it: where the member exists, how many, how two
 * of them talk, and where each coordination and command-and-control function
 * sits. The table a reviewer needs before any other when the system is a
 * population, because three runs produced a model where every one of these
 * columns would have read "absent".
 */
/**
 * At EPBS the fleet is not a member usage but the configuration items that
 * realise it: every direct EPBS part tracing to PA's fleet, with its multiplicity.
 * v4's audit read "—" here while `droneAirframeCi : DroneAirframeItem [12]` traced to it.
 */
export function epbsFleet(text: string, elements: Array<{ qualifiedName: string; multiplicity?: string }>, root: string, fleetPart: string): string | undefined {
  const target = `${root}::PA::${fleetPart}`.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const names = [...text.matchAll(new RegExp(`\\btrace\\s+([A-Za-z_][A-Za-z0-9_]*)\\s+to\\s+${target}\\s*;`, 'g'))].map((m) => m[1]);
  const found = names
    .map((n) => elements.find((e) => e.qualifiedName === `${root}::EPBS::${n}`))
    .filter((e): e is { qualifiedName: string; multiplicity?: string } => !!e)
    .map((e) => `\`${e.qualifiedName.split('::').pop()}\` [${e.multiplicity || '1'}]`);
  return found.length > 0 ? found.join(', ') : undefined;
}

/** The S60 payloads, when the bonus lane ran; never an error when it did not. */
export function bonusLane(dir: string): Pick<FinalAudit, 'behaviour' | 'faultTree'> {
  const read = <T>(name: string): T | undefined => {
    const file = resolve(dir, `${name}.json`);
    try {
      return existsSync(file) ? (JSON.parse(readFileSync(file, 'utf8')) as T) : undefined;
    } catch {
      return undefined;
    }
  };
  const behaviour = read<FinalAudit['behaviour']>('check-behaviour');
  const tree = read<{ exitCode: number; withCutSets?: number; singlePointsOfFailure?: unknown; contracts?: number; groups?: unknown[] }>('fault-tree');
  const count = (x: unknown): number => (Array.isArray(x) ? x.length : typeof x === 'number' ? x : 0);
  return {
    behaviour,
    faultTree: tree
      ? { exitCode: tree.exitCode, withCutSets: count(tree.withCutSets), singlePointsOfFailure: count(tree.singlePointsOfFailure), contracts: count(tree.contracts), applicable: count(tree.groups) > 0 }
      : undefined,
  };
}

export function behaviourMarkdown(audit: Pick<FinalAudit, 'behaviour' | 'faultTree'>): string[] {
  const lines = ['## Behaviour', ''];
  if (audit.behaviour) {
    const verdict = (r: { property: string; exitCode: number }): string =>
      r.property === 'none' ? 'nothing to check' : r.exitCode === 0 ? 'holds' : r.exitCode === 1 ? '**refuted**' : 'undecided';
    lines.push(
      'Each state machine against the properties it states, or — for a machine written to come back to the state it opens at — that every reachable configuration can get back there. A machine with no transition back is a lifecycle and gets no default.',
      '',
      '| Machine | Property | Verdict | Detail |',
      '|---|---|---|---|',
      ...audit.behaviour.machines.map((r) => `| \`${r.machine.split('::').slice(1).join('::')}\` | ${r.property} | ${verdict(r)} | ${(r.detail ?? '').replace(/\|/g, '/').slice(0, 140)} |`),
      '',
    );
    if (audit.behaviour.skipped > 0) lines.push(`${audit.behaviour.skipped} machine(s) past the sweep's cap were not checked.`, '');
  }
  if (audit.faultTree)
    lines.push(
      audit.faultTree.applicable === false
        ? 'Fault tree: not applicable. It computes which component contract failures break a top requirement, and no layer of this workflow writes component contracts that refine one — so there is nothing to cut, and no claim about single points of failure is made here.'
        : `Fault tree over the contracts: ${audit.faultTree.contracts} contract(s), ${audit.faultTree.withCutSets} with cut sets, ${audit.faultTree.singlePointsOfFailure} single point(s) of failure.`,
      '',
    );
  return lines;
}

export function measuresMarkdown(rows: MeasureRow[]): string[] {
  const cell = (x: MeasureRow['layers'][number] | undefined): string =>
    x ? `${x.estimate}${x.met === undefined ? '' : x.met ? ' ✓' : ' ✗'}` : '—';
  return [
    '## Measures',
    '',
    'The worst case over the `#Estimate` each layer\'s chosen architecture states. These are the architecture\'s own claims with their basis in the doc, checked for consistency by the solver — not measurements.',
    '',
    '| Measure | Target | LA | PA |',
    '|---|---|---|---|',
    ...rows.map((r) => `| \`${r.name}\` | ${r.target}${r.placeholder ? ' (placeholder)' : ''} | ${cell(r.layers.find((x) => x.layer === 'LA'))} | ${cell(r.layers.find((x) => x.layer === 'PA'))} |`),
    '',
    ...(rows.some((r) => r.unreachable)
      ? [
          '### No architecture compared meets these',
          '',
          'Every alternative at every layer missed the target. That is a question about the target or the brief — revisit the number, or what the brief fixes (a fleet size, a duty cycle) — not a reason to prefer one design.',
          '',
          ...rows.filter((r) => r.unreachable).map((r) => `- \`${r.name}\` ${r.target}: missed by ${r.unreachable} alternatives`),
          '',
        ]
      : []),
    ...(rows.some((r) => r.metByAll)
      ? [
          '### Every architecture compared meets these',
          '',
          `They added the same to every alternative's score, so the choice was made by the rest${rows.every((r) => r.metByAll) ? ' — and here that is every measure: the measures decided nothing' : ''}. A target nobody misses is a question about the target: is it the customer's?`,
          '',
          ...rows.filter((r) => r.metByAll).map((r) => `- \`${r.name}\` ${r.target}${r.placeholder ? ' (placeholder)' : ''}: met by ${r.metByAll} alternatives`),
          '',
        ]
      : []),
    ...(rows.some((r) => r.placeholder)
      ? [`${rows.filter((r) => r.placeholder).length} of these ${rows.length} targets are placeholders in the brief, awaiting the customer's numbers: a ✓ against one says the design meets the placeholder, nothing more.`, '']
      : []),
  ];
}

function fleetMarkdown(rows: FleetRow[]): string[] {
  const lines = [
    '## The fleet',
    '',
    '| Layer | Member definition | Fleet | Representatives | Links between members | Coordination and C2 on board |',
    '|---|---|---|---|---|---|',
    ...rows.map((r) => {
      const links = r.peerLinks.map((p) => `\`${p.name ?? '(unnamed)'}\`${p.type ? ` : ${p.type}` : ''}`).join(', ') || '—';
      const aboard = r.placement.length > 0 ? `${r.placement.filter((p) => p.place === 'on board').length}/${r.placement.length}` : '—';
      return `| ${r.layer} | ${r.memberDef ? 'yes' : '—'} | ${r.fleet ? (r.fleet.includes('`') ? r.fleet : `[${r.fleet}]`) : '—'} | ${r.representatives.map((x) => `\`${x}\``).join(', ') || '—'} | ${links} | ${aboard} |`;
    }),
    '',
    'Connectivity counts usages, not instances: a link between two representatives is one wired occurrence standing for every pair of members that exchange (CV-16).',
    '',
  ];
  for (const r of rows.filter((x) => x.placement.length > 0 && (x.layer === 'LA' || x.layer === 'PA'))) {
    lines.push(
      `### Where command and control sits at ${r.layer}`,
      '',
      'One row per function definition. A definition is on board when every usage sits on a member or the fleet, on the ground when any usage sits elsewhere, and neither when only actors perform it.',
      '',
      '| Function | Tag | Usages and where they are allocated | Where it sits |',
      '|---|---|---|---|',
    );
    for (const p of r.placement) lines.push(`| \`${p.def}\` | ${p.tag} | ${p.where} | ${p.place} |`);
    lines.push('');
  }
  return lines;
}
