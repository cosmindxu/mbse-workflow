/**
 * The gate the v7 run would have failed.
 *
 * v7 estimated `areaUnderWatchShare = 0.92` as a bare literal. The brief fixed
 * twelve members, forty minutes of flight and sixty of recharge, so 4.8 members
 * are airborne at once and the share a fleet can hold *at any moment* is 0.40.
 * Nobody noticed until the model was flown, months of work later, and the
 * simulation measured 0.3915.
 *
 * This is that arithmetic, run at the gate where it costs nothing. The check is
 * narrow on purpose — a heuristic that blocks the wrong thing is worse than no
 * check — so these tests pin both what it catches and what it must leave alone.
 */
import { describe, expect, it } from 'vitest';
import { PREDICATES } from '../../src/check/predicates.ts';
import type { BriefFacts } from '../../src/check/predicates.ts';

const predicate = PREDICATES['moe.dutyCycleBound'];

const brief = (over: Partial<BriefFacts> = {}): BriefFacts => ({
  systemName: 'Swarm',
  aliases: [],
  moes: ['areaUnderWatchShare'],
  measures: [{
    name: 'areaUnderWatchShare',
    sense: 'max',
    target: 0.9,
    unit: '',
    doc: 'Share of the area under watch at any moment; the brief requires at least 0.9.',
  }],
  budgets: { fleetSize: 12, memberFlightEnduranceMinutes: 40, memberRechargeMinutes: 60 },
  capabilities: [],
  coordinationFunctions: [],
  c2Functions: [],
  ...over,
} as BriefFacts);

const input = (value: string, facts: BriefFacts = brief()) => ({
  root: 'Swarm',
  layer: 'PA' as const,
  blocking: true,
  tags: { byElement: new Map(), byKeyword: new Map(), has: () => false, taggedWith: () => [] },
  payloads: {
    elements: [{
      id: '1', qualifiedName: 'Swarm::PA::areaUnderWatchShare', name: 'areaUnderWatchShare',
      metaclass: 'AttributeUsage', type: '', multiplicity: '', value, redefines: '', doc: '',
    }],
  },
  brief: facts,
}) as never;

describe('an estimate the brief\'s own numbers contradict', () => {
  it('blocks v7\'s 0.92 against a 40/60 duty cycle, and shows the arithmetic', () => {
    const found = predicate(input('0.92'));
    expect(found).toHaveLength(1);
    expect(found[0].code).toBe('moe.dutyCycleBound');
    expect(found[0].blocking).toBe(true);
    // The message has to teach, not just refuse: the bound, the fleet it
    // implies, and the way out.
    expect(found[0].message).toContain('40 min of flight against 60 min of recharge');
    expect(found[0].message).toContain('4.8 of 12');
    expect(found[0].message).toContain('assert constraint');
  });

  it('allows an estimate the duty cycle can actually hold', () => {
    expect(predicate(input('0.4'))).toEqual([]);
    expect(predicate(input('0.35'))).toEqual([]);
  });

  it('allows a derived estimate, which is the whole point of the rule', () => {
    // No literal: CV-17's valueless estimate, fixed by a constraint. The
    // architecture that can cover more has to show how, and then it may.
    expect(predicate(input(''))).toEqual([]);
  });
});

describe('what it must not touch', () => {
  it('says nothing when the brief fixes no duty cycle', () => {
    expect(predicate(input('0.92', brief({ budgets: { fleetSize: 12 } })))).toEqual([]);
  });

  it('says nothing about a measure that makes no claim about any one moment', () => {
    // A share of reports acknowledged is not a share held simultaneously by a
    // population, and the duty cycle does not bound it.
    const facts = brief({
      measures: [{
        name: 'areaUnderWatchShare', sense: 'max', target: 0.8, unit: '',
        doc: 'Share of the reports that matter which an operator acknowledged.',
      }],
    });
    expect(predicate(input('0.83', facts))).toEqual([]);
  });

  it('says nothing about a measure with a unit, or one to be minimised', () => {
    expect(predicate(input('0.92', brief({
      measures: [{ name: 'areaUnderWatchShare', sense: 'max', target: 45, unit: 's',
                   doc: 'Latency at any moment.' }],
    })))).toEqual([]);
    expect(predicate(input('0.92', brief({
      measures: [{ name: 'areaUnderWatchShare', sense: 'min', target: 0.25, unit: '',
                   doc: 'Share lost at any moment.' }],
    })))).toEqual([]);
  });

  it('says nothing when the layer states no estimate at all', () => {
    const bare = { ...(input('0.92') as Record<string, unknown>), payloads: { elements: [] } };
    expect(predicate(bare as never)).toEqual([]);
  });
});

describe('a member that cannot get back', () => {
  const transit = PREDICATES['moe.transitBudget'];

  const withBudgets = (budgets: Record<string, number>) => ({
    root: 'Swarm', layer: 'PA' as const, blocking: true,
    tags: { byElement: new Map(), byKeyword: new Map(), has: () => false, taggedWith: () => [] },
    payloads: { elements: [] },
    brief: brief({ budgets }),
  }) as never;

  it('says nothing when the brief states no speed — the case v7 is in', () => {
    // The check must not guess a speed. Inventing one would be fabricating the
    // very fact it exists to test, and v7 states none.
    expect(transit(withBudgets({
      areaOfInterestKm2: 25, memberFlightEnduranceMinutes: 40, fleetSize: 12,
    }))).toEqual([]);
  });

  it('blocks when the round trip alone spends the whole endurance', () => {
    // 25 km² → 3535.53 m to the far corner; at 2 m/s that is 3535.53 s there
    // and back, against 40 min = 2400 s of endurance.
    const found = transit(withBudgets({
      areaOfInterestKm2: 25, memberFlightEnduranceMinutes: 40, memberCruiseSpeedMps: 2,
    }));
    expect(found).toHaveLength(1);
    expect(found[0].code).toBe('moe.transitBudget');
    expect(found[0].message).toContain('3535.53');
    expect(found[0].message).toContain('2400');
    // It has to say what to do, and that the number came from a flight.
    expect(found[0].message).toContain('Measured, not assumed');
  });

  it('allows a member fast enough to do the trip and still watch', () => {
    // 15 m/s over the same area: 471 s of transit inside 2400 s of endurance.
    expect(transit(withBudgets({
      areaOfInterestKm2: 25, memberFlightEnduranceMinutes: 40, memberCruiseSpeedMps: 15,
    }))).toEqual([]);
  });

  it('reads whatever the brief called the speed', () => {
    expect(transit(withBudgets({
      areaOfInterestKm2: 25, memberFlightEnduranceMinutes: 40, cruiseSpeed: 2,
    }))).toHaveLength(1);
  });

  it('says nothing without an area or an endurance to compare', () => {
    expect(transit(withBudgets({ memberCruiseSpeedMps: 2, memberFlightEnduranceMinutes: 40 }))).toEqual([]);
    expect(transit(withBudgets({ memberCruiseSpeedMps: 2, areaOfInterestKm2: 25 }))).toEqual([]);
  });
});

describe('reading the brief by meaning rather than by spelling', () => {
  const duty = PREDICATES['moe.dutyCycleBound'];
  const transit = PREDICATES['moe.transitBudget'];

  const withBudgets = (budgets: Record<string, number>, value = '0.92') => ({
    root: 'Swarm', layer: 'PA' as const, blocking: true,
    tags: { byElement: new Map(), byKeyword: new Map(), has: () => false, taggedWith: () => [] },
    payloads: { elements: [{
      id: '1', qualifiedName: 'Swarm::PA::areaUnderWatchShare', name: 'areaUnderWatchShare',
      metaclass: 'AttributeUsage', type: '', multiplicity: '', value, redefines: '', doc: '',
    }] },
    brief: brief({ budgets }),
  }) as never;

  it('finds the duty cycle whatever the brief called the turnaround', () => {
    // v7 said memberRechargeMinutes, v8 said groundTurnaroundMinutes from the
    // same paragraph. Keyed on the first spelling, this gate went silent on the
    // second run and nobody noticed — the worst way for a check to fail.
    const found = duty(withBudgets({
      fleetSizeDrones: 12, memberFlightEnduranceMinutes: 40, groundTurnaroundMinutes: 20,
    }));
    expect(found).toHaveLength(1);
    expect(found[0].message).toContain('40 min of flight against 20 min');
  });

  it('finds the area whatever the brief called it', () => {
    const found = transit(withBudgets({
      areaOfInterestSquareKilometres: 25, memberFlightEnduranceMinutes: 40,
      cruiseSpeedMetresPerSecond: 2,
    }));
    expect(found).toHaveLength(1);
  });

  it('allows a share the stated footprint actually reaches', () => {
    // Eight of twelve airborne at 3 km² each is 24 of 25 km², so 0.9 is
    // arithmetic and not optimism. Blocking it would be the check refusing to
    // read a fact the brief put there.
    expect(duty(withBudgets({
      fleetSizeDrones: 12, memberFlightEnduranceMinutes: 40, groundTurnaroundMinutes: 20,
      sensorFootprintSquareKilometres: 3, areaOfInterestSquareKilometres: 25,
    }, '0.90'))).toEqual([]);
  });

  it('still blocks a claim beyond what even the footprint reaches', () => {
    const found = duty(withBudgets({
      fleetSizeDrones: 12, memberFlightEnduranceMinutes: 40, groundTurnaroundMinutes: 20,
      sensorFootprintSquareKilometres: 1, areaOfInterestSquareKilometres: 25,
    }, '0.90'));
    expect(found).toHaveLength(1);
    expect(found[0].message).toContain('keep under watch');
  });
});
