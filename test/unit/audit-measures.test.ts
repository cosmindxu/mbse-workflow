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
