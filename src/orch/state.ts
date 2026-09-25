/**
 * What the run knows about itself.
 *
 * Written after every transition, atomically, because the two things a long
 * run has to survive are a machine that stops and a person who edits a fragment
 * halfway through. Both come back through this file: the step statuses say what
 * was done, and the fragment hashes say whether it is still true.
 */
import { existsSync, readFileSync, renameSync, writeFileSync } from 'node:fs';
import type { Layer } from '../spec/layers.ts';
import type { GateId, StepId } from '../spec/steps.ts';
import type { RunMode } from '../config/schema.ts';
import type { SeedOutput } from '../llm/schemas.ts';

export type StepStatus = 'pending' | 'running' | 'done' | 'blocked' | 'skipped';

export interface GateRecord {
  gate: GateId;
  decision: 'approve' | 'reject' | 'auto';
  comments?: string;
  at: string;
}

export interface AlternativeRecord {
  k: number;
  status: StepStatus;
  iterations: number;
  score?: number;
  chosen?: boolean;
}

export interface StepRecord {
  status: StepStatus;
  /** How many repair rounds this step needed. */
  iterations: number;
  prefixHash?: string;
  fragmentHashes?: Partial<Record<Layer, string>>;
  verdictPath?: string;
  blocking?: number;
  gate?: GateRecord;
  alternatives?: AlternativeRecord[];
  startedAt?: string;
  finishedAt?: string;
  note?: string;
}

export interface RunState {
  version: 1;
  root: string;
  mode: RunMode;
  knobs: Record<string, boolean>;
  sysprose: { dir: string; commit: string; expected: string; matches: boolean };
  brief?: SeedOutput;
  steps: Partial<Record<StepId, StepRecord>>;
  current?: StepId;
  /** The whole run: the legs added up. */
  llm: { calls: number; costUsd: number; durationMs: number; killed?: number };
  /**
   * One entry per process that worked on the run. Before legs were kept,
   * `llm` was overwritten by each leg, and v3's state said 7.18 USD for ~22.
   */
  legs?: Leg[];
  /**
   * What a person said when they rejected a gate, by step id.
   *
   * A comment used to be written into the layer's fragment as a `#prompt`
   * element and nothing else. That works where an author runs again and reads
   * its own layer (G-OA, G-SA, G-EPBS), and is lost where the step rewrites
   * that file: SEED rewrites Common, and EVALUATE copies the chosen
   * alternative over the head before its rubric — so at G-SEED, G-LA and G-PA
   * the comment vanished between the decision and the re-run. Kept here, the
   * step that runs again can be handed what the person said.
   */
  gateComments?: Partial<Record<StepId, string[]>>;
  startedAt: string;
  updatedAt: string;
}

export interface Leg {
  startedAt: string;
  calls: number;
  costUsd: number;
  durationMs: number;
  killed: number;
}

/** Opens a leg for this process; a state from before legs becomes its first. */
export function openLeg(state: RunState, now = new Date().toISOString()): Leg {
  if (!state.legs) {
    const { calls, costUsd, durationMs, killed } = state.llm;
    state.legs = calls > 0 || costUsd > 0 ? [{ startedAt: state.startedAt, calls, costUsd, durationMs, killed: killed ?? 0 }] : [];
  }
  const leg: Leg = { startedAt: now, calls: 0, costUsd: 0, durationMs: 0, killed: 0 };
  state.legs.push(leg);
  return leg;
}

/** Records what this leg has spent and totals every leg into `llm`. */
export function recordSpend(state: RunState, leg: Leg, spent: { calls: number; costUsd: number; durationMs: number; killed?: number }): void {
  Object.assign(leg, { calls: spent.calls, costUsd: spent.costUsd, durationMs: spent.durationMs, killed: spent.killed ?? 0 });
  const legs = state.legs ?? [leg];
  state.llm = {
    calls: legs.reduce((n, l) => n + l.calls, 0),
    costUsd: legs.reduce((n, l) => n + l.costUsd, 0),
    durationMs: legs.reduce((n, l) => n + l.durationMs, 0),
    killed: legs.reduce((n, l) => n + l.killed, 0),
  };
}

export function emptyState(init: Pick<RunState, 'root' | 'mode' | 'knobs' | 'sysprose'>): RunState {
  const now = new Date().toISOString();
  return {
    version: 1,
    ...init,
    steps: {},
    llm: { calls: 0, costUsd: 0, durationMs: 0 },
    startedAt: now,
    updatedAt: now,
  };
}

export function loadState(path: string): RunState | undefined {
  if (!existsSync(path)) return undefined;
  return JSON.parse(readFileSync(path, 'utf8')) as RunState;
}

/** Write through a temporary file: a half-written state file is worse than none. */
export function saveState(path: string, state: RunState): void {
  state.updatedAt = new Date().toISOString();
  const tmp = `${path}.tmp`;
  writeFileSync(tmp, `${JSON.stringify(state, null, 2)}\n`);
  renameSync(tmp, path);
}

export function stepRecord(state: RunState, id: StepId): StepRecord {
  const existing = state.steps[id];
  if (existing) return existing;
  const created: StepRecord = { status: 'pending', iterations: 0 };
  state.steps[id] = created;
  return created;
}
