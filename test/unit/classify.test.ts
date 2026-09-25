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
});
