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
 *   3. the family: text that did not lex, parse, map, resolve or validate is a
 *      finding about the fragment; verification outcomes are not,
 *   4. severity: warnings and infos report.
 */
import { BLOCKING_FAMILIES, KNOB_CONDITIONAL, familyOf, noteFor } from '../spec/codes.ts';
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
  const family = familyOf(code);
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
): RepairItem {
  const code = d.code ?? 'uncoded';
  const severity = (d.severity as Severity) ?? 'error';
  const { blocking } = classifyCode(code, severity, step, knobs);
  const note = noteFor(code);
  return {
    source: 'diagnostic',
    code,
    severity,
    message: d.message,
    hint: note?.note ?? d.hint,
    cv: note?.cv,
    qualifiedName: d.elementName,
    prefixLine: d.range?.start.line,
    blocking,
    check,
  };
}
