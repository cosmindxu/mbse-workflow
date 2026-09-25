/**
 * A rejected gate's comment reaches the step that runs again — including the
 * two steps that rewrite the file it used to be written into.
 */
import { describe, expect, it } from 'vitest';
import { emptyState } from '../../src/orch/state.ts';
import { reviewerSection } from '../../src/agents/seed.ts';

describe('gate comments in the run state', () => {
  it('are kept per step, and accumulate over rejections', () => {
    const state = emptyState({ root: 'X', mode: 'gated', knobs: {}, sysprose: { dir: '', commit: 'a', expected: 'a', matches: true } });
    expect(state.gateComments).toBeUndefined();
    state.gateComments = { ...state.gateComments, S33: [...(state.gateComments?.S33 ?? []), 'split the coordination component'] };
    state.gateComments = { ...state.gateComments, S33: [...(state.gateComments?.S33 ?? []), 'and say what the ground node costs'] };
    expect(state.gateComments.S33).toEqual(['split the coordination component', 'and say what the ground node costs']);
  });
});

describe('the steps that rewrite their own layer', () => {
  it("put the reviewer's words in SEED's prompt, where the fragment could not carry them", () => {
    expect(reviewerSection([])).toEqual([]);
    const section = reviewerSection(['state the fleet size in the brief']).join('\n');
    expect(section).toContain('rejected');
    expect(section).toContain('state the fleet size in the brief');
    expect(section).toContain('say in the rationale what you changed');
  });
});
