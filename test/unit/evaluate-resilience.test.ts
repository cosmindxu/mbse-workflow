/**
 * Resilience is weighted on its own, not diluted into the rubric mean.
 */
import { describe, expect, it } from 'vitest';
import { resilienceFor } from '../../src/agents/evaluate.ts';
import type { EvaluateOutput } from '../../src/llm/schemas.ts';

const rubric = (criteria: Array<[string, number]>): EvaluateOutput =>
  ({
    scores: [{ alternative: 1, criteria: criteria.map(([name, score]) => ({ name, score, reason: 'r' })) }],
    recommended: 1,
    rationale: 'r',
  }) as EvaluateOutput;

describe('resilienceFor', () => {
  it('averages only the two resilience criteria, normalised to 0..1', () => {
    const r = rubric([['cohesion', 1], ['groundLinkLossResilience', 5], ['groundNodeLossResilience', 3]]);
    expect(resilienceFor(r, 1)).toBeCloseTo(0.75);
  });

  it('is neutral when the criteria were not scored, so a run without a population ranks as before', () => {
    expect(resilienceFor(rubric([['cohesion', 5]]), 1)).toBe(0.5);
  });
});
