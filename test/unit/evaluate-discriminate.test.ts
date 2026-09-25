/**
 * A trade-off has to learn something from the measures it scores.
 *
 * In v7's PA trade-off, four of fourteen measures gave both alternatives the
 * same number, so a third of the comparison turned on nothing. The measure the
 * decision actually rested on did separate them, 0.55 against 0.91 — this check
 * is about the dead weight beside it, not about accusing the decisive one.
 */
import { describe, expect, it } from 'vitest';
import { measuresThatDoNotDiscriminate } from '../../src/agents/evaluate.ts';

const alt = (moes: Array<{ name: string; value?: number; outcome?: string }>) => ({
  k: 1, elements: 0, blocking: 0, repairIterations: 0, warnings: 0,
  moes: moes.map((m) => ({
    name: m.name, outcome: m.outcome ?? 'decided', value: m.value,
    sense: 'max' as const, target: 0.9, unit: '',
  })),
}) as never;

describe('measures that score both alternatives the same', () => {
  it('names a measure that gave both alternatives the same number', () => {
    const found = measuresThatDoNotDiscriminate([
      alt([{ name: 'groundLinkLossAreaUnderWatchShare', value: 0.9 },
           { name: 'areaUnderWatchShare', value: 0.9 }]),
      alt([{ name: 'groundLinkLossAreaUnderWatchShare', value: 0.9 },
           { name: 'areaUnderWatchShare', value: 0.92 }]),
    ]);
    expect(found.map((f) => f.name)).toEqual(['groundLinkLossAreaUnderWatchShare']);
  });

  it('says nothing when every measure separates them', () => {
    expect(measuresThatDoNotDiscriminate([
      alt([{ name: 'a', value: 0.5 }]),
      alt([{ name: 'a', value: 0.7 }]),
    ])).toEqual([]);
  });

  it('counts two undecided estimates as failing to discriminate', () => {
    // Neither alternative said anything the solver could bound. The comparison
    // is no better informed for having scored it.
    const found = measuresThatDoNotDiscriminate([
      alt([{ name: 'a', outcome: 'undecided' }]),
      alt([{ name: 'a', outcome: 'undecided' }]),
    ]);
    expect(found.map((f) => f.name)).toEqual(['a']);
  });

  it('does not compare a measure one alternative never stated', () => {
    expect(measuresThatDoNotDiscriminate([
      alt([{ name: 'a', value: 0.5 }, { name: 'b', value: 0.5 }]),
      alt([{ name: 'a', value: 0.5 }]),
    ]).map((f) => f.name)).toEqual(['a']);
  });

  it('has nothing to say about a single alternative', () => {
    expect(measuresThatDoNotDiscriminate([alt([{ name: 'a', value: 0.5 }])])).toEqual([]);
  });
});

describe('a decision made by elimination is not a trade-off', () => {
  // The run that prompted this scored a single survivor at both layers and
  // said nothing: the table read as a comparison, and what actually decided
  // each layer was whatever rejected the other architecture.
  it('says so, and names what was rejected', async () => {
    const { rationaleFor } = await import('../../src/agents/evaluate.ts');
    const text = rationaleFor(
      'PA', 1,
      [{ k: 1, elements: 0, blocking: 0, repairIterations: 0, warnings: 0, moes: [] }] as never,
      [{ k: 1, total: 0.8, moe: 1, rubric: 0.5, structure: 0.8, resilience: 0.2 }],
      { recommended: 1, rationale: 'x', scores: [] } as never,
      { per: 0.05, cap: 0.25 },
      [{ k: 1, status: 'done' }, { k: 2, status: 'blocked' }],
    );
    expect(text).toContain('This was not a comparison');
    expect(text).toContain('1 of 2 alternative(s) were viable');
    expect(text).toContain('alternative 2 (blocked)');
    expect(text).toContain('not evidence that this architecture beat anything');
  });

  it('says nothing when two alternatives really were compared', async () => {
    const { rationaleFor } = await import('../../src/agents/evaluate.ts');
    const text = rationaleFor(
      'PA', 1,
      [{ k: 1, elements: 0, blocking: 0, repairIterations: 0, warnings: 0, moes: [] },
       { k: 2, elements: 0, blocking: 0, repairIterations: 0, warnings: 0, moes: [] }] as never,
      [{ k: 1, total: 0.8, moe: 1, rubric: 0.5, structure: 0.8, resilience: 0.2 },
       { k: 2, total: 0.7, moe: 1, rubric: 0.5, structure: 0.7, resilience: 0.2 }],
      { recommended: 1, rationale: 'x', scores: [] } as never,
      { per: 0.05, cap: 0.25 },
      [{ k: 1, status: 'done' }, { k: 2, status: 'done' }],
    );
    expect(text).not.toContain('This was not a comparison');
  });
});
