/**
 * A brief's budgets, found by what they mean rather than how one run spelled them.
 *
 * Shared by the gates (`check/predicates.ts`) and the simulation adapter
 * (`realization/adapter.ts`): both read the same brief, and two readers with two
 * spellings is how a check — or a whole simulation — goes silent on a new run.
 */

/**
 * A budget the brief fixes, found by what it means rather than by its spelling.
 *
 * SEED names the budgets; the brief is prose. v7 produced
 * `memberRechargeMinutes` and `areaOfInterestKm2`, v8 produced
 * `groundTurnaroundMinutes` and `areaOfInterestSquareKilometres` from the same
 * paragraph — and two gates keyed on the first spellings went silent on the
 * second run without anyone noticing, which is the worst way for a check to
 * fail. Patterns, and the first match wins.
 */
export const budgetLike = (
  budgets: Readonly<Record<string, number>>,
  pattern: RegExp,
): number | undefined => {
  const key = Object.keys(budgets).find((name) => pattern.test(name));
  return key === undefined ? undefined : budgets[key];
};

export const BUDGET = {
  endurance: /enduran/i,
  /** Time on the ground between sorties, however the brief words it. */
  turnaround: /recharge|turnaround|refuel|swap/i,
  area: /area/i,
  speed: /speed|cruise/i,
  fleet: /fleet.?size|size.?fleet|fleet.?count/i,
  /** What one member keeps under watch at once, when the brief fixes it. */
  footprint: /footprint|sensor.?(area|coverage)|coverage.?per/i,
} as const;

/**
 * The brief's budgets, with the names the simulation generator reads added
 * beside whatever SEED called them. v9's brief says `memberEnduranceMinutes`,
 * `groundTurnaroundMinutes` and `fleetSizeMembers`; the generator asked for
 * v7's `memberFlightEnduranceMinutes`, `memberRechargeMinutes` and `fleetSize`
 * and refused to simulate any run since. A speed is only taken when its name
 * says metres per second — the unit the generator flies in.
 */
export function withCanonicalBudgets(budgets: Readonly<Record<string, number>>): Record<string, number> {
  const out: Record<string, number> = { ...budgets };
  const add = (name: string, pattern: RegExp): void => {
    if (out[name] !== undefined) return;
    const value = budgetLike(budgets, pattern);
    if (value !== undefined) out[name] = value;
  };
  add('areaOfInterestKm2', BUDGET.area);
  add('memberFlightEnduranceMinutes', BUDGET.endurance);
  add('memberRechargeMinutes', BUDGET.turnaround);
  add('fleetSize', BUDGET.fleet);
  add('memberCruiseSpeedMps', /metres?PerSecond|mps\b/i);
  return out;
}
