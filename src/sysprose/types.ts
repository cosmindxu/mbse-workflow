/**
 * The payload shapes this project consumes.
 *
 * Every one of them is the shape the Sysprose CLI publishes under its
 * `payloadKey` — the in-process backend rebuilds them from the same API
 * functions the CLI calls, and `test/unit/backend-parity.test.ts` holds the two
 * against recorded CLI output. Where a type already exists in the Sysprose API
 * it is derived from the function that returns it rather than restated, so a
 * change over there is a type error here rather than a silent drift.
 */
import type {
  connectivityReport,
  orphanReport,
  modelMetrics,
  promptsFor,
  impactClosure,
  reachReport,
  verifyModel,
  consistencyReport,
  refinementReport,
  boundsReport,
  faultTreeReport,
  evidenceStatus,
  behaviourReport,
} from '@api/index';
import type { CheckReport } from '@text/load';

export type { CheckReport };
export type ConnectivityReport = ReturnType<typeof connectivityReport>;
export type OrphanReport = ReturnType<typeof orphanReport>;
export type ModelMetrics = ReturnType<typeof modelMetrics>;
export type PromptReport = ReturnType<typeof promptsFor>;
export type ImpactReport = ReturnType<typeof impactClosure>;
export type ReachReport = ReturnType<typeof reachReport>;
export type VerifyReport = Awaited<ReturnType<typeof verifyModel>>;
export type ConsistencyReport = Awaited<ReturnType<typeof consistencyReport>>;
export type RefinementReport = Awaited<ReturnType<typeof refinementReport>>;
export type BoundsReport = Awaited<ReturnType<typeof boundsReport>>;
export type FaultTreeReport = Awaited<ReturnType<typeof faultTreeReport>>;
export type BehaviourReport = ReturnType<typeof behaviourReport>;
export type EvidenceStatusReport = ReturnType<typeof evidenceStatus>;

/** The six relationship families `trace --relation` accepts. */
export type TraceRelation = 'satisfy' | 'allocate' | 'verify' | 'refine' | 'derive' | 'trace';

/** How `--kind` narrows the requirements table. */
export type StatementKindFilter = 'requirement' | 'prose' | 'prompt';

/** One element as every report refers to it. */
export interface ElementRef {
  id: string;
  eClass: string;
  declaredName?: string;
  qualifiedName: string;
}

/** One row of `elements`. */
export interface ElementRow {
  id: string;
  qualifiedName: string;
  name: string;
  metaclass: string;
  type: string;
  multiplicity: string;
  value: string;
  redefines: string;
  doc: string;
}

export interface TraceLink {
  from: string;
  to: string;
  relationshipId: string;
  fromName: string;
  toName: string;
}

export interface TracePayload {
  relation: string;
  relationshipKinds: string[];
  fromKinds: string[];
  toKinds: string[];
  rows: ElementRef[];
  columns: ElementRef[];
  cells: boolean[][];
  links: TraceLink[];
  /** Labels, not refs — "links to nothing". */
  unlinkedRows: string[];
  /** Labels, not refs — "nothing links to". */
  unlinkedColumns: string[];
  libraryExcluded: number;
  implicitExcluded: number;
  unresolvedTypings: number;
}

export interface RequirementRow {
  id: string;
  number: string;
  reqId: string;
  name: string;
  metaclass: string;
  /** `undefined` on a row the statement-kind reading does not classify. */
  kind: string | undefined;
  text: string;
  /** `null` on a statement nothing is supposed to satisfy (prose, prompt). */
  satisfied: boolean | null;
  satisfiedBy: string[];
  verifiedBy: string[];
  refinedBy: string[];
  tracedTo: string[];
  derivedFrom: string[];
}

export interface RequirementsPayload {
  total: number;
  satisfied: number;
  coverage: number;
  libraryExcluded: number;
  implicitExcluded: number;
  nonNormativeExcluded: number;
  kind: StatementKindFilter | null;
  rows: RequirementRow[];
}

/** What `version()` reports about the Sysprose checkout being driven. */
export interface SysproseVersion {
  dir: string;
  commit: string;
  expected: string;
  matches: boolean;
}
