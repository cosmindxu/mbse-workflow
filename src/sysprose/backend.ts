/**
 * The one door to Sysprose.
 *
 * Two implementations behind it: `inprocess` imports the checker and the
 * analytics API directly (one library parse per process, ~170 ms per model
 * load after the first), `spawn` shells out to the two CLIs (~3 s per call) and
 * exists so a Sysprose whose internals moved can still be driven. Both publish
 * the same payloads; `test/unit/backend-parity.test.ts` holds them against
 * recorded CLI output.
 */
import type { Model } from '@core/index';
import type { Layer } from '../spec/layers.ts';
import type { LayerView } from '../transition/view.ts';
import type {
  BoundsReport,
  CheckReport,
  ConnectivityReport,
  ConsistencyReport,
  ElementRow,
  EvidenceStatusReport,
  FaultTreeReport,
  BehaviourReport,
  ImpactReport,
  ModelMetrics,
  OrphanReport,
  PromptReport,
  ReachReport,
  RefinementReport,
  RequirementsPayload,
  StatementKindFilter,
  SysproseVersion,
  TracePayload,
  TraceRelation,
  VerifyReport,
} from './types.ts';

/** A model that has been parsed and bound, with the lock still held. */
export interface Loaded {
  readonly model: Model;
  readonly report: CheckReport;
  readonly text: string;
  readonly displayName: string;
}

/**
 * Which `#Keyword`s sit on which element.
 *
 * Every convention in this project tags elements — layer, role, mode, hazard,
 * MoE, imposed — and no report publishes the tags, so the post-conditions ask
 * the model itself. Cheap: one walk of the user elements per loaded model.
 */
export interface TagIndex {
  byElement: Map<string, string[]>;
  byKeyword: Map<string, string[]>;
  has(qualifiedName: string, keyword: string): boolean;
  taggedWith(keyword: string): string[];
}

/** Every analysis this project runs, over one loaded model. */
export interface Analyses {
  elements(m: Loaded, includeLibrary?: boolean): ElementRow[];
  tags(m: Loaded): TagIndex;
  /** One layer, structured for the transition rules (relationships and directions included). */
  layerView(m: Loaded, layer: Layer): LayerView;
  trace(m: Loaded, relation: TraceRelation, from?: string, to?: string): TracePayload;
  connectivity(m: Loaded): ConnectivityReport;
  orphans(m: Loaded): OrphanReport;
  requirements(m: Loaded, kind?: StatementKindFilter): RequirementsPayload;
  stats(m: Loaded): ModelMetrics;
  reach(m: Loaded, scope?: string): ReachReport;
  prompts(m: Loaded, ref: string): PromptReport;
  whereUsed(m: Loaded, ref: string, depth?: number): ImpactReport;
  verify(m: Loaded): Promise<VerifyReport>;
  consistency(m: Loaded): Promise<ConsistencyReport>;
  refine(m: Loaded, via?: 'composition' | 'derive' | 'refine' | 'all'): Promise<RefinementReport>;
  bounds(m: Loaded, measure: string, sense?: 'min' | 'max'): Promise<BoundsReport>;
  faultTree(m: Loaded): Promise<FaultTreeReport>;
  /** One state machine's properties — its own, or `pattern` when it states none. */
  behaviour(m: Loaded, machineId: string, pattern?: string): BehaviourReport;
  evidenceStatus(m: Loaded): EvidenceStatusReport;
}

export interface SysproseBackend extends Analyses {
  readonly kind: 'inprocess' | 'spawn';
  version(): Promise<SysproseVersion>;
  /**
   * Load `text`, hand it to `fn`, drop it. The queue lock is held for the whole
   * callback: everything the step needs from one model is asked inside it.
   */
  withModel<T>(text: string, displayName: string, fn: (m: Loaded) => Promise<T> | T): Promise<T>;
  /** Just the checker — no analytics, no model kept. */
  check(text: string, displayName: string): Promise<CheckReport>;
}

/** An element reference that resolved to nothing, or to more than one thing. */
export class ElementRefError extends Error {
  readonly candidates: string[];
  constructor(message: string, candidates: string[] = []) {
    super(message);
    this.name = 'ElementRefError';
    this.candidates = candidates;
  }
}
