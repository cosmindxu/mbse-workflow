/**
 * The workflow, as a table.
 *
 * A typed copy of `06-agent-workflow.yaml` — `test/unit/spec-drift.test.ts`
 * holds the two together when the corpus is present. It is a copy rather than a
 * load because the yaml's `checks` are command strings and a command is only
 * half of a check: `trace --relation allocate` exits 0 on a layer where nothing
 * is allocated. What makes it a gate is the command PLUS a predicate scoped to
 * the layer being authored, so each check carries both.
 *
 * Two commands in the design are not runnable as written and are marked here
 * rather than silently dropped: `bounds` needs `--measure`, so the MoE bounds
 * are run by the EVALUATE agent which knows the measure names; and
 * `check-behaviour` needs `--element`, so it is run per state machine by the
 * bonus verification step rather than once over the model.
 */
import type { StatementKindFilter, TraceRelation } from '../sysprose/types.ts';
import type { Layer } from './layers.ts';

export type KnobId =
  | 'modes_states'
  | 'interfaces'
  | 'variability'
  | 'safety'
  | 'views'
  | 'verification'
  | 'requirements_intake'
  | 'infrastructure_intake';

export type AgentId =
  | 'SEED'
  | 'REQ-INTAKE'
  | 'INFRA-INTAKE'
  | 'AUTHOR'
  | 'TRANSITION'
  | 'ALTERNATIVES'
  | 'EVALUATE'
  | 'AUDIT'
  | 'CHECK';

export type GateId = 'G-SEED' | 'G-OA' | 'G-SA' | 'G-LA' | 'G-PA' | 'G-EPBS' | 'G-FINAL';

export type StepId =
  | 'S00' | 'S01' | 'S02'
  | 'S10' | 'S11' | 'S20' | 'S21' | 'S22'
  | 'S30' | 'S31' | 'S32' | 'S33' | 'S34'
  | 'S40' | 'S41' | 'S42' | 'S43'
  | 'S50' | 'S60' | 'S70';

/** Which analysis a check runs. */
export type CheckCmd =
  | 'check'
  | 'elements'
  | 'trace'
  | 'connectivity'
  | 'reach'
  | 'orphans'
  | 'requirements'
  | 'stats'
  | 'verify'
  | 'consistency'
  | 'refine'
  | 'evidence-status'
  | 'fault-tree'
  | 'check-behaviour';

export interface CheckArgs {
  relation?: TraceRelation;
  from?: string;
  to?: string;
  kind?: StatementKindFilter;
  via?: 'composition' | 'derive' | 'refine' | 'all';
}

/** Blocking either always, never, or only while a knob is on. */
export type Blocking = boolean | { knob: KnobId };

export interface CheckSpec {
  /** Unique in the step; also the name of its payload file in the audit packet. */
  name: string;
  cmd: CheckCmd;
  args?: CheckArgs;
  blocking: Blocking;
  /** Scoped post-conditions evaluated over this check's payload. */
  predicates?: PredicateId[];
}

export type PredicateId =
  | 'seed.briefShape'
  | 'intake.requirementShape'
  | 'intake.imposedShape'
  | 'oa.noSystemName'
  | 'oa.capabilities'
  | 'oa.systemEntity'
  | 'oa.members'
  | 'oa.namedFunctions'
  | 'replicas.memberPair'
  | 'replicas.topology'
  | 'moe.estimated'
  | 'moe.dutyCycleBound'
  | 'moe.transitBudget'
  | 'requirements.hazardsByComponent'
  | 'hazards.fromBrief'
  | 'hazards.notRestated'
  | 'modes.fromBrief'
  | 'rules.carried'
  | 'rules.hold'
  | 'common.itemFields'
  | 'faultTree.applicable'
  | 'alt.c2Placement'
  | 'functions.coordination'
  | 'functions.c2'
  | 'fleet.scenario'
  | 'fleet.configuration'
  | 'pa.bearer'
  | 'sa.fleetCarried'
  | 'sa.chains'
  | 'allocate.functionsAllocated'
  | 'trace.rowsRealiseUp'
  | 'trace.previousRealised'
  | 'trace.closure'
  | 'reach.codes'
  | 'connectivity.layerPorts'
  | 'orphans.layerPartDefs'
  | 'orphans.imposedUsed'
  | 'requirements.coverage'
  | 'requirements.hazards'
  | 'requirements.hazardsMitigated'
  | 'epbs.paPartsRealised'
  | 'skeleton.parses'
  | 'final.todos'
  | 'docs.coverage'
  | 'layer.functionsOnly';

export interface StepSpec {
  id: StepId;
  name: string;
  agent: AgentId;
  /** The fragment this step writes, if it writes one. */
  layer?: Layer;
  /** Runs only while this knob is on. */
  knob?: KnobId;
  /** The transition rule a TRANSITION step applies. */
  transition?: 'T01' | 'T02' | 'T03' | 'T04';
  /** ALTERNATIVES steps produce `limits.n_alternatives[layer]` fragments. */
  alternatives?: boolean;
  /** Rows of the mapping and the decision this step applies. */
  uses: string[];
  postconditions: string[];
  checks: CheckSpec[];
  /** Diagnostic codes this step's design calls out; blocking when they appear. */
  failCodes: string[];
  gate?: GateId;
  /** An AUDIT step packets these steps. */
  auditOf?: StepId[];
  /** Not runnable as a generic command — run by the named agent instead. */
  deferredChecks?: string[];
}

const check = (name = 'check'): CheckSpec => ({ name, cmd: 'check', blocking: true });

export const STEPS: readonly StepSpec[] = [
  {
    id: 'S00',
    name: 'SEED',
    agent: 'SEED',
    layer: 'Common',
    uses: ['B-02', 'B-04', 'B-05', 'CV-01', 'CV-02', 'CV-10', 'CV-19'],
    postconditions: [
      'mission sentence derived from the environment quadrants (B-02)',
      'function sentence: <System> <verb>s <object> from <state> to <state> (B-04)',
      'at least one capability',
      'at least one #MoE attribute with a require constraint (B-05)',
      'knob table recorded in the brief',
    ],
    checks: [check(), { name: 'elements', cmd: 'elements', blocking: true, predicates: ['seed.briefShape', 'common.itemFields'] }],
    failCodes: ['validation/duplicate-name', 'validation/blank-name'],
    gate: 'G-SEED',
  },
  {
    id: 'S01',
    name: 'REQ-INTAKE',
    agent: 'REQ-INTAKE',
    knob: 'requirements_intake',
    layer: 'Needs',
    uses: ['B-01', 'CV-09'],
    postconditions: [
      'every intake item is a requirement def with a subject and doc = the original text',
      '#Need or #Requirement per the need/requirement separation (A5-P-03)',
      'each statement follows one of the CESAM patterns (A5-R-04)',
    ],
    checks: [
      check(),
      {
        name: 'requirements',
        cmd: 'requirements',
        args: { kind: 'requirement' },
        blocking: true,
        predicates: ['intake.requirementShape'],
      },
      { name: 'consistency', cmd: 'consistency', blocking: false },
    ],
    failCodes: ['validation/requirement-subject'],
  },
  {
    id: 'S02',
    name: 'INFRA-INTAKE',
    agent: 'INFRA-INTAKE',
    knob: 'infrastructure_intake',
    layer: 'Imposed',
    uses: ['CV-02', 'CV-05'],
    postconditions: [
      'existing components as #Imposed part def with their ports',
      'imposed interfaces as interface def',
      'standards as #Standard requirement def',
      'each carries doc = the source reference',
    ],
    checks: [check(), { name: 'elements', cmd: 'elements', blocking: true, predicates: ['intake.imposedShape'] }],
    failCodes: ['validation/duplicate-name'],
  },
  {
    id: 'S10',
    name: 'AUTHOR-OA',
    agent: 'AUTHOR',
    layer: 'OA',
    uses: ['M1-STEP-01', 'M1-STEP-02', 'A1-R-06', 'CV-05', 'CV-07'],
    postconditions: [
      'when the brief declares a population: each coordination and command-and-control function the brief names is an OA action def of that name, capitalised, carrying its tag — the definition every member\'s activity is typed by',
      'every element of the layer carries a doc a reviewer can read (limits.doc_coverage_min)',
      'no element under OA is named like the system (A1-R-06)',
      'every capability the brief names is a #Capability use case def with a subject',
      'the entity the system takes over is declared under the exact name the brief gives, untagged',
      'when the brief declares a population: at least two representatives of that entity, each with activities of its own, and flows between them for what members exchange',
      'every operational activity is allocated to an entity',
      'every flow resolves at both ends',
      'operational modes are reachable',
    ],
    checks: [
      check(),
      { name: 'elements', cmd: 'elements', blocking: true, predicates: ['oa.noSystemName', 'oa.capabilities', 'oa.systemEntity', 'oa.namedFunctions', 'docs.coverage'] },
      {
        name: 'trace-allocate',
        cmd: 'trace',
        args: { relation: 'allocate', from: 'ActionUsage', to: 'PartUsage' },
        blocking: true,
        predicates: ['allocate.functionsAllocated', 'oa.members'],
      },
      { name: 'connectivity', cmd: 'connectivity', blocking: { knob: 'interfaces' }, predicates: ['connectivity.layerPorts'] },
      { name: 'reach', cmd: 'reach', blocking: { knob: 'modes_states' }, predicates: ['reach.codes'] },
    ],
    // `requirement-subject` blocks here, where it can be fixed. It was declared
    // at S21 and not at S10, so a subject-less requirement written in OA was
    // reported harmlessly at the layer that owns it and then sent to the SA
    // author, who cannot edit OA. Measured on OA::OperationalBudgets: three
    // repair rounds, two of them on that finding alone.
    failCodes: ['ref/unresolved-flow-end', 'validation/connector-endpoints', 'verification/unreachable-state', 'validation/requirement-subject'],
    gate: 'G-OA',
  },
  { id: 'S11', name: 'AUDIT-OA', agent: 'AUDIT', uses: [], postconditions: [], checks: [], failCodes: [], auditOf: ['S10'] },
  {
    id: 'S20',
    name: 'TRANSITION-OA-SA',
    agent: 'TRANSITION',
    layer: 'SA',
    transition: 'T01',
    uses: ['M1-T-01'],
    postconditions: ['the skeleton parses inside its prefix; TODO docs are allowed'],
    checks: [{ name: 'check', cmd: 'check', blocking: true, predicates: ['skeleton.parses'] }],
    failCodes: ['parse/mismatched-token', 'ref/unresolved-reference'],
  },
  {
    id: 'S21',
    name: 'AUTHOR-SA',
    agent: 'AUTHOR',
    layer: 'SA',
    uses: ['M1-STEP-04', 'M1-STEP-05', 'M1-STEP-06', 'CV-05', 'CV-07', 'B-03', 'CV-16', 'CV-18', 'CV-19'],
    postconditions: [
      'when the brief declares a population: every coordination and command-and-control function it names is a function of the system under that name, tagged #Coordination or #C2',
      'every hazard stated so far is satisfied by the function or component that mitigates it, or tagged #Accepted with its reason (safety knob)',
      'every element of the layer carries a doc a reviewer can read (limits.doc_coverage_min)',
      'every SA function and capability traces to OA',
      'every SA function is allocated to the system or to an actor',
      'the system ports are wired to the actors',
      'system modes are reachable',
      'requirement coverage is complete when the intake lane is on',
      '#Hazard requirements are declared for SA when the safety knob is on',
      'every hazard the brief names is a #Hazard requirement of that name at SA (safety knob)',
      'every mode the brief names is a state of its owner (modes_states knob)',
      'every rule the brief names is a #Rule requirement at SA and a property a state machine carries, and no carried rule fails',
    ],
    checks: [
      check(),
      { name: 'elements', cmd: 'elements', blocking: true, predicates: ['docs.coverage', 'functions.coordination', 'functions.c2', 'sa.fleetCarried', 'sa.chains', 'rules.carried', 'rules.hold'] },
      {
        name: 'trace-trace',
        cmd: 'trace',
        args: { relation: 'trace' },
        blocking: true,
        // The second one is a note here, never a gate: operational analysis
        // describes the whole operation and the system takes over a subset, so
        // an activity with no system function is a scope fact worth recording.
        predicates: ['trace.rowsRealiseUp', 'trace.previousRealised'],
      },
      {
        name: 'trace-allocate',
        cmd: 'trace',
        args: { relation: 'allocate', from: 'ActionUsage', to: 'PartUsage' },
        blocking: true,
        predicates: ['allocate.functionsAllocated'],
      },
      { name: 'connectivity', cmd: 'connectivity', blocking: { knob: 'interfaces' }, predicates: ['connectivity.layerPorts'] },
      { name: 'reach', cmd: 'reach', blocking: { knob: 'modes_states' }, predicates: ['reach.codes', 'modes.fromBrief'] },
      { name: 'requirements', cmd: 'requirements', blocking: { knob: 'requirements_intake' }, predicates: ['requirements.coverage'] },
      {
        name: 'requirements-hazards',
        cmd: 'requirements',
        args: { kind: 'requirement' },
        blocking: { knob: 'safety' },
        predicates: ['requirements.hazards', 'requirements.hazardsMitigated', 'hazards.fromBrief'],
      },
      { name: 'consistency', cmd: 'consistency', blocking: false },
    ],
    failCodes: [
      'ref/unresolved-reference',
      'validation/dangling-endpoint',
      'verification/unreachable-state',
      'validation/requirement-subject',
    ],
    gate: 'G-SA',
  },
  { id: 'S22', name: 'AUDIT-SA', agent: 'AUDIT', uses: [], postconditions: [], checks: [], failCodes: [], auditOf: ['S20', 'S21'] },
  {
    id: 'S30',
    name: 'TRANSITION-SA-LA',
    agent: 'TRANSITION',
    layer: 'LA',
    transition: 'T02',
    uses: ['M1-T-02'],
    postconditions: ['the skeleton parses inside its prefix; TODO docs are allowed'],
    checks: [
      { name: 'check', cmd: 'check', blocking: true, predicates: ['skeleton.parses'] },
      { name: 'connectivity', cmd: 'connectivity', blocking: false },
    ],
    failCodes: ['parse/mismatched-token', 'ref/unresolved-reference'],
  },
  {
    id: 'S31',
    name: 'AUTHOR-LA-FUNCTIONS',
    agent: 'AUTHOR',
    layer: 'LA',
    uses: ['M1-STEP-07', 'CV-16', 'CV-19'],
    postconditions: [
      'when the brief declares a population: no #Coordination or #C2 function is lost — renamed or split is fine, dropped is not',
      'every hazard stated so far is satisfied by the function or component that mitigates it, or tagged #Accepted with its reason (safety knob)',
      'every element of the layer carries a doc a reviewer can read (limits.doc_coverage_min)',
      'no LA function without a trace to an SA function',
      'no SA function left unrealised, except one allocated to an actor',
      'functions only: every function stays allocated to the placeholder component the skeleton provides — the decomposition into logical components is the next step\'s job, done several ways and compared',
    ],
    checks: [
      check(),
      { name: 'requirements-hazards', cmd: 'requirements', args: { kind: 'requirement' }, blocking: { knob: 'safety' }, predicates: ['requirements.hazards', 'requirements.hazardsMitigated', 'hazards.notRestated'] },
      { name: 'elements', cmd: 'elements', blocking: true, predicates: ['docs.coverage', 'layer.functionsOnly', 'functions.coordination', 'functions.c2'] },
      {
        name: 'trace-trace',
        cmd: 'trace',
        args: { relation: 'trace' },
        blocking: true,
        predicates: ['trace.rowsRealiseUp', 'trace.previousRealised'],
      },
      // Report-only, and collected for its data: the realisation predicates
      // exempt a function allocated to an actor, and this is where they read it.
      {
        name: 'trace-allocate',
        cmd: 'trace',
        args: { relation: 'allocate', from: 'ActionUsage', to: 'PartUsage' },
        blocking: false,
      },
    ],
    failCodes: ['ref/unresolved-reference'],
  },
  {
    id: 'S32',
    name: 'ALTERNATIVES-LA',
    agent: 'ALTERNATIVES',
    layer: 'LA',
    alternatives: true,
    uses: ['M1-STEP-08', 'CV-04', 'CV-05', 'CV-06', 'CV-07', 'CV-15', 'CV-08', 'CV-16', 'CV-17', 'CV-18', 'CV-19'],
    postconditions: [
      'every hazard stated at SA or below is satisfied by a component of this architecture, not only by a shared function, or tagged #Accepted (safety knob)',
      'every measure of effectiveness has a #Estimate attribute in the layer with its worst-case value and basis (CV-17)',
      'when the brief declares a population: one #Member part def, a fleet usage with its multiplicity, two representatives and a peer interface between them (CV-16)',
      'when the brief declares a population: every #C2 function keeps a ground usage in both alternatives; alternative 1 keeps the deciding #Coordination on the ground; alternative 2 puts at least half the #Coordination functions on the members',
      'every hazard stated so far is satisfied by the function or component that mitigates it, or tagged #Accepted with its reason (safety knob)',
      'every element of the layer carries a doc a reviewer can read (limits.doc_coverage_min)',
      'every LA function is allocated to a logical component',
      'no dangling port',
      'no component definition left unused',
      'component modes are reachable',
      'every #Imposed element is used when the infrastructure lane is on',
    ],
    checks: [
      check(),
      { name: 'requirements-hazards', cmd: 'requirements', args: { kind: 'requirement' }, blocking: { knob: 'safety' }, predicates: ['requirements.hazards', 'requirements.hazardsMitigated', 'requirements.hazardsByComponent', 'hazards.notRestated'] },
      { name: 'elements', cmd: 'elements', blocking: true, predicates: ['docs.coverage', 'replicas.memberPair', 'alt.c2Placement', 'replicas.topology', 'fleet.scenario', 'fleet.configuration', 'moe.estimated', 'moe.dutyCycleBound', 'moe.transitBudget', 'rules.carried', 'rules.hold'] },
      // An architecture is a way of carrying the functions, not a replacement
      // for them. Measured on a live run: both alternatives rewrote the layer
      // from scratch and dropped all 46 realization links, and the step cleared
      // — because it never asked. It asks now, exactly as the author step does.
      {
        name: 'trace-trace',
        cmd: 'trace',
        args: { relation: 'trace' },
        blocking: true,
        predicates: ['trace.rowsRealiseUp', 'trace.previousRealised'],
      },
      {
        name: 'trace-allocate',
        cmd: 'trace',
        args: { relation: 'allocate', from: 'ActionUsage', to: 'PartUsage' },
        blocking: true,
        predicates: ['allocate.functionsAllocated'],
      },
      { name: 'connectivity', cmd: 'connectivity', blocking: { knob: 'interfaces' }, predicates: ['connectivity.layerPorts'] },
      {
        name: 'orphans',
        cmd: 'orphans',
        blocking: true,
        predicates: ['orphans.layerPartDefs', 'orphans.imposedUsed'],
      },
      { name: 'reach', cmd: 'reach', blocking: { knob: 'modes_states' }, predicates: ['reach.codes', 'modes.fromBrief'] },
    ],
    failCodes: ['validation/dangling-endpoint', 'validation/connection-compatibility'],
  },
  {
    id: 'S33',
    name: 'EVALUATE-LA',
    agent: 'EVALUATE',
    layer: 'LA',
    uses: ['M1-STEP-09', 'M1-STEP-03', 'B-05', 'CV-17'],
    deferredChecks: ['bounds --measure <root>::<layer>::<MoE> (run by EVALUATE per measure per alternative, over the alternative\'s own #Estimate: the command needs a measure)'],
    postconditions: [
      'the chosen alternative carries its trade-off rationale inside the model (#prose)',
      'OA <- SA <- LA closure: every OA activity is reachable through trace',
    ],
    checks: [
      check(),
      { name: 'trace-trace', cmd: 'trace', args: { relation: 'trace' }, blocking: true, predicates: ['trace.closure'] },
      { name: 'verify', cmd: 'verify', blocking: false },
    ],
    failCodes: [],
    gate: 'G-LA',
  },
  { id: 'S34', name: 'AUDIT-LA', agent: 'AUDIT', uses: [], postconditions: [], checks: [], failCodes: [], auditOf: ['S30', 'S31', 'S32', 'S33'] },
  {
    id: 'S40',
    name: 'TRANSITION-LA-PA',
    agent: 'TRANSITION',
    layer: 'PA',
    transition: 'T03',
    uses: ['M1-T-03'],
    postconditions: ['the skeleton parses inside its prefix; TODO docs are allowed'],
    checks: [{ name: 'check', cmd: 'check', blocking: true, predicates: ['skeleton.parses'] }],
    failCodes: ['parse/mismatched-token', 'ref/unresolved-reference'],
  },
  {
    id: 'S41',
    name: 'ALTERNATIVES-PA',
    agent: 'ALTERNATIVES',
    layer: 'PA',
    alternatives: true,
    uses: ['M1-STEP-10-13', 'CV-05', 'CV-06', 'CV-12', 'B-03', 'CV-08', 'CV-16', 'CV-17', 'CV-18', 'CV-19'],
    deferredChecks: ['bounds --measure <root>::<layer>::<MoE> (run by EVALUATE per measure per alternative, over the alternative\'s own #Estimate: the command needs a measure)'],
    postconditions: [
      'every hazard stated at SA or below is satisfied by a component of this architecture, not only by a shared function, or tagged #Accepted (safety knob)',
      'when the brief declares a population: the member definition, fleet multiplicity and a typed link between two representatives survive into the physical architecture (CV-16)',
      'when the brief declares a population: every #C2 function keeps a ground usage in both alternatives; alternative 1 keeps the deciding #Coordination on the ground; alternative 2 puts at least half the #Coordination functions on the members',
      'every hazard stated so far is satisfied by the function or component that mitigates it, or tagged #Accepted with its reason (safety knob)',
      'every element of the layer carries a doc a reviewer can read (limits.doc_coverage_min)',
      'every function is allocated to a physical part',
      'behaviour parts are hosted in node parts (nesting, CV-06)',
      'physical links are typed by a connection def',
      'item definitions carry units',
      'every PA element traces to LA',
      'resource budgets are stated as require constraints',
      'every #Imposed element is used when the infrastructure lane is on',
    ],
    checks: [
      check(),
      { name: 'elements', cmd: 'elements', blocking: true, predicates: ['docs.coverage', 'replicas.memberPair', 'alt.c2Placement', 'replicas.topology', 'fleet.scenario', 'fleet.configuration', 'functions.coordination', 'functions.c2', 'pa.bearer', 'moe.estimated', 'moe.dutyCycleBound', 'moe.transitBudget', 'rules.carried', 'rules.hold'] },
      { name: 'connectivity', cmd: 'connectivity', blocking: { knob: 'interfaces' }, predicates: ['connectivity.layerPorts'] },
      {
        name: 'trace-trace',
        cmd: 'trace',
        args: { relation: 'trace' },
        blocking: true,
        predicates: ['trace.rowsRealiseUp', 'trace.previousRealised'],
      },
      // Found by the end-to-end test once the head no longer allocates to the
      // placeholder: the physical alternatives were never asked whether every
      // function has a part that performs it. The logical ones were.
      {
        name: 'trace-allocate',
        cmd: 'trace',
        args: { relation: 'allocate', from: 'ActionUsage', to: 'PartUsage' },
        blocking: true,
        predicates: ['allocate.functionsAllocated'],
      },
      { name: 'orphans', cmd: 'orphans', blocking: true, predicates: ['orphans.layerPartDefs', 'orphans.imposedUsed'] },
      { name: 'reach', cmd: 'reach', blocking: { knob: 'modes_states' }, predicates: ['reach.codes', 'modes.fromBrief'] },
      { name: 'requirements-hazards', cmd: 'requirements', args: { kind: 'requirement' }, blocking: { knob: 'safety' }, predicates: ['requirements.hazards', 'requirements.hazardsMitigated', 'requirements.hazardsByComponent', 'hazards.notRestated'] },
      { name: 'verify', cmd: 'verify', blocking: false },
    ],
    failCodes: ['validation/unknown-unit', 'validation/dimensional-consistency', 'verification/refuted'],
  },
  {
    id: 'S42',
    name: 'EVALUATE-PA',
    agent: 'EVALUATE',
    layer: 'PA',
    uses: ['M1-STEP-09', 'B-05', 'CV-17'],
    deferredChecks: ['bounds --measure <root>::<layer>::<MoE> (run by EVALUATE per measure per alternative, over the alternative\'s own #Estimate: the command needs a measure)'],
    postconditions: [
      'the chosen alternative carries its trade-off rationale inside the model (#prose)',
      'LA <- PA closure: every LA function is realised',
    ],
    checks: [
      check(),
      { name: 'trace-trace', cmd: 'trace', args: { relation: 'trace' }, blocking: true, predicates: ['trace.closure'] },
      { name: 'verify', cmd: 'verify', blocking: false },
    ],
    failCodes: [],
    gate: 'G-PA',
  },
  { id: 'S43', name: 'AUDIT-PA', agent: 'AUDIT', uses: [], postconditions: [], checks: [], failCodes: [], auditOf: ['S40', 'S41', 'S42'] },
  {
    id: 'S50',
    name: 'AUTHOR-EPBS',
    agent: 'AUTHOR',
    layer: 'EPBS',
    transition: 'T04',
    uses: ['M1-T-04', 'M1-STEP-14-17', 'CV-14', 'CV-09', 'CV-16'],
    postconditions: [
      'every hazard stated so far is satisfied by the function or component that mitigates it, or tagged #Accepted with its reason (safety knob)',
      'every element of the layer carries a doc a reviewer can read (limits.doc_coverage_min)',
      'every PA part is realised by a #CI_* part with a trace',
      'component contracts are requirement defs with a subject',
      'a verification def per chain or capability, with objective { verify R; }',
    ],
    checks: [
      check(),
      { name: 'requirements-hazards', cmd: 'requirements', args: { kind: 'requirement' }, blocking: { knob: 'safety' }, predicates: ['requirements.hazards', 'requirements.hazardsMitigated'] },
      { name: 'elements', cmd: 'elements', blocking: true, predicates: ['docs.coverage'] },
      {
        name: 'trace-trace',
        cmd: 'trace',
        args: { relation: 'trace', from: 'PartUsage' },
        blocking: true,
        predicates: ['epbs.paPartsRealised'],
      },
      { name: 'trace-verify', cmd: 'trace', args: { relation: 'verify' }, blocking: false },
      { name: 'refine', cmd: 'refine', args: { via: 'composition' }, blocking: false },
    ],
    failCodes: ['verification/refinement-failed', 'verification/refinement-undecided'],
    gate: 'G-EPBS',
  },
  {
    id: 'S60',
    name: 'VERIFY-BONUS',
    agent: 'CHECK',
    knob: 'verification',
    uses: ['M1-STEP-18'],
    postconditions: ['run and reported; never blocking (Q-04: verification is a bonus)'],
    checks: [
      { name: 'verify', cmd: 'verify', blocking: false },
      { name: 'consistency', cmd: 'consistency', blocking: false },
      { name: 'refine', cmd: 'refine', args: { via: 'composition' }, blocking: false },
      { name: 'evidence-status', cmd: 'evidence-status', blocking: false },
      { name: 'fault-tree', cmd: 'fault-tree', blocking: false, predicates: ['faultTree.applicable'] },
      // Per state machine: the properties it states, or — when it states none —
      // that every reachable configuration can get back to its initial state.
      { name: 'check-behaviour', cmd: 'check-behaviour', blocking: false },
    ],
    failCodes: [],
  },
  {
    id: 'S70',
    name: 'FINAL-AUDIT',
    agent: 'AUDIT',
    uses: ['CV-01'],
    postconditions: [
      'the assembled model checks clean through the shipped CLI',
      'trace closure OA <- SA <- LA <- PA <- EPBS',
      'requirement coverage reported',
      'every state machine walked',
      'connectivity, orphans and remaining TODO docs listed',
    ],
    checks: [
      check(),
      { name: 'stats', cmd: 'stats', blocking: false },
      { name: 'trace-trace', cmd: 'trace', args: { relation: 'trace' }, blocking: false, predicates: ['trace.closure'] },
      { name: 'trace-allocate', cmd: 'trace', args: { relation: 'allocate', from: 'ActionUsage', to: 'PartUsage' }, blocking: false },
      { name: 'requirements', cmd: 'requirements', blocking: false, predicates: ['requirements.coverage'] },
      { name: 'reach', cmd: 'reach', blocking: false },
      { name: 'connectivity', cmd: 'connectivity', blocking: false },
      { name: 'orphans', cmd: 'orphans', blocking: false },
      { name: 'elements', cmd: 'elements', blocking: false, predicates: ['final.todos'] },
      { name: 'evidence-status', cmd: 'evidence-status', blocking: false },
    ],
    failCodes: [],
    gate: 'G-FINAL',
    auditOf: ['S50', 'S60'],
  },
];

const BY_ID = new Map(STEPS.map((s) => [s.id, s]));

export const step = (id: StepId): StepSpec => {
  const found = BY_ID.get(id);
  if (!found) throw new Error(`unknown step ${id}`);
  return found;
};

/** The command a reader types to reproduce one check. */
export function checkCommand(spec: CheckSpec, file: string): string {
  if (spec.cmd === 'check') return `npm run check -- ${file} --json`;
  const args: string[] = [];
  if (spec.args?.relation) args.push('--relation', spec.args.relation);
  if (spec.args?.from) args.push('--from', spec.args.from);
  if (spec.args?.to) args.push('--to', spec.args.to);
  if (spec.args?.kind) args.push('--kind', spec.args.kind);
  if (spec.args?.via) args.push('--via', spec.args.via);
  // One run per state machine; the packet's payload lists each with its element.
  if (spec.cmd === 'check-behaviour') args.push('--element', '<each state machine>');
  return `npm run sysprose -- ${spec.cmd} ${file} ${args.join(' ')} --json`.replace(/\s+/g, ' ');
}

export const isBlocking = (blocking: Blocking, knobs: Record<KnobId, boolean>): boolean =>
  typeof blocking === 'boolean' ? blocking : knobs[blocking.knob] === true;
