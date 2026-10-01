/**
 * Measures: a target renders as the bound it sets, the solver is asked for the
 * worst case, and the score counts what was decided.
 */
import { describe, expect, it } from 'vitest';
import { boundText, hasTarget, isDecided, isProvisional, meets, unscoredBecause, worstCaseSense } from '../../src/spec/measures.ts';
import { moeScore } from '../../src/agents/evaluate.ts';

const coverage = { sense: 'max' as const, target: 0.95, unit: '' };
const latency = { sense: 'min' as const, target: 10, unit: 's' };

describe('measures', () => {
  it('renders a target as its bound, never the bare sense word', () => {
    expect(boundText(coverage)).toBe('≥ 0.95');
    expect(boundText(latency)).toBe('≤ 10 s');
  });

  it('renders a test condition as the value it is held to, whatever its sense', () => {
    // v9's "half the links jammed" was a budget with sense max, written `>= 0.5`:
    // at least half, whose mildest case is the one the estimates were taken at.
    expect(boundText({ sense: 'max', target: 0.5, condition: true })).toBe('= 0.5');
    expect(boundText({ sense: 'max', target: 10, unit: 'min', condition: true })).toBe('= 10 min');
  });

  it('renders a measure the brief gives no number as having no target, never `≥ undefined`', () => {
    // v9's unattended watch: the brief asks for it and states no number.
    expect(boundText({ sense: 'max', unit: 'h' })).toBe('no target');
    expect(boundText({ sense: 'max', target: null, unit: 'h' })).toBe('no target');
    expect(hasTarget({})).toBe(false);
    expect(hasTarget({ target: null })).toBe(false);
    expect(hasTarget({ target: 0 })).toBe(true);
  });

  it('has nothing to meet or miss without a target, however decided the estimate', () => {
    expect(meets({ sense: 'max' }, 'optimum', 0.7)).toBeUndefined();
    expect(meets({ sense: 'max', target: null }, 'derived', 0.7)).toBeUndefined();
  });

  it('leaves out of the score a measure with no target and a target SEED set, and keeps a placeholder', () => {
    expect(unscoredBecause({})).toBe('no target');
    expect(unscoredBecause({ target: 12, setBySeed: true })).toBe('set by SEED');
    expect(unscoredBecause({ target: 0.75 })).toBeUndefined();
    // A placeholder still counts: the customer asked for the measure and gave a number to work to.
    const placeholder = { target: 0.75, placeholder: true };
    expect(unscoredBecause(placeholder)).toBeUndefined();
  });

  it('reads a placeholder and a target SEED set as not the customer\'s', () => {
    expect(isProvisional({ placeholder: true })).toBe(true);
    expect(isProvisional({ setBySeed: true })).toBe(true);
    expect(isProvisional({ placeholder: false })).toBe(false);
  });

  it('asks for the worst case: the least coverage, the most latency', () => {
    expect(worstCaseSense('max')).toBe('min');
    expect(worstCaseSense('min')).toBe('max');
  });

  it('counts only outcomes that prove a value', () => {
    for (const o of ['optimum', 'supremum', 'infimum']) expect(isDecided(o)).toBe(true);
    for (const o of ['unbounded', 'bound-without-optimality', 'vacuous', 'inconclusive', undefined]) expect(isDecided(o)).toBe(false);
    expect(meets(coverage, 'optimum', 0.97)).toBe(true);
    expect(meets(coverage, 'optimum', 0.9)).toBe(false);
    expect(meets(latency, 'optimum', 12)).toBe(false);
    expect(meets(latency, 'inconclusive', 5)).toBeUndefined();
  });

  it('scores 1 per target met, 0 per miss, ½ per undecided measure', () => {
    const row = (met?: boolean) => ({ name: 'x', outcome: 'optimum', sense: 'max' as const, target: 1, unit: '', met });
    expect(moeScore({ moes: [] })).toBe(0.5);
    expect(moeScore({ moes: [row(true), row(false), row(undefined), row(true)] })).toBe(0.625);
    expect(moeScore({ moes: [row(true), row(true)] })).toBe(1);
  });

  it('counts a measure with no target and a target SEED set as neither 0 nor ½: not at all', () => {
    const row = (met?: boolean, unscored?: 'no target' | 'set by SEED') => ({ name: 'x', outcome: 'optimum', sense: 'max' as const, unit: '', met, unscored });
    // v9's 12 h, SEED's number, missed by every alternative: 0 on it pulled
    // each measures term down. Left out, the term is the mean of the rest.
    expect(moeScore({ moes: [row(true), row(false), row(false, 'set by SEED')] })).toBe(0.5);
    expect(moeScore({ moes: [row(true), row(true), row(undefined, 'no target')] })).toBe(1);
    expect(moeScore({ moes: [row(true), row(undefined, 'no target'), row(false, 'set by SEED')] })).toBe(1);
    // Nothing left to count: the same ½ as no measures, for every alternative.
    expect(moeScore({ moes: [row(undefined, 'no target')] })).toBe(0.5);
  });
});

describe('accepting a hazard', () => {
  it('costs structure score per hazard, up to the cap', async () => {
    const { acceptancePenalty } = await import('../../src/agents/evaluate.ts');
    const cost = { per: 0.05, cap: 0.25 };
    expect(acceptancePenalty(0, cost)).toBe(0);
    expect(acceptancePenalty(1, cost)).toBeCloseTo(0.05);
    expect(acceptancePenalty(4, cost)).toBeCloseTo(0.2);
    expect(acceptancePenalty(9, cost)).toBeCloseTo(0.25);
  });
});

describe('the worst case of a derived estimate', () => {
  it('is a point when both senses agree, whatever the optimality code', async () => {
    const { worstCase } = await import('../../src/spec/measures.ts');
    const nonlinear = { outcome: 'bound-without-optimality', value: 0.96 };
    expect(await worstCase(async () => nonlinear, 'max')).toMatchObject({ outcome: 'derived', value: 0.96 });
  });

  it('stays undecided when the two senses bound a range', async () => {
    const { worstCase } = await import('../../src/spec/measures.ts');
    const range = async (sense: 'min' | 'max') => ({ outcome: 'bound-without-optimality', value: sense === 'min' ? 0.9 : 0.96 });
    expect(await worstCase(range, 'max')).toMatchObject({ outcome: 'bound-without-optimality', value: 0.9 });
  });

  it('asks once when the literal already bounds to an optimum', async () => {
    const { worstCase } = await import('../../src/spec/measures.ts');
    const asked: string[] = [];
    await worstCase(async (sense) => (asked.push(sense), { outcome: 'optimum', value: 0.97 }), 'max');
    expect(asked).toEqual(['min']);
  });
});
