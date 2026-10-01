/**
 * What blocks, and in which order the rules decide it.
 */
import { describe, expect, it } from 'vitest';
import { classifyCode, itemFromDiagnostic, type Knobs } from '../../src/check/classify.ts';
import { step as stepById } from '../../src/spec/steps.ts';

const knobs = (over: Partial<Knobs> = {}): Knobs => ({
  modes_states: true,
  interfaces: true,
  variability: true,
  safety: true,
  views: false,
  verification: true,
  requirements_intake: false,
  infrastructure_intake: false,
  ...over,
});

const S10 = stepById('S10');
const S41 = stepById('S41');

describe('classification', () => {
  it('blocks text that did not parse, resolve or validate', () => {
    for (const code of ['parse/mismatched-token', 'ref/unresolved-reference', 'validation/duplicate-name', 'lexer/illegal-char']) {
      expect(classifyCode(code, 'error', S10, knobs()).blocking, code).toBe(true);
    }
  });

  it('reports verification outcomes rather than blocking on them', () => {
    expect(classifyCode('verification/nondeterministic-choice', 'warning', S10, knobs()).blocking).toBe(false);
    expect(classifyCode('verification/refinement-undecided', 'warning', S10, knobs()).blocking).toBe(false);
  });

  it('lets a knob decide the codes the design ties to one', () => {
    expect(classifyCode('verification/unreachable-state', 'warning', S10, knobs()).blocking).toBe(true);
    expect(classifyCode('verification/unreachable-state', 'warning', S10, knobs({ modes_states: false })).blocking).toBe(false);
    expect(classifyCode('validation/dangling-endpoint', 'warning', S10, knobs({ interfaces: false })).blocking).toBe(false);
  });

  it('gives the knob rule precedence over the family rule', () => {
    // `validation/*` would block on its family; the interfaces knob is off, so
    // the conditional entry wins and it is reported.
    const off = classifyCode('validation/dangling-endpoint', 'error', S10, knobs({ interfaces: false }));
    expect(off.blocking).toBe(false);
    expect(off.reason).toContain('interfaces');
  });

  it('blocks an unresolved reference and a violated constraint even at warning severity', () => {
    for (const code of ['ref/unresolved-requirement', 'ref/unresolved-allocation-end', 'ref/unresolved-specialization']) {
      expect(classifyCode(code, 'warning', S10, knobs()).blocking, code).toBe(true);
    }
    expect(classifyCode('validation/constraint-violation', 'warning', S10, knobs()).blocking).toBe(true);
    // A constraint that could not be evaluated is an info: a target on a
    // measure with no value yet, reported.
    expect(classifyCode('validation/constraint-violation', 'info', S10, knobs()).blocking).toBe(false);
  });

  it('does not block on a warning from a blocking family', () => {
    expect(classifyCode('validation/rules', 'warning', S10, knobs()).blocking).toBe(false);
  });

  it('attaches the convention that answers the code', () => {
    const item = itemFromDiagnostic(
      {
        code: 'ref/unresolved-flow-end',
        severity: 'error',
        message: "Unresolved flow end 'a.b'",
        elementName: 'X::OA::flow1',
        range: { start: { line: 12 } },
      },
      S10,
      knobs(),
      'check',
    );
    expect(item.blocking).toBe(true);
    expect(item.cv).toBe('CV-05');
    expect(item.hint).toContain('flow');
    expect(item.prefixLine).toBe(12);
    expect(item.qualifiedName).toBe('X::OA::flow1');
  });

  it('keeps an uncoded finding rather than dropping it', () => {
    const item = itemFromDiagnostic({ severity: 'error', message: 'something' }, S10, knobs(), 'check');
    expect(item.code).toBe('uncoded');
    expect(item.blocking).toBe(false);
  });
  it('reports a target verdict and never blocks on it, while a violated constraint still blocks', () => {
    // A missed target is a result of the comparison, not the fragment
    // contradicting itself. A validation warning already reports; the code is
    // pinned so that an error from Sysprose would report too.
    for (const severity of ['info', 'warning', 'error'] as const) {
      const c = classifyCode('validation/target-by-specialisation', severity, S41, knobs());
      expect(c.blocking, severity).toBe(false);
    }
    expect(classifyCode('validation/target-by-specialisation', 'warning', S41, knobs()).reason).toContain('a result, not a defect');
    expect(classifyCode('validation/constraint-violation', 'warning', S41, knobs()).blocking).toBe(true);
  });

  it('notes that a target verdict is a result, and a miss on a placeholder reads as one', () => {
    const verdict = (elementName: string, severity = 'warning') =>
      itemFromDiagnostic(
        { code: 'validation/target-by-specialisation', severity, message: `areaUnderWatchTarget: violated for LA (${elementName.split('::').pop()} = 0.5)`, elementName },
        S41,
        knobs(),
        'check',
        new Set(['coverageUnderMeshJammingFraction', 'unattendedWatchDurationHours']),
      );
    const customer = verdict('Swarm::LA::areaUnderWatchFraction');
    expect(customer.blocking).toBe(false);
    expect(customer.hint).toContain('a result of the comparison, not a defect');
    expect(customer.hint).toContain('Do not change an estimate to meet it');
    expect(customer.message).not.toContain('placeholder');

    const placeholder = verdict('Swarm::PA::coverageUnderMeshJammingFraction');
    expect(placeholder.message).toContain('missed a placeholder');
    expect(placeholder.hint).toContain("not the customer's number yet");
    // A target SEED set where the brief gave none is read the same way.
    expect(verdict('Swarm::PA::unattendedWatchDurationHours').message).toContain('missed a placeholder');
    // An info is a target met or undecided: nothing was missed.
    expect(verdict('Swarm::PA::coverageUnderMeshJammingFraction', 'info').message).not.toContain('missed');
  });
});
