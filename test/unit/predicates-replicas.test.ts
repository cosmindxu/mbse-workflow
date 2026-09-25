/**
 * A population gate asks for exactly what CV-16 says, one missing piece at a time.
 */
import { describe, expect, it } from 'vitest';
import { PREDICATES, type BriefFacts, type PredicateInput } from '../../src/check/predicates.ts';
import { step as stepById } from '../../src/spec/steps.ts';
import type { TagIndex } from '../../src/sysprose/backend.ts';
import type { ActionView, ConnectionView, LayerView } from '../../src/transition/view.ts';

const ROOT = 'Swarm';
const noTags: TagIndex = { byElement: new Map(), byKeyword: new Map(), has: () => false, taggedWith: () => [] };
const row = (name: string, metaclass: string, type = '', multiplicity = '') => ({
  id: name,
  qualifiedName: `${ROOT}::LA::${name}`,
  name,
  metaclass,
  type,
  multiplicity,
  value: '',
  redefines: '',
  doc: 'd',
});
const population: NonNullable<BriefFacts['population']> = {
  memberDef: 'SwarmMember',
  fleetPart: 'fleet',
  size: 12,
  meshPort: 'MeshPort',
  meshInterface: 'MeshLink',
  coordinationCapability: 'CoordinateCoverage',
};
const brief: BriefFacts = {
  systemName: 'Swarm',
  aliases: [],
  moes: [],
  capabilities: [],
  population,
  coordinationFunctions: ['handOverSector', 'rotateRecharge'],
  c2Functions: ['issueTasking'],
};
const action = (name: string, tag?: string): ActionView => ({ name, qualifiedName: `${ROOT}::LA::${name}`, params: [], keywords: tag ? [tag] : [] });

interface Shape {
  def?: boolean;
  fleet?: string;
  reps?: string[];
  links?: ConnectionView[];
  allocations?: Array<[string, string]>;
  actions?: ActionView[];
}
const whole: Shape = {
  def: true,
  fleet: '12',
  reps: ['memberA', 'memberB'],
  links: [{ name: 'peerLink', type: 'MeshLink', from: 'memberA::meshOut', to: 'memberB::meshIn', metaclass: 'InterfaceUsage' }],
  actions: [action('handOverSector', 'Coordination'), action('rotateRecharge', 'Coordination'), action('issueTasking', 'C2')],
  allocations: [],
};

const input = (shape: Shape, over: Partial<PredicateInput> = {}): PredicateInput => {
  const s = { ...whole, ...shape };
  const elements = [
    ...(s.def ? [row('SwarmMember', 'PartDefinition')] : []),
    ...(s.fleet ? [row('fleet', 'PartUsage', 'LA::SwarmMember', s.fleet)] : []),
    ...(s.reps ?? []).map((r) => row(r, 'PartUsage', 'LA::SwarmMember')),
    row('groundCoordinator', 'PartUsage', 'LA::GroundCoordinator'),
  ];
  const view: LayerView = {
    root: ROOT,
    layer: 'LA',
    actions: s.actions ?? [],
    parts: [],
    partDefs: s.def ? [{ name: 'SwarmMember', qualifiedName: `${ROOT}::LA::SwarmMember`, isActor: false, ports: [], keywords: ['Member'] }] : [],
    useCases: [],
    states: [],
    flows: [],
    connections: s.links ?? [],
    successions: [],
    allocations: (s.allocations ?? []).map(([fn, part]) => ({ action: `${ROOT}::LA::${fn}`, actionName: fn, part: `${ROOT}::LA::${part}`, partName: part })),
  };
  return {
    step: stepById('S32'),
    layer: 'LA',
    root: ROOT,
    knobs: { modes_states: true, interfaces: true, variability: true, safety: false, views: false, verification: true, requirements_intake: false, infrastructure_intake: false },
    brief,
    payloads: { elements, layerView: view },
    tags: noTags,
    blocking: true,
    ...over,
  };
};
const messages = (i: PredicateInput): string => PREDICATES['replicas.memberPair'](i).map((x) => x.message).join('\n');

describe('replicas.memberPair', () => {
  it('clears the CV-16 shape', () => {
    expect(PREDICATES['replicas.memberPair'](input({}))).toEqual([]);
  });

  it('asks for each missing piece on its own, quoting the line to write', () => {
    expect(messages(input({ def: false }))).toContain('#Member part def SwarmMember');
    expect(messages(input({ fleet: undefined }))).toContain('part fleet : SwarmMember [12];');
    expect(messages(input({ fleet: '4' }))).toContain('sized `[4]`');
    expect(PREDICATES['replicas.memberPair'](input({ fleet: '10..12' }))).toEqual([]);
    expect(PREDICATES['replicas.memberPair'](input({ fleet: '2..*' }))).toEqual([]);
    expect(messages(input({ fleet: '2..8' }))).toContain('sized `[2..8]`');
    expect(messages(input({ reps: ['memberA'] }))).toContain('part memberB : SwarmMember;');
    expect(messages(input({ links: [] }))).toContain('interface peerLink : Common::MeshLink');
  });

  it('does not take a connection from a member to itself for a peer link', () => {
    const self: ConnectionView = { name: 'loop', type: 'MeshLink', from: 'memberA::meshOut', to: 'memberA::meshIn', metaclass: 'InterfaceUsage' };
    expect(messages(input({ links: [self] }))).toContain('no link between two members');
  });

  it('wants the peer interface at LA', () => {
    const wrong: ConnectionView = { name: 'peerLink', type: 'StatusLink', from: 'memberA::meshOut', to: 'memberB::meshIn', metaclass: 'ConnectionUsage' };
    expect(messages(input({ links: [wrong] }))).toContain('Common::MeshLink');
  });

  it('is silent without a population', () => {
    expect(PREDICATES['replicas.memberPair'](input({ def: false }, { brief: { ...brief, population: undefined } }))).toEqual([]);
  });
});

describe('alt.c2Placement', () => {
  it('alternative 1 keeps command and control on the ground', () => {
    const onBoard = input({ allocations: [['issueTasking', 'memberA']] }, { alternative: 1 });
    expect(PREDICATES['alt.c2Placement'](onBoard)[0].message).toContain('`issueTasking` on `memberA`');
    const ground = input({ allocations: [['issueTasking', 'groundCoordinator'], ['handOverSector', 'groundCoordinator'], ['rotateRecharge', 'groundCoordinator']] }, { alternative: 1 });
    expect(PREDICATES['alt.c2Placement'](ground)).toEqual([]);
  });

  it('alternative 1 also keeps the deciding half of coordination on the ground', () => {
    const decided = input({ allocations: [['issueTasking', 'groundCoordinator'], ['handOverSector', 'memberA'], ['rotateRecharge', 'fleet']] }, { alternative: 1 });
    expect(PREDICATES['alt.c2Placement'](decided)[0].message).toContain('2 of 2 coordination function(s) are decided on the members alone');
  });

  it('counts a function by its definition: a member half does not put the definition on board', () => {
    // v4's shape: each member's half on the member, the deciding usage on the ground.
    const actions = [
      { ...action('alphaHandOverSector', 'Coordination'), defName: 'HandOverSector' },
      { ...action('bravoHandOverSector', 'Coordination'), defName: 'HandOverSector' },
      { ...action('handOverSector', 'Coordination'), defName: 'HandOverSector' },
      { ...action('rotateRecharge'), defName: 'RotateRecharge', defKeywords: ['Coordination'] },
      action('issueTasking', 'C2'),
    ];
    const allocations: Array<[string, string]> = [
      ['alphaHandOverSector', 'memberA'],
      ['bravoHandOverSector', 'memberB'],
      ['handOverSector', 'groundCoordinator'],
      ['rotateRecharge', 'groundCoordinator'],
      ['issueTasking', 'groundCoordinator'],
    ];
    const i = input({ actions, allocations }, { alternative: 1 });
    expect(PREDICATES['alt.c2Placement'](i)).toEqual([]);
    expect(PREDICATES['replicas.topology'](i)[0].message).toContain('0 of 3 coordination and command-and-control function(s) on board, 3 on the ground');
    // The same definitions moved on board make alternative 2.
    const moved = allocations.map(([fn, part]): [string, string] => [fn, fn === 'handOverSector' ? 'memberA' : part]);
    expect(PREDICATES['alt.c2Placement'](input({ actions, allocations: moved }, { alternative: 2 }))).toEqual([]);
    expect(PREDICATES['replicas.topology'](input({ actions, allocations: moved }, { alternative: 2 }))[0].message).toContain('1 of 3');
  });

  it('a function only actors perform is neither on board nor on the ground', () => {
    const i = input({ allocations: [['issueTasking', 'operator']] }, { alternative: 1 });
    (i.payloads.layerView as LayerView).parts = [{ name: 'operator', qualifiedName: `${ROOT}::LA::operator`, isActor: true, ports: [], keywords: ['Actor'] }];
    expect(PREDICATES['replicas.topology'](i)[0].message).toContain('1 performed by actors');
  });

  it('alternative 2 puts at least half the coordination on the members, counting nested paths', () => {
    const ground = input({ allocations: [['handOverSector', 'groundCoordinator'], ['rotateRecharge', 'groundCoordinator']] }, { alternative: 2 });
    expect(PREDICATES['alt.c2Placement'](ground)[0].message).toContain('0 of 2');
    const aboard = input({ allocations: [['handOverSector', 'memberA::missionComputer'], ['rotateRecharge', 'groundCoordinator']] }, { alternative: 2 });
    expect(PREDICATES['alt.c2Placement'](aboard)).toEqual([]);
  });

  it('alternative 2 distributes coordination, not command: every C2 function keeps a ground usage', () => {
    // v5's distributed PA: tasking on the duty member alone.
    const onlyAboard = input({ allocations: [['handOverSector', 'memberA'], ['rotateRecharge', 'fleet'], ['issueTasking', 'memberA']] }, { alternative: 2 });
    expect(PREDICATES['alt.c2Placement'](onlyAboard)[0].message).toContain('distributes coordination, not command');
    const copied = input({ allocations: [['handOverSector', 'memberA'], ['rotateRecharge', 'fleet'], ['issueTasking', 'memberA'], ['issueTasking', 'groundCoordinator']] }, { alternative: 2 });
    expect(PREDICATES['alt.c2Placement'](copied)).toEqual([]);
  });

  it('has nothing to say about a third alternative', () => {
    expect(PREDICATES['alt.c2Placement'](input({ allocations: [['issueTasking', 'memberA']] }, { alternative: 3 }))).toEqual([]);
  });
});

describe('functions.coordination and functions.c2', () => {
  it('at SA, each named function exists under its name and carries its tag', () => {
    const sa = (actions: ActionView[]) => {
      const i = input({ actions }, { step: stepById('S21'), layer: 'SA' });
      (i.payloads.layerView as LayerView).layer = 'SA';
      return PREDICATES['functions.coordination'](i).filter((x) => x.blocking).map((x) => x.message).join('\n');
    };
    expect(sa([action('handOverSector', 'Coordination')])).toContain('no function of that name. Add `#Coordination action rotateRecharge');
    expect(sa([action('handOverSector'), action('rotateRecharge', 'Coordination')])).toContain('not tagged: write `#Coordination action handOverSector`');
  });

  it('reads a tag on the definition as the score does', () => {
    const viaDef = input({ actions: [{ ...action('handOverSector'), defKeywords: ['Coordination'] }, action('rotateRecharge', 'Coordination')] }, { step: stepById('S21'), layer: 'SA' });
    (viaDef.payloads.layerView as LayerView).layer = 'SA';
    expect(PREDICATES['functions.coordination'](viaDef).filter((x) => x.blocking)).toEqual([]);
  });

  it('below SA, a function may be renamed but not lost', () => {
    const lost = input({ actions: [action('handOverSectorLocally', 'Coordination')] });
    expect(PREDICATES['functions.coordination'](lost).filter((x) => x.blocking)[0].message).toContain('tags 1');
    expect(PREDICATES['functions.c2'](input({})).filter((x) => x.blocking)).toEqual([]);
  });

});

describe('pa.bearer', () => {
  it('blocks a bearer left an actor at PA, and a PA with no medium connection def', () => {
    const withBearer = { ...brief, population: { ...population, bearer: 'MeshRadio' } };
    const i = input({}, { step: stepById('S41'), layer: 'PA', brief: withBearer });
    (i.payloads.elements as ReturnType<typeof row>[]).push({ ...row('MeshRadio', 'PartDefinition'), qualifiedName: `${ROOT}::PA::MeshRadio` });
    i.tags = { ...noTags, has: (q: string, k: string) => q === `${ROOT}::PA::MeshRadio` && k === 'Actor' };
    const items = PREDICATES['pa.bearer'](i);
    expect(items.map((x) => x.blocking)).toEqual([true, true]);
    expect(items[0].message).toContain('keep it a `#Node part def MeshRadio`');
    expect(items[1].message).toContain('connection def MeshRadioLink');
  });
});
