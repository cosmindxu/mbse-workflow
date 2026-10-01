/**
 * Blocking, or reported?
 *
 * The distinction is the whole repair policy: a blocking finding sends the
 * fragment back to an agent and, unfixed, stops the run at a gate; a reported
 * one is written into the packet and the run goes on. Getting it wrong in
 * either direction is expensive — a run that stops on an inconclusive solver,
 * or one that ships a model whose flows do not resolve.
 *
 * Precedence, highest first:
 *   1. a code the design ties to a knob (an unreachable mode blocks while
 *      modes_states is on, and is a note when it is off),
 *   2. a code this step's design names as its failure,
 *   3. a code that only ever reports (`REPORTED_ONLY`: a target's verdict),
 *   4. the family: text that did not lex, parse, map, resolve or validate is a
 *      finding about the fragment; verification outcomes are not,
 *   5. severity: warnings and infos report.
 */
import { BLOCKING_FAMILIES, KNOB_CONDITIONAL, PLACEHOLDER_MISS_NOTE, REPORTED_ONLY, TARGET_VERDICT, familyOf, noteFor } from '../spec/codes.ts';
import type { KnobId, StepSpec } from '../spec/steps.ts';
import type { Layer } from '../spec/layers.ts';

export type Severity = 'error' | 'warning' | 'info';

/** One thing to fix, from a diagnostic or from a scoped post-condition. */
export interface RepairItem {
  source: 'diagnostic' | 'predicate' | 'preflight';
  /** Diagnostic code, predicate id, or preflight code. */
  code: string;
  severity: Severity;
  message: string;
  hint?: string;
  /** The convention that answers it, when there is one. */
  cv?: string;
  qualifiedName?: string;
  layer?: Layer;
  /** 1-based line in the assembled file. */
  prefixLine?: number;
  /** 1-based line in the fragment the author edits. */
  fragmentLine?: number;
  fragmentPath?: string;
  blocking: boolean;
  /**
   * The layer above this step's that the finding is anchored in. Such a
   * finding is reported and never blocks: the step cannot edit that layer, so
   * a repair round spent on it is money for nothing. Measured: two of three
   * repair rounds at S21 went on `validation/requirement-subject` naming
   * `OA::OperationalBudgets`, which Sysprose began flagging after the layer
   * was written and which the SA author could not touch.
   */
  inherited?: Layer;
  /** Which check produced it. */
  check?: string;
}

export type Knobs = Record<KnobId, boolean>;

export interface Classification {
  blocking: boolean;
  /** Why — one short reason, for the packet. */
  reason: string;
}

export function classifyCode(code: string, severity: Severity, step: StepSpec, knobs: Knobs): Classification {
  const knob = KNOB_CONDITIONAL[code];
  if (knob) {
    return knobs[knob]
      ? { blocking: true, reason: `${code} blocks while the ${knob} knob is on` }
      : { blocking: false, reason: `${code} is reported: the ${knob} knob is off` };
  }
  if (step.failCodes.includes(code)) {
    return { blocking: true, reason: `${code} is a declared failure of ${step.id}` };
  }
  if (REPORTED_ONLY.has(code)) {
    return { blocking: false, reason: `${code} is a verdict on a target, reported: a missed target is a result, not a defect` };
  }
  const family = familyOf(code);
  // Two warnings that are findings about the fragment, not about the world.
  // Sysprose reports an unresolved reference as a warning, so the family rule
  // let a model ship naming things that are not there — v9 went out with seven
  // traces to `PA::GroundStation` and four allocations to SA actors LA cannot
  // see. And a VIOLATED constraint (a warning; one that could not be evaluated
  // is an info, and reports) is the layer's own numbers contradicting each
  // other — v9's LA asserted 0.78 == an expression of its own values that
  // gives 0.80. Both block; one anchored in a layer above is still only
  // reported (`inherit`).
  if (severity !== 'info' && (family === 'ref' || code === 'validation/constraint-violation')) {
    return { blocking: true, reason: `${code}: the fragment contradicts itself or names what is not there` };
  }
  if ((BLOCKING_FAMILIES as readonly string[]).includes(family)) {
    return severity === 'error'
      ? { blocking: true, reason: `${family} error` }
      : { blocking: false, reason: `${family} ${severity}` };
  }
  return { blocking: false, reason: `${family || 'uncoded'} finding, reported` };
}

/** A diagnostic as the checker's own item, with the rule that answers it attached. */
export function itemFromDiagnostic(
  d: {
    code?: string;
    severity: string;
    message: string;
    hint?: string;
    elementName?: string;
    range?: { start: { line: number } };
  },
  step: StepSpec,
  knobs: Knobs,
  check: string,
  /** Measures whose target is not the customer's (placeholder, or set by SEED). */
  provisional: ReadonlySet<string> = new Set(),
): RepairItem {
  const code = d.code ?? 'uncoded';
  const severity = (d.severity as Severity) ?? 'error';
  const { blocking } = classifyCode(code, severity, step, knobs);
  // A miss on a target nobody has asked for yet reads as what it is. An info
  // is a target met (or undecided), and needs no such words.
  const placeholder = code === TARGET_VERDICT && severity !== 'info' && namesMeasure(d, provisional);
  const note = placeholder ? PLACEHOLDER_MISS_NOTE : noteFor(code);
  return {
    source: 'diagnostic',
    code,
    severity,
    message: placeholder ? `${d.message} — missed a placeholder, not the customer's number` : d.message,
    hint: note?.note ?? d.hint,
    cv: note?.cv,
    qualifiedName: d.elementName,
    prefixLine: d.range?.start.line,
    blocking,
    check,
  };
}

/**
 * Whether a diagnostic is about one of `measures`: the element it is anchored
 * at, or a measure named as a word in its message. Sysprose anchors a target
 * verdict at the layer's estimate (`Root::LA::<measure>`) and names the Common
 * target in the message; either is enough.
 */
function namesMeasure(d: { message: string; elementName?: string }, measures: ReadonlySet<string>): boolean {
  if (measures.size === 0) return false;
  const anchored = d.elementName?.split('::').pop();
  if (anchored && measures.has(anchored)) return true;
  return [...measures].some((m) => new RegExp(`\\b${m}\\b`).test(d.message));
}
