/**
 * A resumed run adds its legs up instead of overwriting the one before.
 */
import { describe, expect, it } from 'vitest';
import { unrecordedSpend } from '../../src/audit/contribution.ts';
import { emptyState, openLeg, recordSpend } from '../../src/orch/state.ts';

const fresh = () => emptyState({ root: 'S', mode: 'autonomous', knobs: {}, sysprose: { dir: '', commit: '', expected: '', matches: true } });

describe('legs', () => {
  it('totals every leg into llm, killed calls included', () => {
    const state = fresh();
    const first = openLeg(state, 't1');
    recordSpend(state, first, { calls: 5, costUsd: 9.93, durationMs: 1000, killed: 0 });
    const second = openLeg(state, 't2');
    recordSpend(state, second, { calls: 8, costUsd: 20.57, durationMs: 2000, killed: 2 });
    expect(state.legs).toHaveLength(2);
    expect(state.llm.calls).toBe(13);
    expect(state.llm.costUsd).toBeCloseTo(30.5);
    expect(state.llm.killed).toBe(2);
  });

  it('keeps what a state from before legs recorded as its first leg', () => {
    const state = fresh();
    state.llm = { calls: 8, costUsd: 23.33, durationMs: 4843000 };
    const leg = openLeg(state, 'now');
    recordSpend(state, leg, { calls: 1, costUsd: 1, durationMs: 1 });
    expect(state.legs!.map((l) => l.costUsd)).toEqual([23.33, 1]);
    expect(state.llm.costUsd).toBeCloseTo(24.33);
  });

  it('a leg that spends nothing leaves the total alone', () => {
    const state = fresh();
    recordSpend(state, openLeg(state), { calls: 0, costUsd: 0, durationMs: 0 });
    expect(state.llm).toMatchObject({ calls: 0, costUsd: 0 });
  });
});

describe('unrecordedSpend', () => {
  it('says what the call log holds beyond the legs, and nothing when they agree', () => {
    const calls = [{ tag: 'a', ok: true, costUsd: 2 }, { tag: 'b', ok: true, costUsd: 3 }];
    expect(unrecordedSpend({ calls: 2, costUsd: 5 }, calls)).toBeUndefined();
    expect(unrecordedSpend({ calls: 1, costUsd: 2 }, calls)).toContain('5.00 USD — 3.00 USD more');
  });
});
