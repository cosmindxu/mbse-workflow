/**
 * A measure whose estimate moved between the layer above and this one is
 * reported with both values and both bases — never blocking, never exempt.
 */
import { describe, expect, it } from 'vitest';
import { CARRIED_TOLERANCE, PREDICATES, differingInputs, type CarriedEstimates, type EstimateSide, type PredicateInput } from '../../src/check/predicates.ts';
import { definingExpression, expressionNames } from '../../src/spec/measures.ts';
import { step as stepById } from '../../src/spec/steps.ts';
import type { TagIndex } from '../../src/sysprose/backend.ts';

const ROOT = 'Swarm';
const noTags: TagIndex = { byElement: new Map(), byKeyword: new Map(), has: () => false, taggedWith: () => [] };
const input = (measures: CarriedEstimates['measures']): PredicateInput => ({
  step: stepById('S41'),
  layer: 'PA',
  root: ROOT,
  knobs: { modes_states: true, interfaces: true, variability: true, safety: false, views: false, verification: true, requirements_intake: false, infrastructure_intake: false },
  brief: { systemName: ROOT, aliases: [], moes: Object.keys(measures), capabilities: [] },
  payloads: { elements: [], carried: { above: 'LA', measures } satisfies CarriedEstimates },
  tags: noTags,
  // The elements check blocks; this finding must not, whatever its check does.
  blocking: true,
  alternative: 1,
});
const run = (measures: CarriedEstimates['measures']) => PREDICATES['moe.carriedEstimate'](input(measures));

const stated = (value: number, basis: string): EstimateSide => ({ value, derived: false, basis });
const derived = (value: number, basis: string, inputs: Record<string, number | undefined>): EstimateSide => ({ value, derived: true, basis, inputs });

describe('moe.carriedEstimate', () => {
  it('says nothing when the layers agree, or differ only by rounding', () => {
    expect(run({ coverage: { above: stated(0.78, 'a'), here: stated(0.78, 'b') } })).toEqual([]);
    // v9's LA wrote 0.5866 as 0.58: 1.1% is rounding, not design.
    expect(run({ jam: { above: stated(0.58, 'a'), here: stated(0.5866, 'b') } })).toEqual([]);
    expect(CARRIED_TOLERANCE).toBe(0.02);
  });

  it('reports two literals that differ with both values and both bases, as a warning that never blocks', () => {
    // v9: LA 0.58, PA 0.68 on a second confirming neighbour no PA element models.
    const items = run({
      coverageUnderMeshJammingFraction: {
        above: stated(0.58, 'half of the hand-overs fail'),
        here: stated(0.68, 'confirmation fails on both of the two nearest neighbours'),
      },
    });
    expect(items).toHaveLength(1);
    const [x] = items;
    expect(x.code).toBe('moe.carriedEstimate');
    expect(x.severity).toBe('warning');
    expect(x.blocking).toBe(false);
    expect(x.qualifiedName).toBe('Swarm::PA::coverageUnderMeshJammingFraction');
    expect(x.message).toContain('0.68 at PA (stated)');
    expect(x.message).toContain('0.58 at LA (stated)');
    expect(x.message).toContain("LA's basis: «half of the hand-overs fail»");
    expect(x.message).toContain("PA's basis: «confirmation fails on both of the two nearest neighbours»");
    // Neutral: the layer above may be the one that is wrong.
    expect(x.message).toContain("whether LA's estimate was wrong, or which element modelled at PA changes it");
  });

  it('flags a difference in either direction — the layer above can be the wrong one', () => {
    // v9's LA rounded 40/60 h up to 0.7; PA's 0.66 is the right one, and it is still reported.
    expect(run({ hours: { above: stated(0.7, 'a'), here: stated(0.66, 'b') } })).toHaveLength(1);
  });

  it('does not exempt two derived estimates: it names the input that moved', () => {
    const items = run({
      coverageUnderMeshJammingFraction: {
        above: derived(0.58662, 'correlated', { areaUnderWatchFraction: 0.78216, handOverLossFraction: 0.5, sectorGapShareOfLostHandOver: 0.5 }),
        here: derived(0.68439, 'independent', { areaUnderWatchFraction: 0.78216, handOverLossFraction: 0.25, sectorGapShareOfLostHandOver: 0.5 }),
      },
    });
    expect(items).toHaveLength(1);
    expect(items[0].message).toContain('Both are derived; the inputs that differ: `handOverLossFraction` 0.5 at LA, 0.25 at PA.');
    expect(items[0].message).not.toContain('`areaUnderWatchFraction` 0.78216 at LA');
    expect(items[0].blocking).toBe(false);
  });

  it('claims the same inputs only of inputs it compared', () => {
    const same = run({ m: { above: derived(0.5, '', { a: 1 }), here: derived(0.7, '', { a: 1 }) } });
    expect(same[0].message).toContain('Both are derived; every input the two equations read has the same value: the equations differ.');
    // An equation it could not read (`assert constraint { (m == a * b) }`) is
    // not one whose inputs are the same.
    const unread = run({ m: { above: { value: 0.5, derived: true }, here: derived(0.7, '', { a: 2 }) } });
    expect(unread[0].message).toContain('Both are derived; the equation at LA could not be read; PA derives it from `a` 2; which input moved is not known.');
    expect(unread[0].message).not.toContain('same value');
    const neither = run({ m: { above: { value: 0.5, derived: true }, here: { value: 0.7, derived: true } } });
    expect(neither[0].message).toContain('the equation at LA could not be read; the equation at PA could not be read; which input moved is not known.');
    // `fleet.size * 0.1` reads as `fleet`, which has no value at either layer.
    const chain = run({ m: { above: derived(0.5, '', { fleet: undefined }), here: derived(0.7, '', { fleet: undefined }) } });
    expect(chain[0].message).toContain('Both are derived; `fleet` has no value to compare at either layer.');
    expect(chain[0].message).not.toContain('same value');
    // Against a literal, a derived side whose equation was not read says so.
    const literal = run({ m: { above: stated(0.5, 'a'), here: { value: 0.7, derived: true } } });
    expect(literal[0].message).toContain('The equation at PA could not be read.');
  });

  it('names an input read on one side only, and a derived side against a literal one', () => {
    const one = differingInputs(derived(1, '', { a: 1, b: 2 }), derived(2, '', { a: 1, c: 3 }));
    expect(one.map((x) => x.name)).toEqual(['b', 'c']);
    expect(one[0]).toMatchObject({ readAbove: true, readHere: false });
    const items = run({ alerts: { above: stated(24, 'after merging'), here: derived(20, 'the cap', { alertCapPerHour: 20 }) } });
    expect(items[0].message).toContain('PA derives it from `alertCapPerHour` 20.');
  });

  it('compares nothing it has no value for, and is silent without the payload', () => {
    expect(run({ m: { above: stated(1, 'a') } })).toEqual([]);
    expect(run({ m: { above: { derived: false }, here: stated(1, 'b') } })).toEqual([]);
    const bare = input({});
    delete bare.payloads.carried;
    expect(PREDICATES['moe.carriedEstimate'](bare)).toEqual([]);
  });

  it('runs at the physical alternatives, beside moe.estimated', () => {
    const elements = stepById('S41').checks.find((c) => c.name === 'elements');
    expect(elements?.predicates).toContain('moe.carriedEstimate');
  });
});

describe('reading the defining equation', () => {
  const layer = [
    '        attribute jammedLinkFraction = 0.5;',
    '        assert constraint { areaUnderWatchFraction == fleetMemberCount * 0.06 }',
    '        assert constraint named { doc /* the jammed == worst case */ coverageUnderMeshJammingFraction == areaUnderWatchFraction * (1 - jammedLinkFraction * sectorGapShareOfLostHandOver) }',
    '        assert constraint { 2.5e-1 * alertCapPerHour == alertsReachingOperatorPerHour }',
  ].join('\n');

  it('finds the expression a measure is fixed to, on either side, ignoring docs', () => {
    expect(definingExpression(layer, 'coverageUnderMeshJammingFraction')).toBe('areaUnderWatchFraction * (1 - jammedLinkFraction * sectorGapShareOfLostHandOver)');
    expect(definingExpression(layer, 'alertsReachingOperatorPerHour')).toBe('2.5e-1 * alertCapPerHour');
    expect(definingExpression(layer, 'jammedLinkFraction')).toBeUndefined();
  });

  it('lists the names an expression reads, not its numbers', () => {
    expect(expressionNames('areaUnderWatchFraction * (1 - jammedLinkFraction * sectorGapShareOfLostHandOver)')).toEqual([
      'areaUnderWatchFraction',
      'jammedLinkFraction',
      'sectorGapShareOfLostHandOver',
    ]);
    expect(expressionNames('2.5e-1 * alertCapPerHour')).toEqual(['alertCapPerHour']);
  });
});
