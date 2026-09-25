/**
 * A hazard accepted with its reason is not a coverage gap. v4's final audit
 * listed `cotsRadioSupplyRiskHazard` as accepted and, further down, as
 * "satisfied by nothing".
 */
import { describe, expect, it } from 'vitest';
import { PREDICATES, type PredicateInput } from '../../src/check/predicates.ts';
import { acceptedNote } from '../../src/audit/final.ts';
import { step as stepById } from '../../src/spec/steps.ts';
import type { TagIndex } from '../../src/sysprose/backend.ts';
import type { RequirementsPayload } from '../../src/sysprose/types.ts';

const ROOT = 'Swarm';
const qn = (n: string) => `${ROOT}::EPBS::Hazards::${n}`;
const tags = (byKeyword: Record<string, string[]>): TagIndex => ({
  byElement: new Map(),
  byKeyword: new Map(Object.entries(byKeyword)),
  has: (q, k) => (byKeyword[k] ?? []).includes(q),
  taggedWith: (k) => byKeyword[k] ?? [],
});
const reqRow = (name: string, satisfied: boolean) =>
  ({ id: `id-${name}`, number: '', reqId: '', name, metaclass: 'RequirementUsage', kind: 'requirement', text: '', satisfied }) as unknown as RequirementsPayload['rows'][number];
const elRow = (name: string) => ({ id: `id-${name}`, qualifiedName: qn(name), name, metaclass: 'RequirementUsage', type: '', multiplicity: '', value: '', redefines: '', doc: 'd' });
const reqs = (rows: RequirementsPayload['rows']): RequirementsPayload =>
  ({ total: rows.length, satisfied: rows.filter((r) => r.satisfied).length, coverage: 0, libraryExcluded: 0, implicitExcluded: 0, nonNormativeExcluded: 0, kind: null, rows }) as RequirementsPayload;

const input = (t: TagIndex): PredicateInput => ({
  step: stepById('S70'),
  layer: undefined,
  root: ROOT,
  knobs: { modes_states: true, interfaces: true, variability: true, safety: true, views: false, verification: true, requirements_intake: false, infrastructure_intake: false },
  payloads: {
    requirements: reqs([reqRow('cotsRadioSupplyRiskHazard', false), reqRow('mixedBaselineHazard', false), reqRow('fleetSize', true)]),
    elements: [elRow('cotsRadioSupplyRiskHazard'), elRow('mixedBaselineHazard'), elRow('fleetSize')],
  },
  tags: t,
  blocking: false,
});

describe('requirements.coverage and accepted hazards', () => {
  it('does not report a hazard accepted with its reason, and still reports the rest', () => {
    const t = tags({ Hazard: [qn('cotsRadioSupplyRiskHazard'), qn('mixedBaselineHazard')], Accepted: [qn('cotsRadioSupplyRiskHazard')] });
    const names = PREDICATES['requirements.coverage'](input(t)).map((i) => i.qualifiedName);
    expect(names).toEqual(['mixedBaselineHazard']);
  });

  it('says in the headline which unsatisfied requirements are accepted', () => {
    const one = reqs([reqRow('cotsRadioSupplyRiskHazard', false), reqRow('fleetSize', true)]);
    expect(acceptedNote(one, ['cotsRadioSupplyRiskHazard'])).toBe('; the 1 unsatisfied is a hazard accepted with its reason');
    const two = reqs([reqRow('cotsRadioSupplyRiskHazard', false), reqRow('mixedBaselineHazard', false)]);
    expect(acceptedNote(two, ['cotsRadioSupplyRiskHazard'])).toBe('; 1 of the 2 unsatisfied are hazards accepted with their reason');
    expect(acceptedNote(two, [])).toBe('');
  });
});
