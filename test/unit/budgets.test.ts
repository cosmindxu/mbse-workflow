/**
 * The simulation reads a brief's budgets by what they mean, as the gates do.
 */
import { describe, expect, it } from 'vitest';
import { withCanonicalBudgets } from '../../src/spec/budgets.ts';

describe('canonical budgets for the simulation', () => {
  it("adds the generator's names beside v9's spellings, and keeps v7's as they are", () => {
    const v9 = withCanonicalBudgets({
      fleetSizeMembers: 12,
      memberEnduranceMinutes: 40,
      groundTurnaroundMinutes: 20,
      cruiseSpeedMetresPerSecond: 18,
      areaOfInterestSquareKilometres: 25,
    });
    expect(v9).toMatchObject({
      fleetSize: 12,
      memberFlightEnduranceMinutes: 40,
      memberRechargeMinutes: 20,
      memberCruiseSpeedMps: 18,
      areaOfInterestKm2: 25,
    });
    const v7 = { fleetSize: 12, memberFlightEnduranceMinutes: 40, memberRechargeMinutes: 60, areaOfInterestKm2: 25 };
    expect(withCanonicalBudgets(v7)).toEqual(v7);
  });

  it('takes no speed whose name does not say metres per second', () => {
    expect(withCanonicalBudgets({ cruiseSpeedKmh: 65 }).memberCruiseSpeedMps).toBeUndefined();
  });
});
