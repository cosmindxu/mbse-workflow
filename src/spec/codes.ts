/**
 * Diagnostic codes, and the house rule behind the ones that have one.
 *
 * Sysprose's own contract is that automation branches on `code`, never on
 * `message`, and every text-derived finding carries a code and a range. This
 * table adds the only thing the diagnostic cannot know: which convention the
 * author broke, so the repair prompt can quote the rule instead of the symptom.
 * A code with no entry still repairs — it arrives with the tool's own `hint`.
 */
import type { KnobId } from './steps.ts';

/** Families, in the order a report reads them. */
export const BLOCKING_FAMILIES = ['lexer', 'parse', 'mapper', 'ref', 'validation', 'import'] as const;
export const REPORT_FAMILIES = ['verification', 'property', 'evidence', 'semantic'] as const;

export const familyOf = (code: string): string => code.split('/')[0] ?? '';

/**
 * Codes whose blocking status follows a knob rather than their family.
 *
 * The design's policy table (06 §6): a mode that cannot be reached is a finding
 * about a model that claims modes, so it blocks while `modes_states` is on and
 * is reported otherwise; a dangling port is a finding about interfaces.
 */
export const KNOB_CONDITIONAL: Record<string, KnobId> = {
  'verification/unreachable-state': 'modes_states',
  'verification/dead-transition': 'modes_states',
  'verification/deadlock': 'modes_states',
  'validation/dangling-endpoint': 'interfaces',
};

/**
 * Codes that report and never block, whatever their family and severity.
 *
 * `validation/target-by-specialisation` is Sysprose holding a target written
 * in Common against each layer's estimate of its measure: one verdict per
 * layer. A miss is a result of the trade-off — the final audit's "No
 * architecture compared meets these" — not the fragment contradicting itself,
 * and a repair round spent on it can only raise an estimate to meet the
 * target, which is the one answer CV-17 forbids. It is a `validation/*` code,
 * which blocks on an error; this keeps it reported if Sysprose ever raises one.
 */
export const REPORTED_ONLY: ReadonlySet<string> = new Set(['validation/target-by-specialisation']);

/** The target-verdict code, named once: the repair prompt keeps it out of the repair list. */
export const TARGET_VERDICT = 'validation/target-by-specialisation';

export interface CodeNote {
  /** The convention that answers it. */
  cv?: string;
  /** One line an author can act on, when the tool's own hint needs the house context. */
  note: string;
}

export const CODE_NOTES: Record<string, CodeNote> = {
  'validation/duplicate-name': {
    cv: 'CV-01',
    note: 'Two elements share a name in one scope. Layer packages are separate scopes — qualify the reference instead of renaming, unless the clash is inside one layer.',
  },
  'validation/blank-name': {
    note: 'Every element this workflow writes is named: an unnamed element cannot be traced, allocated or reported.',
  },
  'validation/requirement-subject': {
    cv: 'CV-09',
    note: 'A requirement needs a subject. Give it `subject <name> : <PartDef>;` naming the part the requirement is about.',
  },
  'validation/dangling-endpoint': {
    cv: 'CV-05',
    note: 'A connection names an end that is not a port on the part. Connect `<part>.<port>` to `<part>.<port>`; declare the port on the part definition first.',
  },
  'validation/connection-compatibility': {
    cv: 'CV-05',
    note: 'A connection joins an `out` port to an `in` port carrying the same item. Two `in` ports (or two `out`) usually means one end is a port of the layer above — a delegation across layers, which is expressed by allocation and trace, not by a connection: remove it and connect the component to the actor of this layer instead. Otherwise type both ports with the same port def.',
  },
  'validation/connector-endpoints': {
    cv: 'CV-05',
    note: 'A connector needs exactly two ends, both resolvable in this scope. A «Succession» with one endpoint inside a state definition is a transition written in the anonymous form (`first a accept e : E then b;`), which this dialect does not read as a transition: write `transition t first a accept e : E do action x then b;`, or `transition a -> b;` when there is no trigger.',
  },
  'validation/port-direction': {
    cv: 'CV-05',
    note: 'A flow runs out of an `out` port into an `in` port. Check the direction on both port defs.',
  },
  'validation/unknown-unit': {
    note: 'Units come from the standard library (ISQ). Use a library unit, or drop the unit and state the budget in the doc.',
  },
  'validation/dimensional-consistency': {
    note: 'The two sides of the constraint are not the same dimension. Compare a mass with a mass, a duration with a duration.',
  },
  'validation/redefinition-conformance': {
    note: 'A redefinition (`:>>`) must conform to what it redefines: same kind, compatible type and multiplicity.',
  },
  'validation/constraint-violation': {
    cv: 'CV-17',
    note: "This layer's own values violate the constraint. If it fixes an `#Estimate`, do not also state the estimate as a literal: make the `#Estimate` valueless and let the `assert constraint` derive it from this layer's values (CV-17). Otherwise correct the value that contradicts its documented basis.",
  },
  'validation/target-by-specialisation': {
    cv: 'CV-17',
    note: "A target held against this layer's estimate of its measure: a verdict, per layer, on the brief's target — a result of the comparison, not a defect in the fragment. Do not change an estimate to meet it; an estimate is the worst case this design delivers, with its basis in the doc. A target no architecture meets is a question for whoever set it.",
  },
  'ref/unresolved-reference': {
    cv: 'CV-01',
    note: 'A name resolves to nothing. References across layers are qualified: `<Root>::<Layer>::<name>`. References downward are not allowed at all (A1-R-05).',
  },
  'ref/unresolved-flow-end': {
    cv: 'CV-05',
    note: 'A flow end names something that is not there. The form is `flow <name> of <Item> from <fn>.<out> to <fn>.<in>;` and both actions must own those ports.',
  },
  'ref/unresolved-allocation-end': {
    cv: 'CV-04',
    note: 'An allocation end is unresolved. The form is the bare `allocate <actionUsage> to <partUsage>;`, both named in scope.',
  },
  'ref/unresolved-connection-end': {
    cv: 'CV-05',
    note: 'A connection end is unresolved: declare the port on the part definition, then connect `<part>.<port>`.',
  },
  'ref/unresolved-type': {
    note: 'A declared type is not in the model or the library. Define it in `package Common`, or use a library type.',
  },
  'ref/unresolved-requirement': {
    cv: 'CV-09',
    note: 'A satisfy/verify/refine names a requirement that is not there. A requirement def and its usage are separate elements — name the one you mean.',
  },
  'parse/mismatched-token': {
    note: 'The grammar expected something else here. Most often a missing `;`, an unbalanced brace, or a feature named after a keyword.',
  },
  'parse/unknown-keyword': {
    cv: 'CV-02',
    note: 'A `#Tag` must be declared as `metadata def <Tag>;` in `package Kinds` before it is used.',
  },
  'parse/dangling-then': {
    cv: 'CV-13',
    note: 'A succession needs both ends: `first <a> then <b>;`. Control nodes are declared bare first.',
  },
  'parse/conflicting-direction': {
    note: 'A feature is given two directions. One of `in`, `out`, `inout`.',
  },
  'mapper/unsupported-keyword': {
    note: 'The parser read this keyword but the model has no place for it. It is one of the constructs this dialect does not carry — see the conventions for the supported spelling.',
  },
  'verification/unreachable-state': {
    cv: 'CV-07',
    note: 'A state no transition can arrive at. Add the transition, or delete the state.',
  },
  'verification/dead-transition': {
    cv: 'CV-07',
    note: 'A transition whose guard can never hold in any reachable configuration.',
  },
  'verification/nondeterministic-choice': {
    cv: 'CV-07',
    note: 'Two transitions are enabled at once and declaration order decides. Give them disjoint guards or distinct triggers — declaration order is not a semantics.',
  },
  'verification/inconsistent-requirements': {
    cv: 'CV-09',
    note: 'Two requirements on the same subject cannot both hold. Relax one, or split the subject.',
  },
  'verification/refinement-undecided': {
    note: 'The solver could not decide whether the component contracts imply the system contract. Reported, never blocking.',
  },
};

export const noteFor = (code: string): CodeNote | undefined => CODE_NOTES[code];

/**
 * The note for a target verdict on a measure whose target is not the
 * customer's: a placeholder the brief marks, or one SEED set where the brief
 * gave no number. Missing it is "missed a placeholder" — something to take to
 * the customer — and no architecture should be failed on it (v9's
 * `unattendedWatchDurationHours` says so in its own doc).
 */
export const PLACEHOLDER_MISS_NOTE: CodeNote = {
  cv: 'CV-17',
  note: "Missed a placeholder: this target is not the customer's number yet (a placeholder in the brief, or one SEED set where the brief gave none). It is reported so the number is revisited with the customer — not a failure of this design, and never a reason to change an estimate.",
};
