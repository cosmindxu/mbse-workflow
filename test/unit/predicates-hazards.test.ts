/**
 * A stated hazard is a mitigated hazard, or an accepted one.
 */
import { describe, expect, it } from 'vitest';
import { PREDICATES, type PredicateInput } from '../../src/check/predicates.ts';
import { step as stepById } from '../../src/spec/steps.ts';
import type { TagIndex } from '../../src/sysprose/backend.ts';

const ROOT = 'Swarm';
const tags = (byElement: Record<string, string[]>): TagIndex => {
  const byKeyword = new Map<string, string[]>();
  for (const [qn, words] of Object.entries(byElement)) for (const w of words) byKeyword.set(w, [...(byKeyword.get(w) ?? []), qn]);
  return {
    byElement: new Map(Object.entries(byElement)),
    byKeyword,
    has: (qn, k) => (byElement[qn] ?? []).includes(k),
    taggedWith: (k) => byKeyword.get(k) ?? [],
  };
};
const el = (id: string, qualifiedName: string) => ({ id, qualifiedName, name: qualifiedName.split('::').pop()!, metaclass: 'RequirementUsage', type: '', multiplicity: '', value: '', redefines: '', doc: 'd' });
const row = (id: string, name: string, satisfied: boolean | null) => ({ id, number: '', reqId: '', name, metaclass: 'RequirementUsage', kind: 'requirement', text: '', satisfied, satisfiedBy: [], verifiedBy: [], refinedBy: [], tracedTo: [], derivedFrom: [] });

const input = (over: Partial<PredicateInput> = {}): PredicateInput => ({
  step: stepById('S21'),
  layer: 'SA',
  root: ROOT,
  knobs: { modes_states: true, interfaces: true, variability: true, safety: true, views: false, verification: true, requirements_intake: false, infrastructure_intake: false },
  payloads: {
    elements: [el('h1', `${ROOT}::OA::Hazards::hazFlyaway`), el('h2', `${ROOT}::SA::Hazards::hazFlyaway`), el('h3', `${ROOT}::SA::Hazards::hazWind`), el('r1', `${ROOT}::SA::Budgets::budget`)],
    'requirements-hazards': { total: 4, satisfied: 1, coverage: 0.25, libraryExcluded: 0, implicitExcluded: 0, nonNormativeExcluded: 0, kind: 'requirement', rows: [row('h1', 'hazFlyaway', true), row('h2', 'hazFlyaway', false), row('h3', 'hazWind', false), row('r1', 'budget', false)] },
  },
  tags: tags({ [`${ROOT}::OA::Hazards::hazFlyaway`]: ['Hazard'], [`${ROOT}::SA::Hazards::hazFlyaway`]: ['Hazard'], [`${ROOT}::SA::Hazards::hazWind`]: ['Hazard', 'Accepted'] }),
  blocking: true,
  ...over,
});

describe('requirements.hazardsMitigated', () => {
  it('blocks on the unsatisfied hazard, by id, and only on hazards', () => {
    const items = PREDICATES['requirements.hazardsMitigated'](input());
    expect(items.map((i) => i.qualifiedName)).toEqual([`${ROOT}::SA::Hazards::hazFlyaway`]);
    expect(items[0].blocking).toBe(true);
    expect(items[0].message).toContain('satisfy hazFlyaway by');
  });

  it('lets an #Accepted hazard through, and an unsatisfied non-hazard alone', () => {
    const items = PREDICATES['requirements.hazardsMitigated'](input());
    expect(items.map((i) => i.qualifiedName)).not.toContain(`${ROOT}::SA::Hazards::hazWind`);
    expect(items.map((i) => i.qualifiedName)).not.toContain(`${ROOT}::SA::Budgets::budget`);
  });

  it('is silent when the safety knob is off', () => {
    const i = input(); i.knobs = { ...i.knobs, safety: false };
    expect(PREDICATES['requirements.hazardsMitigated'](i)).toEqual([]);
  });
});
