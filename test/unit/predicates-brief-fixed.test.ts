/**
 * What the brief fixes by name — hazards, modes, rules, items — reaches the
 * model under those names (CV-18, CV-19).
 */
import { describe, expect, it } from 'vitest';
import { PREDICATES, type BriefFacts, type PredicateInput } from '../../src/check/predicates.ts';
import { withDroppedHazards } from '../../src/agents/author.ts';
import type { Verdict } from '../../src/check/checker.ts';
import { step as stepById, type StepId } from '../../src/spec/steps.ts';
import type { RuleRow } from '../../src/spec/rules.ts';
import type { Layer } from '../../src/spec/layers.ts';
import type { TagIndex } from '../../src/sysprose/backend.ts';

const ROOT = 'Swarm';
const el = (qn: string, metaclass: string, type = '') => ({ id: qn, qualifiedName: `${ROOT}::${qn}`, name: qn.split('::').pop()!, metaclass, type, multiplicity: '', value: '', redefines: '', doc: 'd' });
const tags = (byKeyword: Record<string, string[]>): TagIndex => ({
  byElement: new Map(),
  byKeyword: new Map(),
  has: (q, k) => (byKeyword[k] ?? []).map((n) => `${ROOT}::${n}`).includes(q),
  taggedWith: (k) => (byKeyword[k] ?? []).map((n) => `${ROOT}::${n}`),
});
const population = { memberDef: 'Drone', fleetPart: 'fleet', size: 12, meshPort: 'MeshPort', meshInterface: 'MeshLink', coordinationCapability: 'Coordinate' };
const brief = (over: Partial<BriefFacts> = {}): BriefFacts => ({ systemName: ROOT, aliases: [], moes: [], capabilities: [], population, ...over });
const input = (id: StepId, layer: Layer, elements: ReturnType<typeof el>[], tagMap: Record<string, string[]>, over: Partial<PredicateInput> = {}): PredicateInput => ({
  step: stepById(id),
  layer,
  root: ROOT,
  knobs: { modes_states: true, interfaces: true, variability: true, safety: true, views: false, verification: true, requirements_intake: false, infrastructure_intake: false },
  payloads: { elements },
  tags: tags(tagMap),
  blocking: true,
  ...over,
});
const codes = (id: string, i: PredicateInput) => PREDICATES[id as keyof typeof PREDICATES](i);

describe('hazards.fromBrief', () => {
  it('blocks SA until every brief hazard is stated under its name, and is silent elsewhere or without hazards', () => {
    const b = brief({ hazards: ['PositionDriftHazard', 'StaleTrackHazard'] });
    const items = codes('hazards.fromBrief', input('S21', 'SA', [], { Hazard: ['SA::Hazards::PositionDriftHazard'] }, { brief: b }));
    expect(items.map((x) => x.message)).toEqual([expect.stringContaining('`StaleTrackHazard`')]);
    expect(items[0].blocking).toBe(true);
    expect(codes('hazards.fromBrief', input('S32', 'LA', [], {}, { brief: b }))).toEqual([]);
    expect(codes('hazards.fromBrief', input('S21', 'SA', [], {}, { brief: brief() }))).toEqual([]);
  });
});

describe('hazards.notRestated', () => {
  const t = { Hazard: ['SA::Hazards::linkGap', 'LA::Hazards::linkGap', 'LA::Hazards::newOne', 'OA::Hazards::linkGap'] };
  it('blocks a hazard restated below SA, naming the path to satisfy instead', () => {
    const items = codes('hazards.notRestated', input('S32', 'LA', [], t));
    expect(items.map((x) => x.qualifiedName)).toEqual([`${ROOT}::LA::Hazards::linkGap`]);
    expect(items[0].message).toContain('satisfy SA::Hazards::linkGap by <part>;');
  });
  it('lets SA reuse an operational hazard name, and a new name through', () => {
    expect(codes('hazards.notRestated', input('S21', 'SA', [], { Hazard: ['OA::Hazards::x', 'SA::Hazards::x'] }))).toEqual([]);
  });
  it('does not fight hazards.kept: removing a restated hazard is not a deletion', () => {
    const verdict: Verdict = { step: 'S32', prefixPath: '', prefixHash: '', blocking: false, checks: [], items: [], durationMs: 0, loaded: true, elementCount: 0 };
    expect(withDroppedHazards(verdict, new Set(['linkGap', 'own']), new Set(['own']), new Set(['linkGap']))).toBe(verdict);
    expect(withDroppedHazards(verdict, new Set(['linkGap', 'own']), new Set([]), new Set(['linkGap'])).items.map((i) => i.message)).toEqual([expect.stringContaining('`own`')]);
  });
});

describe('modes.fromBrief', () => {
  const elements = [
    el('LA::Drone', 'PartDefinition'),
    el('LA::Drone::DroneMode', 'StateDefinition'),
    el('LA::Drone::DroneMode::NavigationDegraded', 'StateUsage'),
    el('LA::GroundStation', 'PartDefinition'),
    el('LA::GroundStation::StationMode', 'StateDefinition'),
    el('LA::GroundStation::StationMode::Quarantined', 'StateUsage'),
  ];
  const b = brief({ modes: [{ name: 'NavigationDegraded', of: 'member' }, { name: 'Quarantined', of: 'member' }] });
  it('clears a mode on the member machine, and blocks one on the wrong owner, saying where it is', () => {
    const items = codes('modes.fromBrief', input('S32', 'LA', elements, { Member: ['LA::Drone'] }, { brief: b }));
    expect(items).toHaveLength(1);
    expect(items[0].message).toContain('`Quarantined`');
    expect(items[0].message).toContain('GroundStation::StationMode');
  });
  it('counts a package-level machine the member uses through a typed state usage', () => {
    const typed = [
      el('LA::Drone', 'PartDefinition'),
      el('LA::Drone::mode', 'StateUsage', 'MemberMode'),
      el('LA::MemberMode', 'StateDefinition'),
      el('LA::MemberMode::NavigationDegraded', 'StateUsage'),
      el('LA::MemberMode::Quarantined', 'StateUsage'),
    ];
    expect(codes('modes.fromBrief', input('S32', 'LA', typed, { Member: ['LA::Drone'] }, { brief: b }))).toEqual([]);
  });

  it('takes any non-actor owner at SA, where the system is one box', () => {
    const sa = elements.map((e) => ({ ...e, qualifiedName: e.qualifiedName.replace('::LA::', '::SA::') }));
    expect(codes('modes.fromBrief', input('S21', 'SA', sa, {}, { brief: b }))).toEqual([]);
  });
});

describe('rules.carried and rules.hold', () => {
  const elements = [el('LA::Drone', 'PartDefinition'), el('LA::Drone::DroneMode', 'StateDefinition'), el('LA::Ground', 'PartDefinition'), el('LA::Ground::GroundMode', 'StateDefinition')];
  const b = brief({ rules: [{ name: 'RecallWins', kind: 'winsUntil', of: 'member' }, { name: 'CanGetHome', kind: 'canAlwaysReturn', of: 'member' }] });
  const row = (rule: string | undefined, machine: string, pattern: string, scope: string, claim = 'pass', detail = ''): RuleRow => ({ machine: `${ROOT}::${machine}`, owner: `${ROOT}::${machine.split('::').slice(0, -1).join('::')}`, rule, fields: { pattern, scope, p: 'state A' }, claim, detail });
  const at = (rows: RuleRow[] | undefined) => input('S32', 'LA', elements, { Member: ['LA::Drone'] }, { brief: b, payloads: { elements, rules: rows } });

  it('clears rules carried with the right pattern on the owner the brief names', () => {
    expect(codes('rules.carried', at([row('RecallWins', 'LA::Drone::DroneMode', 'absence', 'between'), row('CanGetHome', 'LA::Drone::DroneMode', 'recovery', 'globally')]))).toEqual([]);
  });
  it('blocks a missing rule with the template, a wrong kind with the right pattern, and a wrong owner', () => {
    const missing = codes('rules.carried', at([row('CanGetHome', 'LA::Drone::DroneMode', 'recovery', 'globally')]));
    expect(missing.map((x) => x.message)).toEqual([expect.stringContaining('attribute scope = "between"')]);
    const kind = codes('rules.carried', at([row('RecallWins', 'LA::Drone::DroneMode', 'absence', 'after'), row('CanGetHome', 'LA::Drone::DroneMode', 'recovery', 'globally')]));
    expect(kind[0].message).toContain('pattern=absence, scope=between');
    const owner = codes('rules.carried', at([row('RecallWins', 'LA::Ground::GroundMode', 'absence', 'between'), row('CanGetHome', 'LA::Drone::DroneMode', 'recovery', 'globally')]));
    expect(owner[0].message).toContain('carried by `LA::Ground::GroundMode`');
  });
  it('asks for the #Rule requirement at SA only', () => {
    const saElements = [el('SA::Sys', 'PartDefinition'), el('SA::Sys::M', 'StateDefinition')];
    const sa = input('S21', 'SA', saElements, {}, { brief: b, payloads: { elements: saElements, rules: [row('RecallWins', 'SA::Sys::M', 'absence', 'between'), row('CanGetHome', 'SA::Sys::M', 'recovery', 'globally')] } });
    expect(codes('rules.carried', sa).map((x) => x.message)).toEqual([expect.stringContaining('#Rule requirement RecallWins'), expect.stringContaining('#Rule requirement CanGetHome')]);
  });
  it('does not count a carrier Sysprose could not read — a misnamed state or a placeholder left in', () => {
    const bad: RuleRow = { ...row('RecallWins', 'LA::Drone::DroneMode', 'absence', 'between', 'inconclusive', '`state <the state that starts it>` names no state in this machine'), code: 'verification/unknown-atom' };
    const items = codes('rules.carried', at([bad, row('CanGetHome', 'LA::Drone::DroneMode', 'recovery', 'globally')]));
    expect(items.map((x) => x.message)).toEqual([expect.stringContaining('could not be read: `state <the state that starts it>` names no state')]);
    // Reported once, by rules.carried; rules.hold keeps its notes for walks that genuinely could not decide.
    expect(codes('rules.hold', at([bad]))).toEqual([]);
  });

  it('is silent when the model did not load, so the payload is absent', () => {
    expect(codes('rules.carried', at(undefined))).toEqual([]);
  });
  it('blocks a failed rule with its run, notes an undecided one, and ignores properties no brief rule names', () => {
    const items = codes('rules.hold', at([
      row('RecallWins', 'LA::Drone::DroneMode', 'absence', 'between', 'fail', 'witness trace of 3 step(s)'),
      row('CanGetHome', 'LA::Drone::DroneMode', 'recovery', 'globally', 'inconclusive', 'bound hit'),
      row(undefined, 'LA::Drone::DroneMode', 'absence', 'globally', 'fail'),
    ]));
    expect(items.map((x) => [x.blocking, x.severity])).toEqual([[true, 'error'], [false, 'info']]);
    expect(items[0].message).toContain('witness trace of 3 step(s)');
  });
});

describe('common.itemFields', () => {
  const b = brief({ items: [{ name: 'DetectionReport', fields: ['confidence', 'objectClass'] }, { name: 'Track', fields: ['stale'] }] });
  it('blocks a missing item and a missing field, and clears a complete one', () => {
    const elements = [el('Common::DetectionReport', 'ItemDefinition'), el('Common::DetectionReport::confidence', 'AttributeUsage')];
    const items = codes('common.itemFields', input('S00', 'Common' as Layer, elements, {}, { brief: b }));
    expect(items.map((x) => x.message)).toEqual([expect.stringContaining('lacks `objectClass`'), expect.stringContaining('no `item def Track`')]);
  });
});
