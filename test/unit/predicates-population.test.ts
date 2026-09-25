/**
 * A population the brief declares is a population the model has to show.
 */
import { describe, expect, it } from 'vitest';
import { PREDICATES, type BriefFacts, type PredicateInput } from '../../src/check/predicates.ts';
import { step as stepById } from '../../src/spec/steps.ts';
import type { TagIndex } from '../../src/sysprose/backend.ts';

const ROOT = 'Swarm';
const noTags: TagIndex = { byElement: new Map(), byKeyword: new Map(), has: () => false, taggedWith: () => [] };
const row = (qualifiedName: string, metaclass: string, type = '') => ({
  id: qualifiedName,
  qualifiedName,
  name: qualifiedName.split('::').pop()!,
  metaclass,
  type,
  multiplicity: '',
  value: '',
  redefines: '',
  doc: 'd',
});
const link = (from: string, to: string) => ({ from, to, fromName: `${ROOT}::OA::${from}`, toName: `${ROOT}::OA::${to}` });

const population: NonNullable<BriefFacts['population']> = {
  memberDef: 'SwarmMember',
  fleetPart: 'fleet',
  size: 12,
  meshPort: 'MeshPort',
  meshInterface: 'MeshLink',
  coordinationCapability: 'CoordinateCoverage',
};
const brief = (over: Partial<BriefFacts> = {}): BriefFacts => ({
  systemName: 'Swarm',
  aliases: [],
  moes: ['fleetSizeDrones'],
  capabilities: ['CoordinateCoverage', 'HoldWatch'],
  systemEntity: 'watchAssetA',
  population,
  coordinationFunctions: ['handOverSector'],
  c2Functions: ['issueTasking'],
  ...over,
});
const base = (stepId: 'S00' | 'S10', payloads: PredicateInput['payloads'], over: Partial<PredicateInput> = {}): PredicateInput => ({
  step: stepById(stepId),
  layer: stepId === 'S10' ? 'OA' : undefined,
  root: ROOT,
  knobs: { modes_states: true, interfaces: true, variability: true, safety: false, views: false, verification: true, requirements_intake: false, infrastructure_intake: false },
  brief: brief(),
  payloads,
  tags: noTags,
  blocking: true,
  ...over,
});

const oaParts = (...names: string[]) => names.map((n) => row(`${ROOT}::OA::${n}`, 'PartUsage', 'OA::WatchAsset'));
const allocate = (...links: Array<[string, string]>) => ({ rows: [], columns: [], links: links.map(([a, p]) => link(a, p)), unlinkedRows: [], unlinkedColumns: [] });

describe('oa.members', () => {
  it('blocks one instance standing in for the fleet, and names the second representative to write', () => {
    const items = PREDICATES['oa.members'](base('S10', { elements: oaParts('watchAssetA'), 'trace-allocate': allocate(['holdWatch', 'watchAssetA']) }));
    expect(items).toHaveLength(1);
    expect(items[0].blocking).toBe(true);
    expect(items[0].message).toContain('part watchAssetB : WatchAsset;');
  });

  it('counts only representatives that do something', () => {
    const items = PREDICATES['oa.members'](base('S10', { elements: oaParts('watchAssetA', 'watchAssetB'), 'trace-allocate': allocate(['holdWatch', 'watchAssetA']) }));
    expect(items).toHaveLength(1);
  });

  it('clears two representatives with activities of their own', () => {
    const items = PREDICATES['oa.members'](
      base('S10', { elements: oaParts('watchAssetA', 'watchAssetB'), 'trace-allocate': allocate(['handOverSector', 'watchAssetA'], ['takeOverSector', 'watchAssetB']) }),
    );
    expect(items).toEqual([]);
  });

  it('is silent without a population', () => {
    const input = base('S10', { elements: oaParts('watchAssetA'), 'trace-allocate': allocate(['holdWatch', 'watchAssetA']) }, { brief: brief({ population: undefined }) });
    expect(PREDICATES['oa.members'](input)).toEqual([]);
  });
});

describe('oa.systemEntity', () => {
  it('blocks when the entity is missing, and when it is tagged as an actor', () => {
    const missing = PREDICATES['oa.systemEntity'](base('S10', { elements: oaParts('watchAsset') }));
    expect(missing[0].message).toContain('declares no part of that name');
    const tagged = PREDICATES['oa.systemEntity'](
      base('S10', { elements: [...oaParts('watchAssetA'), row(`${ROOT}::OA::WatchAsset`, 'PartDefinition')] }, {
        tags: { ...noTags, has: (qn, k) => k === 'Actor' && qn === `${ROOT}::OA::WatchAsset`, taggedWith: (k) => (k === 'Actor' ? [`${ROOT}::OA::WatchAsset`] : []) },
      }),
    );
    expect(tagged[0].message).toContain('tagged as an actor');
  });
});

describe('seed.briefShape with a population', () => {
  const common = [row(`${ROOT}::Common::MeshPort`, 'PortDefinition'), row(`${ROOT}::Common::MeshLink`, 'InterfaceDefinition'), row(`${ROOT}::Common::fleetSizeDrones`, 'AttributeUsage')];

  it('clears a population whose names all exist', () => {
    expect(PREDICATES['seed.briefShape'](base('S00', { elements: common }))).toEqual([]);
  });

  it('names each missing piece: port, interface, capability, functions, keywords', () => {
    const items = PREDICATES['seed.briefShape'](
      base('S00', { elements: [] }, { brief: brief({ capabilities: ['HoldWatch'], coordinationFunctions: ['assign'], c2Functions: [] }) }),
    );
    const text = items.map((i) => i.message).join('\n');
    expect(text).toContain('port def MeshPort');
    expect(text).toContain('interface def MeshLink');
    expect(text).toContain('coordination capability');
    expect(text).toContain('no command-and-control functions');
    expect(text).toContain('`assign` is a keyword');
    // Only what SEED's repair can rewrite, package Common, blocks.
    const blocking = items.filter((i) => i.blocking).map((i) => i.message).join('\n');
    expect(blocking).toContain('port def MeshPort');
    expect(blocking).not.toContain('coordination capability');
    expect(blocking).not.toContain('`assign` is a keyword');
  });
});

describe('oa.namedFunctions', () => {
  const def = (name: string) => row(`${ROOT}::OA::${name}`, 'ActionDefinition');
  const usage = (name: string, type: string) => row(`${ROOT}::OA::${name}`, 'ActionUsage', type);
  const tagged = (pairs: Array<[string, string]>): TagIndex => ({
    byElement: new Map(),
    byKeyword: new Map(),
    has: (q, k) => pairs.some(([n, t]) => `${ROOT}::OA::${n}` === q && t === k),
    taggedWith: () => [],
  });
  const tags = tagged([['HandOverSector', 'Coordination'], ['IssueTasking', 'C2']]);
  const members = oaParts('watchAssetA', 'watchAssetB');
  const whole = [def('HandOverSector'), def('IssueTasking'), usage('alphaHandOverSector', 'HandOverSector'), usage('bravoHandOverSector', 'HandOverSector'), usage('issueTasking', 'IssueTasking'), ...members];
  const alloc = allocate(['alphaHandOverSector', 'watchAssetA'], ['bravoHandOverSector', 'watchAssetB'], ['issueTasking', 'operator']);
  const text = (elements: ReturnType<typeof row>[], t: TagIndex = tags, a = alloc) =>
    PREDICATES['oa.namedFunctions'](base('S10', { elements, 'trace-allocate': a }, { tags: t })).map((x) => x.message).join('\n');

  it('clears definitions named and tagged as the brief says, each member performing the coordination', () => {
    expect(text(whole)).toBe('');
  });

  it('asks for the missing definition, and for the tag on one that exists', () => {
    const out = text([def('HandOverSector'), ...members], noTags);
    expect(out).toContain('write `#Coordination action def HandOverSector`');
    expect(out).toContain('declares no `action def IssueTasking`');
    expect(out).toContain('action alphaIssueTasking : IssueTasking;');
  });

  it('asks each member to perform coordination through the named definition, not an ad-hoc one each', () => {
    // v5's risk: `action alphaHandOverSector : AlphaHandOver;` — nothing merges at T-01.
    const adHoc = whole.filter((e) => !e.name.endsWith('HandOverSector') || e.metaclass === 'ActionDefinition').concat([usage('alphaHandOverSector', 'AlphaHandOver'), usage('bravoHandOverSector', 'BravoHandOver')]);
    expect(text(adHoc)).toContain('`HandOverSector` is declared and nothing is typed by it');
    const one = text(whole, tags, allocate(['alphaHandOverSector', 'watchAssetA'], ['bravoHandOverSector', 'watchAssetA'], ['issueTasking', 'operator']));
    expect(one).toContain('only one member performs it');
    // Command and control performed by the operator alone is fine.
    expect(text(whole)).not.toContain('IssueTasking');
  });

  it('is silent without a population, and is wired at S10', () => {
    expect(PREDICATES['oa.namedFunctions'](base('S10', { elements: [] }, { brief: brief({ population: undefined }) }))).toEqual([]);
    expect(stepById('S10').checks.flatMap((c) => c.predicates ?? [])).toContain('oa.namedFunctions');
  });
});
