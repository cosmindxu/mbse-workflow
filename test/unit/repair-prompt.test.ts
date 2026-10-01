/**
 * A target's verdict is not something to repair: the repair prompt keeps it
 * out of the notes and out of their cap, and says why.
 */
import { describe, expect, it } from 'vitest';
import { repairPrompt } from '../../src/agents/author.ts';
import type { RepairItem } from '../../src/check/classify.ts';

const note = (i: number): RepairItem => ({ source: 'predicate', code: 'docs.coverage', severity: 'info', message: `note ${i}`, blocking: false });
const verdict = (measure: string): RepairItem => ({
  source: 'diagnostic',
  code: 'validation/target-by-specialisation',
  severity: 'warning',
  message: `${measure}Target: violated for LA (${measure} = 0.5)`,
  blocking: false,
});
const blocker: RepairItem = { source: 'diagnostic', code: 'ref/unresolved-reference', severity: 'error', message: 'nothing there', blocking: true };

describe('the repair prompt and target verdicts', () => {
  it('does not offer a missed target for repair, and says a miss is a result', () => {
    const prompt = repairPrompt('package LA { }', [blocker, verdict('coverage'), note(1)]);
    expect(prompt).not.toContain('coverageTarget: violated');
    expect(prompt).toContain('1 target verdict(s) were also reported');
    expect(prompt).toContain('A missed target is a result: do not change an estimate to meet it.');
    expect(prompt).toContain('note 1');
  });

  it('keeps the twenty-note cap for the notes, however many verdicts there are', () => {
    const items = [blocker, ...Array.from({ length: 12 }, (_, i) => verdict(`m${i}`)), ...Array.from({ length: 25 }, (_, i) => note(i))];
    const prompt = repairPrompt('package PA { }', items);
    const listed = prompt.split('\n').filter((l) => l.startsWith('- `docs.coverage`'));
    expect(listed).toHaveLength(20);
    expect(prompt).toContain('note 19');
    expect(prompt).not.toContain('note 20');
    expect(prompt).toContain('12 target verdict(s)');
  });

  it('says nothing about verdicts when there are none', () => {
    expect(repairPrompt('package LA { }', [blocker, note(1)])).not.toContain('target verdict');
  });
});
