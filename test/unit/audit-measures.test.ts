/**
 * A target every compared alternative misses is flagged for the person who set it.
 */
import { describe, expect, it } from 'vitest';
import { measuresMarkdown, unreachableTarget } from '../../src/audit/final.ts';

const drop = { name: 'singleLossCoverageDrop', sense: 'min' as const, target: 0.1 };

describe('unreachable targets', () => {
  it('flags a target missed by every alternative at every layer', () => {
    // v5: 0.15 and 0.21 at LA, 0.09 would have met it.
    expect(unreachableTarget(drop, [{ outcome: 'optimum', value: 0.15 }, { outcome: 'optimum', value: 0.21 }])).toBe('2/2');
    expect(unreachableTarget(drop, [{ outcome: 'optimum', value: 0.15 }, { outcome: 'optimum', value: 0.09 }])).toBeUndefined();
  });

  it('does not flag what it could not decide, or what was never compared', () => {
    expect(unreachableTarget(drop, [{ outcome: 'optimum', value: 0.15 }, { outcome: 'inconclusive' }])).toBeUndefined();
    expect(unreachableTarget(drop, [])).toBeUndefined();
  });

  it('lists flagged measures under their own heading', () => {
    const md = measuresMarkdown([
      { name: 'singleLossCoverageDrop', target: '≤ 0.1', layers: [{ layer: 'LA', estimate: '0.21', met: false }], unreachable: '4/4' },
      { name: 'fleetSize', target: '≤ 12', layers: [{ layer: 'LA', estimate: '12', met: true }] },
    ]).join('\n');
    expect(md).toContain('### No architecture compared meets these');
    expect(md).toContain('`singleLossCoverageDrop` ≤ 0.1: missed by 4/4 alternatives');
    expect(md).not.toContain('`fleetSize` ≤ 12: missed');
  });
});

describe('targets nobody misses, and placeholder targets', () => {
  const alerts = { name: 'operatorAlertsPerHour', sense: 'min' as const, target: 20 };
  it('flags a target every alternative met, and not one that some missed or left undecided', async () => {
    const { metByEveryAlternative } = await import('../../src/audit/final.ts');
    expect(metByEveryAlternative(alerts, [{ outcome: 'optimum', value: 17 }, { outcome: 'optimum', value: 15 }])).toBe('2/2');
    expect(metByEveryAlternative(alerts, [{ outcome: 'optimum', value: 17 }, { outcome: 'optimum', value: 25 }])).toBeUndefined();
    expect(metByEveryAlternative(alerts, [{ outcome: 'optimum', value: 17 }, { outcome: 'inconclusive', value: null }])).toBeUndefined();
  });
  it('says a met placeholder is only that, and that measures met by all decided nothing', () => {
    const md = measuresMarkdown([
      { name: 'operatorAlertsPerHour', target: '≤ 20 1/h', layers: [{ layer: 'PA', estimate: '16 1/h', met: true }], metByAll: '2/2', placeholder: true },
    ]).join('\n');
    expect(md).toContain('≤ 20 1/h (placeholder)');
    expect(md).toContain('### Every architecture compared meets these');
    expect(md).toContain('the measures decided nothing');
    expect(md).toContain('1 of these 1 targets are placeholders');
  });
});

describe('a miss on a target that is not the customer\'s', () => {
  it('reads "missed a placeholder", not a plain failure, and a customer target still reads ✗', () => {
    const md = measuresMarkdown([
      { name: 'coverageUnderMeshJammingFraction', target: '≥ 0.75', layers: [{ layer: 'LA', estimate: '0.58', met: false }, { layer: 'PA', estimate: '0.58', met: false }], placeholder: true },
      // The brief gave no number; SEED set 12 h, and its own doc says no
      // architecture should be failed on it.
      { name: 'unattendedWatchDurationHours', target: '≥ 12 h', layers: [{ layer: 'LA', estimate: '0.66 h', met: false }], setBySeed: true },
      { name: 'areaUnderWatchFraction', target: '≥ 0.9', layers: [{ layer: 'LA', estimate: '0.78216 (derived)', met: false }] },
    ]).join('\n');
    expect(md).toContain('| `coverageUnderMeshJammingFraction` | ≥ 0.75 (placeholder) | 0.58 — missed a placeholder | 0.58 — missed a placeholder |');
    expect(md).toContain('| `unattendedWatchDurationHours` | ≥ 12 h (set by SEED) | 0.66 h — missed a placeholder | — |');
    expect(md).toContain('| `areaUnderWatchFraction` | ≥ 0.9 | 0.78216 (derived) ✗ | — |');
    expect(md).toContain('a miss is a number to take to the customer, not a failure of the design');
    expect(md).toContain('`unattendedWatchDurationHours`: the brief gave no number, and SEED set the target');
    // Presentation only: the S33/S42 score still counts the miss, so the audit
    // does not say no architecture was failed on it.
    expect(md).toContain('Read a miss against it as a placeholder miss, a number to take to the customer.');
    expect(md).not.toContain('no architecture is failed');
  });

  it('marks a placeholder in the list of targets nobody met', () => {
    const md = measuresMarkdown([
      { name: 'missedDetectionFraction', target: '≤ 0.1', layers: [{ layer: 'LA', estimate: '0.12', met: false }], unreachable: '4/4', placeholder: true },
    ]).join('\n');
    expect(md).toContain('- `missedDetectionFraction` ≤ 0.1 (placeholder): missed by 4/4 alternatives');
  });
});
