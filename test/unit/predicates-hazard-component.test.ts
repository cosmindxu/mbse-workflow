/**
 * An architecture mitigates the system's hazards with its own components.
 */
import { describe, expect, it } from 'vitest';
import { PREDICATES, type PredicateInput } from '../../src/check/predicates.ts';
import { step as stepById } from '../../src/spec/steps.ts';
import type { TagIndex } from '../../src/sysprose/backend.ts';
import type { RequirementsPayload } from '../../src/sysprose/types.ts';

const ROOT = 'Swarm';
const el = (qn: string, metaclass: string, type = '') => ({ id: qn, qualifiedName: `${ROOT}::${qn}`, name: qn.split('::').pop()!, metaclass, type, multiplicity: '', value: '', redefines: '', doc: 'd' });
const req = (qn: string, satisfiedBy: string[]) => ({ id: qn, number: '', reqId: '', name: qn.split('::').pop()!, metaclass: 'RequirementUsage', kind: 'requirement', text: '', satisfied: satisfiedBy.length > 0, satisfiedBy }) as unknown as RequirementsPayload['rows'][number];
const tags = (byKeyword: Record<string, string[]>): TagIndex => ({
  byElement: new Map(),
  byKeyword: new Map(),
  has: (q, k) => (byKeyword[k] ?? []).map((n) => `${ROOT}::${n}`).includes(q),
  taggedWith: (k) => (byKeyword[k] ?? []).map((n) => `${ROOT}::${n}`),
});

const elements = [
  el('LA::GroundStation', 'PartDefinition'),
  el('LA::Operator', 'PartDefinition'),
  el('LA::groundStation', 'PartUsage', 'LA::GroundStation'),
  el('LA::groundStation::safetyMonitor', 'PartUsage', 'LA::SafetyMonitor'),
  el('LA::operator', 'PartUsage', 'LA::Operator'),
  el('LA::recallAndLand', 'ActionUsage', 'LA::RecallAndLand'),
  el('SA::Hazards::flyaway', 'RequirementUsage'),
  el('LA::Hazards::linkGap', 'RequirementUsage'),
  el('LA::Hazards::supply', 'RequirementUsage'),
  el('OA::Hazards::crowd', 'RequirementUsage'),
];
const input = (rows: RequirementsPayload['rows'], over: Partial<PredicateInput> = {}): PredicateInput => ({
  step: stepById('S32'),
  layer: 'LA',
  root: ROOT,
  knobs: { modes_states: true, interfaces: true, variability: true, safety: true, views: false, verification: true, requirements_intake: false, infrastructure_intake: false },
  payloads: { elements, 'requirements-hazards': { rows } as RequirementsPayload },
  tags: tags({ Hazard: ['SA::Hazards::flyaway', 'LA::Hazards::linkGap', 'LA::Hazards::supply', 'OA::Hazards::crowd'], Accepted: ['LA::Hazards::supply'], Actor: ['LA::Operator'] }),
  blocking: true,
  alternative: 1,
  ...over,
});
const flagged = (i: PredicateInput) => PREDICATES['requirements.hazardsByComponent'](i).map((x) => x.qualifiedName);

describe('requirements.hazardsByComponent', () => {
  it('blocks a system hazard only a shared function mitigates, and says which function', () => {
    const items = PREDICATES['requirements.hazardsByComponent'](input([req('SA::Hazards::flyaway', ['recallAndLand'])]));
    expect(items.map((x) => x.qualifiedName)).toEqual([`${ROOT}::SA::Hazards::flyaway`]);
    expect(items[0].message).toContain('only by `recallAndLand`');
    expect(items[0].blocking).toBe(true);
  });

  it('clears a satisfy by a component, nested ones included, and not by an actor', () => {
    expect(flagged(input([req('LA::Hazards::linkGap', ['groundStation'])]))).toEqual([]);
    expect(flagged(input([req('LA::Hazards::linkGap', ['safetyMonitor'])]))).toEqual([]);
    expect(flagged(input([req('LA::Hazards::linkGap', ['operator'])]))).toEqual([`${ROOT}::LA::Hazards::linkGap`]);
  });

  it('leaves accepted hazards, the operation\'s hazards, and steps that are not alternatives alone', () => {
    expect(flagged(input([req('LA::Hazards::supply', []), req('OA::Hazards::crowd', [])]))).toEqual([]);
    expect(flagged(input([req('SA::Hazards::flyaway', [])], { alternative: undefined }))).toEqual([]);
    expect(flagged(input([req('SA::Hazards::flyaway', [])], { knobs: { ...input([]).knobs, safety: false } }))).toEqual([]);
  });

  it('is wired into both alternatives steps', () => {
    for (const id of ['S32', 'S41'] as const) expect(stepById(id).checks.flatMap((c) => c.predicates ?? [])).toContain('requirements.hazardsByComponent');
  });
});
