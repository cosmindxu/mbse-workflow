/**
 * A budget the brief fixes is restated at a layer by a feature that subsets it (CV-20).
 *
 * v9's final audit read eight of its ten budgets as "has no value anywhere and
 * nothing specialises it", `fleetSizeMembers` among them, while LA and PA each
 * wrote `attribute fleetMemberCount = 12`: a copy nothing tied to the budget.
 */
import { describe, expect, it } from 'vitest';
import { PREDICATES, type PredicateInput } from '../../src/check/predicates.ts';
import { step as stepById } from '../../src/spec/steps.ts';
import { convention } from '../../src/spec/conventions.ts';
import { buildSystemPrompt } from '../../src/prompts/system.ts';
import { estimateGuidance } from '../../src/agents/alternatives.ts';
import type { Moe } from '../../src/llm/schemas.ts';
import type { ElementRow } from '../../src/sysprose/types.ts';

const ROOT = 'Swarm';
// `type` and `redefines` are the elements cells: the simple name of what a
// feature is typed by, subsets or redefines.
const feature = (layer: string, name: string, over: Partial<ElementRow> = {}): ElementRow => ({
  id: `${layer}-${name}`, qualifiedName: `${ROOT}::${layer}::${name}`, name, metaclass: 'AttributeUsage', type: '', multiplicity: '', value: '12', redefines: '', doc: '', ...over,
});
const input = (layer: 'LA' | 'PA', elements: ElementRow[], budgets: Record<string, number> = { fleetSizeMembers: 12, memberEnduranceMinutes: 40 }): PredicateInput => ({
  step: stepById(layer === 'LA' ? 'S32' : 'S41'),
  layer,
  root: ROOT,
  knobs: { modes_states: true, interfaces: true, variability: true, safety: false, views: false, verification: true, requirements_intake: false, infrastructure_intake: false },
  brief: { systemName: ROOT, aliases: [], moes: [], capabilities: [], budgets },
  payloads: { elements },
  tags: { byElement: new Map(), byKeyword: new Map(), has: () => false, taggedWith: () => [] },
  blocking: true,
  alternative: 1,
});
const subset = PREDICATES['budgets.subset'];

describe('budgets.subset', () => {
  it('is silent when each budget is subset or redefined at this layer, under any name', () => {
    expect(subset(input('LA', [
      feature('LA', 'fleetMemberCount', { type: 'fleetSizeMembers' }),
      // Nested in a part, and typed as well as subsetting: still a feature of this layer.
      feature('LA', 'Drone::endurance', { type: 'Real, memberEnduranceMinutes', value: '40' }),
    ]))).toEqual([]);
    expect(subset(input('PA', [
      feature('PA', 'fleetSizeMembers', { redefines: 'fleetSizeMembers' }),
      feature('PA', 'memberEnduranceMinutes', { type: 'memberEnduranceMinutes', value: '40' }),
    ]))).toEqual([]);
  });

  it('notes a budget only copied into a plain attribute, never blocking, with the line to write', () => {
    // v9's LA: the number, under its own name, tied to nothing.
    const items = subset(input('LA', [feature('LA', 'fleetMemberCount'), feature('LA', 'memberFlightMinutes', { type: 'memberEnduranceMinutes', value: '40' })]));
    expect(items).toHaveLength(1);
    expect(items[0]).toMatchObject({ code: 'budgets.subset', severity: 'info', blocking: false, cv: 'CV-20' });
    expect(items[0].message).toContain('`Common::fleetSizeMembers`');
    expect(items[0].message).not.toContain('memberEnduranceMinutes');
    expect(items[0].message).toContain('`attribute <name> :> Common::fleetSizeMembers = 12;`');
  });

  it('does not count a feature outside this layer that subsets the budget', () => {
    const items = subset(input('PA', [
      feature('LA', 'fleetMemberCount', { type: 'fleetSizeMembers' }),
      feature('Common', 'fleetUpperBound', { type: 'fleetSizeMembers' }),
    ], { fleetSizeMembers: 12 }));
    expect(items).toHaveLength(1);
    expect(items[0].message).toContain('no feature in `package PA`');
  });

  it('is silent for a brief that fixes no budget', () => {
    expect(subset(input('LA', [], {}))).toEqual([]);
  });

  it('runs at both alternatives steps, in a check whose blocking it does not take', () => {
    for (const id of ['S32', 'S41'] as const) {
      expect(stepById(id).checks.flatMap((c) => c.predicates ?? [])).toContain('budgets.subset');
      expect(stepById(id).uses).toContain('CV-20');
    }
  });
});

describe('the author at LA and PA', () => {
  it('reads CV-20, with the direction of the bounds, among its house rules', () => {
    const rule = convention('CV-20')?.rule ?? '';
    expect(rule).toContain('attribute fleetMemberCount :> Common::fleetSizeMembers = 12;');
    expect(rule).toContain('memberEnduranceMinutes <= 40');
    expect(rule).toContain('memberFlightMinutes >= 40');
    const knobs = { modes_states: true, interfaces: true, variability: true, safety: false, views: false, verification: true, requirements_intake: false, infrastructure_intake: false };
    for (const id of ['S32', 'S41'] as const) {
      expect(buildSystemPrompt({ step: stepById(id), knobs, root: ROOT })).toContain('**CV-20 Budgets restated at a layer**');
    }
  });

  it('is shown how to restate one of this brief\'s budgets, not another brief\'s', () => {
    const measure: Moe = { name: 'areaUnderWatchFraction', unit: '', sense: 'max', target: 0.9, doc: 'share watched' };
    const jammed: Moe = { name: 'meshLinksJammedFraction', unit: '', sense: 'max', target: 0.5, doc: 'half the links jammed', kind: 'budget', condition: true };
    const endurance: Moe = { name: 'memberEnduranceMinutes', unit: 'min', sense: 'min', target: 40, doc: 'flight per sortie', kind: 'budget' };
    const text = estimateGuidance([measure], 'LA', [jammed, endurance]).join(' ');
    expect(text).toContain('restate those numbers as attributes of this layer that subset the brief\'s budget in Common');
    expect(text).toContain('`attribute memberEnduranceMinutes :> Common::memberEnduranceMinutes = 40;`');
    expect(text).toContain('CV-20');
    expect(text).not.toContain('dronesFielded');
    expect(estimateGuidance([measure], 'LA').join(' ')).toContain('`attribute <name> :> Common::<budget> = <the brief\'s number>;`');
  });
});
