/**
 * The bonus lane checks each state machine: a machine that cycles gets "back to
 * where it opened" when it states nothing; a lifecycle gets nothing.
 */
import { describe, expect, it } from 'vitest';
import { initialStateOf, returnsTo } from '../../src/check/checker.ts';
import { behaviourMarkdown } from '../../src/audit/final.ts';

const modes = `#Mode state def MemberMode {
    state Watching; state Recharging; state Grounded;
    initial start;
    transition start -> Watching;
    transition Watching -> Recharging;
    transition Recharging -> Watching;
    transition Watching -> Grounded;
}`;
const lifecycle = `#State state def DeliveryState {
    state Delivered; state Accepted; state InService;
    initial start;
    transition start -> Delivered;
    transition Delivered -> Accepted;
    transition Accepted -> InService;
}`;

describe('the behaviour sweep', () => {
  it('finds the state a machine opens at', () => {
    expect(initialStateOf(modes, 'MemberMode')).toBe('Watching');
    expect(initialStateOf('state def Plain { state Idle; state Busy; }', 'Plain')).toBe('Idle');
  });

  it('tells a machine that comes back from a lifecycle, whatever its tag', () => {
    expect(returnsTo(modes, 'MemberMode', 'Watching')).toBe(true);
    expect(returnsTo(lifecycle, 'DeliveryState', 'Delivered')).toBe(false);
  });

  it('renders refuted and unchecked machines as such', () => {
    const md = behaviourMarkdown({
      behaviour: {
        machines: [
          { machine: 'S::PA::MemberMode', property: 'recovery to Watching', exitCode: 1, detail: 'not recoverable: Grounded' },
          { machine: 'S::EPBS::DeliveryState', property: 'none', exitCode: 2 },
        ],
        skipped: 0,
      },
      faultTree: { exitCode: 2, withCutSets: 0, singlePointsOfFailure: 0, contracts: 0 },
    }).join('\n');
    expect(md).toContain('| `PA::MemberMode` | recovery to Watching | **refuted** | not recoverable: Grounded |');
    expect(md).toContain('| `EPBS::DeliveryState` | none | nothing to check |');
    expect(md).toContain('Fault tree over the contracts: 0 contract(s)');
  });
});

describe('a fault tree with nothing to cut', () => {
  it('reads as not applicable, never as an all-clear', async () => {
    const { bonusLane } = await import('../../src/audit/final.ts');
    const { mkdtempSync, writeFileSync } = await import('node:fs');
    const { tmpdir } = await import('node:os');
    const { join } = await import('node:path');
    const dir = mkdtempSync(join(tmpdir(), 'lane-'));
    writeFileSync(join(dir, 'fault-tree.json'), JSON.stringify({ exitCode: 2, groups: [], withCutSets: 0, singlePointsOfFailure: 0 }));
    const lane = bonusLane(dir);
    expect(lane.faultTree?.applicable).toBe(false);
    const md = behaviourMarkdown(lane).join('\n');
    expect(md).toContain('Fault tree: not applicable');
    expect(md).not.toContain('0 single point');
  });
});

