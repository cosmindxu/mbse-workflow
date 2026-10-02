/**
 * A recorded trade-off, scored again under the rules as they stand.
 *
 * The rules a trade-off is scored by can change after a run has used them:
 * v9's S33 and S42 counted SEED's 12 h of unattended watch, which every
 * alternative missed, and the rule that leaves a target nobody asked for out
 * of the score came after. Running the step again would call the reviewing
 * model and every solver read again, and could choose differently for reasons
 * that have nothing to do with the rule. This reads what the step recorded —
 * each alternative's `bounds` payloads, and its review, structure and
 * resilience scores — and recomputes only what the rules decide: the measures
 * term, and the totals under the configured weights.
 *
 * It appends and never rewrites: the trade-off as it was made stays above the
 * re-score, and no fragment is touched. The layer was built from the recorded
 * choice, so a re-score that would choose otherwise says so and fails, for a
 * person to decide whether to run the step again.
 */
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import {
  highestScoring,
  leaveOutCrashed,
  measuresTable,
  moeScore,
  SOLVER_CRASHED_TWICE,
  weightedTotal,
  type AlternativeMetrics,
  type EvaluationResult,
  type Unscored,
} from '../agents/evaluate.ts';
import type { Moe } from '../llm/schemas.ts';
import type { ModelLayout } from '../model/layout.ts';
import type { RunState } from '../orch/state.ts';
import type { Layer } from '../spec/layers.ts';
import { boundText, hasTarget, meets, scoredMoes, unscoredBecause, worstCase, worstCaseSense, type BoundRow } from '../spec/measures.ts';
import { step as stepById, type StepId } from '../spec/steps.ts';

type Weights = { moe: number; rubric: number; structure: number; resilience?: number };
type Score = EvaluationResult['scores'][number];

/** What the trade-off step wrote to its `step.json`. */
export interface RecordedTradeOff {
  chosen: number;
  scores: Score[];
  metrics: AlternativeMetrics[];
}

/** The `bounds` row a step recorded for one alternative, measure and sense; undefined when it wrote none. */
export type RecordedBound = (k: number, name: string, sense: 'min' | 'max') => BoundRow | undefined;

/** One measure of one alternative, re-scored, and where its worst case was read from. */
export type RescoredMeasure = AlternativeMetrics['moes'][number] & {
  /** The brief marks the target as a placeholder: it counts, and is labelled. */
  placeholder?: boolean;
  /** `payload`: the recorded `bounds` reports; `recorded`: the trade-off's own row — a read that crashed twice, or one that wrote no payload; `none`: neither. */
  source: 'payload' | 'recorded' | 'none';
};

export interface Rescore {
  step: StepId;
  layer: Layer;
  date: string;
  weights: Weights;
  recorded: { chosen: number; scores: Score[] };
  rescored: { chosen: number; scores: Score[] };
  /** Whether the current rules would choose another alternative than the one the layer was built from. */
  changed: boolean;
  /** One line per measure the rules now treat differently, or whose verdict moved. */
  changes: string[];
  measures: Array<{ k: number; moes: RescoredMeasure[] }>;
}

/**
 * The payloads `evaluateAlternatives` wrote beside the trade-off: the worst
 * case under `bounds-<measure>.json`, the other sense, asked only for a derived
 * estimate, under `bounds-<measure>.<sense>.json`. Matched by the row's own
 * sense, so a brief whose sense changed reads the row it now needs, or none.
 */
export function recordedBounds(auditDir: string): RecordedBound {
  return (k, name, sense) => {
    for (const file of [`bounds-${name}.${sense}.json`, `bounds-${name}.json`]) {
      const path = resolve(auditDir, `alt-${k}`, file);
      if (!existsSync(path)) continue;
      const report = JSON.parse(readFileSync(path, 'utf8')) as { bounds?: Array<BoundRow & { sense?: string }> };
      const row = report.bounds?.find((r) => r.sense === sense);
      if (row) return row;
    }
    return undefined;
  };
}

/**
 * The trade-off scored again: each alternative's measures judged against the
 * brief as it stands — a measure with no target and a target SEED set are
 * reported and not scored, a placeholder counts, a measure the solver crashed
 * under twice for any alternative is left out for all — and the totals summed
 * with `weights` over the recorded review, structure and resilience. No model
 * call, no solver run.
 */
export async function rescore(input: {
  step: StepId;
  layer: Layer;
  date: string;
  recorded: RecordedTradeOff;
  /** The current brief's measures and budgets; budgets are never scored. */
  moes: readonly Moe[];
  weights: Weights;
  bound: RecordedBound;
}): Promise<Rescore> {
  const current = scoredMoes(input.moes);
  const read: Array<AlternativeMetrics & { moes: RescoredMeasure[] }> = [];
  for (const alt of input.recorded.metrics) {
    const moes: RescoredMeasure[] = [];
    for (const moe of current) {
      const was = alt.moes.find((x) => x.name === moe.name);
      const base = {
        name: moe.name,
        sense: moe.sense,
        target: hasTarget(moe) ? moe.target : undefined,
        unit: moe.unit,
        unscored: unscoredBecause(moe),
        basis: was?.basis,
        placeholder: moe.placeholder === true || undefined,
      };
      if (was?.outcome === SOLVER_CRASHED_TWICE && was.sense === moe.sense) {
        // The record first: a crash leaves no payload of its own, but it can sit
        // beside one. A derived estimate's worst-sense payload is written before
        // the other sense is asked, and a re-run never clears `alt-<k>/`; read
        // alone, either payload scores a read that crashed twice as ½.
        moes.push({ ...base, outcome: was.outcome, value: was.value, detail: was.detail, met: meets(moe, was.outcome, was.value), source: 'recorded' });
      } else if (input.bound(alt.k, moe.name, worstCaseSense(moe.sense))) {
        const result = await worstCase(async (sense) => input.bound(alt.k, moe.name, sense), moe.sense);
        moes.push({ ...base, outcome: result.outcome, value: result.value, detail: result.detail, met: meets(moe, result.outcome, result.value), source: 'payload' });
      } else if (was && was.sense === moe.sense) {
        // No payload: a read with no estimate to bound, or a record from
        // before the payloads were kept.
        moes.push({ ...base, outcome: was.outcome, value: was.value, detail: was.detail, met: meets(moe, was.outcome, was.value), source: 'recorded' });
      } else {
        moes.push({ ...base, outcome: 'no estimate', source: 'none' });
      }
    }
    read.push({ ...alt, moes });
  }
  const measured = leaveOutCrashed(read).metrics;

  const scores = input.recorded.scores.map((s) => {
    const alt = measured.find((m) => m.k === s.k);
    const parts = { moe: alt ? moeScore(alt) : s.moe, rubric: s.rubric, structure: s.structure, resilience: s.resilience };
    return { k: s.k, ...parts, total: weightedTotal(input.weights, parts) };
  });
  const chosen = highestScoring(scores);
  return {
    step: input.step,
    layer: input.layer,
    date: input.date,
    weights: input.weights,
    recorded: { chosen: input.recorded.chosen, scores: input.recorded.scores },
    rescored: { chosen, scores },
    changed: chosen !== input.recorded.chosen,
    changes: whatChanged(input.recorded.metrics, measured, current),
    measures: measured.map((m) => ({ k: m.k, moes: m.moes })),
  };
}

/** How the score treats a measure: counted against a bound, or why not. */
const treatment = (row: { unscored?: Unscored; target?: number; sense: 'min' | 'max'; unit: string }): string => {
  if (row.unscored === 'no target') return 'no target, not scored';
  if (row.unscored === 'set by SEED') return `${boundText(row)} set by SEED, not scored`;
  if (row.unscored === 'solver crashed') return 'not scored: the solver crashed twice reading it';
  return hasTarget(row) ? `scored against ${boundText(row)}` : 'scored with no target (undecided, ½)';
};

const verdictText = (met: boolean | undefined): string => (met === undefined ? 'undecided' : met ? 'met' : 'missed');

/** Each measure the rules now treat differently from the record, and each verdict that moved. */
function whatChanged(recorded: AlternativeMetrics[], now: Array<{ k: number; moes: RescoredMeasure[] }>, current: readonly Moe[]): string[] {
  const lines: string[] = [];
  const names = [...new Set([...recorded.flatMap((m) => m.moes.map((x) => x.name)), ...current.map((m) => m.name)])];
  for (const name of names) {
    const before = recorded.map((m) => m.moes.find((x) => x.name === name)).find((x) => x !== undefined);
    const after = now.map((m) => m.moes.find((x) => x.name === name)).find((x) => x !== undefined);
    if (!after) {
      lines.push(`\`${name}\`: ${before ? treatment(before) : 'recorded'} then; no longer a measure the brief scores`);
      continue;
    }
    if (!before) {
      lines.push(`\`${name}\`: not in the record; now ${treatment(after)}`);
      continue;
    }
    if (treatment(before) !== treatment(after)) {
      lines.push(`\`${name}\`: ${treatment(before)} then; now ${treatment(after)}`);
      continue;
    }
    if (after.unscored !== undefined) continue;
    const moved = now
      .map((m) => ({ k: m.k, was: recorded.find((r) => r.k === m.k)?.moes.find((x) => x.name === name), is: m.moes.find((x) => x.name === name) }))
      .filter((x) => x.was && x.is && x.was.met !== x.is.met);
    if (moved.length > 0)
      lines.push(`\`${name}\`: ${moved.map((x) => `alternative ${x.k} ${verdictText(x.was!.met)} then, ${verdictText(x.is!.met)} now`).join('; ')}`);
  }
  return lines;
}

export const rescoreHeading = (date: string): string => `## Re-scored under the current rules (${date})`;

/** The section appended to `trade-off.md`. */
export function rescoreSection(r: Rescore): string {
  const weights = `measures ${r.weights.moe}, review ${r.weights.rubric}, structure ${r.weights.structure}, resilience ${r.weights.resilience ?? 0}`;
  const recordedScore = (k: number): Score | undefined => r.recorded.scores.find((s) => s.k === k);
  const placeholders = r.measures.some((m) => m.moes.some((x) => x.placeholder && x.unscored === undefined));
  return [
    rescoreHeading(r.date),
    '',
    'Appended by `mbse-workflow rescore`. The record above is the trade-off as it was made, and is unchanged; so is the layer. ' +
      'No model was called and no solver run: each alternative\'s worst case is read back from the `bounds` payloads recorded ' +
      `beside this file (\`alt-<k>/bounds-*.json\`) and judged against the brief as it stands now — a measure with no target, ` +
      'and a target SEED set, are reported and not scored; a placeholder target counts, and is labelled; a measure the solver ' +
      'crashed under twice for any alternative is left out for every alternative. The review, structure and resilience scores ' +
      `are the recorded ones; the totals use the configured weights (${weights}).`,
    '',
    r.changed
      ? `**THE CHOICE WOULD CHANGE: alternative ${r.rescored.chosen} scores highest under the current rules, and ${r.layer} was built ` +
        `from alternative ${r.recorded.chosen}.** Nothing has been rewritten. Run the trade-off again ` +
        `(\`resume --from-step ${r.step}\`) before relying on ${r.layer} or anything below it.`
      : `**The choice stands: alternative ${r.rescored.chosen}.**`,
    '',
    '| Alternative | Total, recorded | Total, re-scored | Measures, recorded | Measures, re-scored | Review | Structure | Resilience |',
    '|---|---|---|---|---|---|---|---|',
    ...r.rescored.scores.map((s) => {
      const was = recordedScore(s.k);
      return `| ${s.k} | ${was ? was.total.toFixed(3) : '—'} | ${s.total.toFixed(3)} | ${was ? was.moe.toFixed(2) : '—'} | ${s.moe.toFixed(2)} | ${s.rubric.toFixed(2)} | ${s.structure.toFixed(2)} | ${s.resilience.toFixed(2)} |`;
    }),
    '',
    ...(r.changes.length > 0
      ? ['What the current rules change:', '', ...r.changes.map((c) => `- ${c}`), '']
      : ['The current rules treat every measure as the record did; the totals differ only by the weights, if at all.', '']),
    '### Measures, re-scored',
    '',
    ...(placeholders ? ['A target marked (placeholder) is the brief\'s working number, awaiting the customer\'s: it is scored, and a miss against it is a number to take to the customer.', ''] : []),
    ...measuresTable(r.measures, (moe) => (hasTarget(moe) ? `${boundText(moe)}${moe.placeholder ? ' (placeholder)' : ''}` : '—')),
    '',
  ].join('\n');
}

/**
 * `trade-off.md` with the section at its end. A section of the same date —
 * this tool run again today — is replaced, never stacked; earlier dates and
 * the original record are kept as they are.
 */
export function withRescore(tradeOff: string, section: string, date: string): string {
  const heading = rescoreHeading(date);
  const at = tradeOff.indexOf(`\n${heading}\n`);
  let kept = tradeOff;
  if (at >= 0) {
    const next = tradeOff.indexOf('\n## Re-scored under the current rules (', at + heading.length + 1);
    kept = tradeOff.slice(0, at + 1) + (next >= 0 ? tradeOff.slice(next + 1) : '');
  }
  return `${kept.trimEnd()}\n\n${section.trimEnd()}\n`;
}

/** The measures of the brief as it stands: the run's state, else `brief.json`. */
function currentMoes(layout: ModelLayout, state: RunState | undefined): Moe[] {
  if (state?.brief?.moes) return state.brief.moes;
  if (existsSync(layout.briefJsonPath)) return (JSON.parse(readFileSync(layout.briefJsonPath, 'utf8')) as { moes?: Moe[] }).moes ?? [];
  throw new Error(`no brief in ${layout.dir}: neither state.json nor brief.json states the measures`);
}

/**
 * Re-score one trade-off step of a run, append the section to its
 * `trade-off.md` and write `rescore.json` beside it. Nothing else is written.
 */
export async function rescoreStep(
  layout: ModelLayout,
  state: RunState | undefined,
  stepId: StepId,
  weights: Weights,
  date: string,
): Promise<Rescore & { tradeOffPath: string; jsonPath: string }> {
  const spec = stepById(stepId);
  if (spec.agent !== 'EVALUATE' || !spec.layer) throw new Error(`${stepId} is not a trade-off step: re-score S33 (LA) or S42 (PA)`);
  const dir = layout.auditDirFor(stepId);
  const stepPath = resolve(dir, 'step.json');
  const tradeOffPath = resolve(dir, 'trade-off.md');
  if (!existsSync(stepPath) || !existsSync(tradeOffPath)) throw new Error(`${stepId} has no recorded trade-off in ${dir}: step.json and trade-off.md are both needed`);
  const recorded = JSON.parse(readFileSync(stepPath, 'utf8')) as RecordedTradeOff;
  if (!Array.isArray(recorded.scores) || !Array.isArray(recorded.metrics)) throw new Error(`${stepPath} records no scores and metrics`);

  const result = await rescore({
    step: stepId,
    layer: spec.layer,
    date,
    recorded,
    moes: currentMoes(layout, state),
    weights,
    bound: recordedBounds(dir),
  });
  writeFileSync(tradeOffPath, withRescore(readFileSync(tradeOffPath, 'utf8'), rescoreSection(result), date));
  const jsonPath = resolve(dir, 'rescore.json');
  writeFileSync(jsonPath, `${JSON.stringify(result, null, 2)}\n`);
  return { ...result, tradeOffPath, jsonPath };
}
