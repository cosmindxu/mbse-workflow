/**
 * What a person's edit costs, layer by layer.
 *
 * The workflow says a contributor edits a layer's fragment and resumes: the
 * edited layer is re-checked, never re-authored, and everything built on it is
 * set back to pending. That was tested and never measured. This measures it on
 * a finished run, for every layer at once, without touching a file: the edit is
 * simulated on a copy of the state by giving the layer a hash no step saw, and
 * the invalidation the resume would perform is read back.
 *
 *   edit surface  — the one fragment a person opens, and its size;
 *   blast radius  — the steps a resume re-checks and the steps it re-runs;
 *   re-run cost   — what those re-run steps spent in this run, from the call log.
 */
import { existsSync, readFileSync } from 'node:fs';
import type { ModelLayout } from '../model/layout.ts';
import { invalidate } from '../orch/invalidate.ts';
import type { RunState } from '../orch/state.ts';
import { LAYERS, type Layer } from '../spec/layers.ts';
import type { StepId } from '../spec/steps.ts';

export interface ContributionRow {
  layer: Layer;
  fragmentLines: number;
  recheck: StepId[];
  invalidated: StepId[];
  /** Model calls the re-run steps made in this run, and what they cost; killed calls are counted and cost unknown. */
  rerunCalls: number;
  rerunUsd: number;
}

export interface LoggedCall {
  tag: string;
  ok?: boolean;
  costUsd?: number;
}

export function contributionSurface(state: RunState, layout: ModelLayout, calls: LoggedCall[]): ContributionRow[] {
  const rows: ContributionRow[] = [];
  for (const layer of LAYERS) {
    const path = layout.fragmentPath(layer);
    if (!existsSync(path)) continue;
    const copy = structuredClone(state);
    let seen = false;
    for (const record of Object.values(copy.steps)) {
      if (record?.fragmentHashes?.[layer] !== undefined) {
        record.fragmentHashes[layer] = `edited:${record.fragmentHashes[layer]}`;
        seen = true;
      }
    }
    if (!seen) continue;
    const result = invalidate(copy, layout);
    const rerun = new Set<string>(result.invalidated);
    const spent = calls.filter((c) => rerun.has(c.tag.split(':')[0]));
    rows.push({
      layer,
      fragmentLines: readFileSync(path, 'utf8').split('\n').length,
      recheck: result.recheck,
      invalidated: result.invalidated,
      rerunCalls: spent.length,
      rerunUsd: spent.reduce((n, c) => n + (c.costUsd ?? 0), 0),
    });
  }
  return rows;
}

export function readCallLog(path: string): LoggedCall[] {
  if (!existsSync(path)) return [];
  return readFileSync(path, 'utf8')
    .split('\n')
    .filter((l) => l.trim().startsWith('{'))
    .map((l) => JSON.parse(l) as LoggedCall);
}

/**
 * The call log against the legs' totals. A leg's spend is saved when a step
 * finishes, so a leg stopped mid-step loses what that step's finished calls
 * cost — measured in v6: three S32 calls, 7.41 USD, absent from the total.
 * The log keeps every call that returned; it is the floor.
 */
export function unrecordedSpend(recorded: { calls: number; costUsd: number }, calls: LoggedCall[]): string | undefined {
  const logged = calls.filter((c) => c.ok !== false);
  const cost = logged.reduce((n, c) => n + (c.costUsd ?? 0), 0);
  if (cost <= recorded.costUsd + 0.005) return undefined;
  return `the call log holds ${logged.length} call(s), ${cost.toFixed(2)} USD — ${(cost - recorded.costUsd).toFixed(2)} USD more than the legs recorded, spent by a leg stopped mid-step; the log is the floor`;
}

export function contributionMarkdown(rows: ContributionRow[]): string[] {
  if (rows.length === 0) return [];
  const span = (ids: StepId[]): string => (ids.length === 0 ? '—' : ids.length === 1 ? ids[0] : `${ids[0]}…${ids.at(-1)} (${ids.length})`);
  return [
    '## What an edit costs',
    '',
    'If a person edits one layer\'s fragment and resumes: the step that wrote it is re-checked (never re-authored), and every step built on it runs again. The cost is what those steps spent in this run — a guide, since a resume may repair less or more.',
    '',
    '| Layer edited | Fragment lines | Re-checked | Runs again | Calls those steps made | USD |',
    '|---|---|---|---|---|---|',
    ...rows.map((r) => `| ${r.layer} | ${r.fragmentLines} | ${r.recheck.join(', ') || '—'} | ${span(r.invalidated)} | ${r.rerunCalls} | ${r.rerunUsd.toFixed(2)} |`),
    '',
  ];
}
