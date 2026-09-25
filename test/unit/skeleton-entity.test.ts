/**
 * The OA part the brief means by `systemEntity`, even when the names drifted.
 */
import { describe, expect, it } from 'vitest';
import { generateSkeleton, resolveSystemEntity } from '../../src/transition/skeleton.ts';
import type { LayerView, PartView } from '../../src/transition/view.ts';

const part = (name: string, defName: string, isActor = false): PartView => ({
  name,
  qualifiedName: `Swarm::OA::${name}`,
  def: `OA::${defName}`,
  defName,
  isActor,
  ports: [],
  keywords: isActor ? ['Actor'] : [],
});

const view = (parts: PartView[], allocations: Array<[string, string]>): LayerView => ({
  root: 'Swarm',
  layer: 'OA',
  actions: allocations.map(([action]) => ({ name: action, qualifiedName: `Swarm::OA::${action}`, params: [], keywords: [] })),
  parts,
  partDefs: [],
  useCases: [],
  states: [],
  flows: [],
  connections: [],
  successions: [],
  allocations: allocations.map(([action, p]) => ({ action: `Swarm::OA::${action}`, actionName: action, part: `Swarm::OA::${p}`, partName: p })),
});

describe('resolveSystemEntity', () => {
  it('takes the exact name when OA used it', () => {
    const v = view([part('authority', 'Authority'), part('train', 'Train', true)], [['close', 'authority']]);
    expect(resolveSystemEntity(v, 'authority')).toEqual({ name: 'authority', defName: 'Authority', substituted: false });
  });

  it('falls back to the part carrying the activities, actor-tagged or not', () => {
    // The third run: the brief said surveillanceAsset, OA wrote #Actor watchAsset.
    const v = view(
      [part('opsCentre', 'OperationsCentre', true), part('watchAsset', 'WatchAsset', true)],
      [['holdWatch', 'watchAsset'], ['recharge', 'watchAsset'], ['issueTasking', 'opsCentre']],
    );
    const r = resolveSystemEntity(v, 'surveillanceAsset');
    expect(r.name).toBe('watchAsset');
    expect(r.substituted).toBe(true);
  });

  it('allocates every activity of every representative member to the system', () => {
    // A population: two representatives of one member definition.
    const v = view(
      [part('droneA', 'Drone'), part('droneB', 'Drone'), part('opsCentre', 'OperationsCentre', true)],
      [['handOver', 'droneA'], ['takeOver', 'droneB'], ['issueTasking', 'opsCentre']],
    );
    const s = generateSkeleton({ rule: 'T01', from: v, root: 'Swarm', systemName: 'Swarm', systemEntity: 'droneA', memberDef: 'Drone' });
    expect(s.text).toContain('allocate handOver to system;');
    expect(s.text).toContain('allocate takeOver to system;');
    expect(s.text).toContain('allocate issueTasking to opsCentre;');
    expect(s.text).not.toContain('part droneB :');
    expect(s.carried.actors).toBe(1);
  });

  it('counts representatives typed by the operation\'s own definition, not only the member definition', () => {
    const v = view(
      [part('watchAssetA', 'WatchAsset'), part('watchAssetB', 'WatchAsset'), part('opsCentre', 'OperationsCentre', true)],
      [['handOverSector', 'watchAssetA'], ['takeOverSector', 'watchAssetB']],
    );
    const s = generateSkeleton({ rule: 'T01', from: v, root: 'Swarm', systemName: 'Swarm', systemEntity: 'watchAssetA', memberDef: 'SwarmMember' });
    expect(s.text).toContain('allocate takeOverSector to system;');
    expect(s.text).not.toContain('part watchAssetB :');
  });

  it('T-04 procures a population once, with its multiplicity, and not its representatives', () => {
    const pa = view([], []);
    pa.layer = 'PA';
    pa.parts = [
      { ...part('fleet', 'SwarmMember'), qualifiedName: 'Swarm::PA::fleet', multiplicity: '12' },
      { ...part('memberA', 'SwarmMember'), qualifiedName: 'Swarm::PA::memberA' },
      { ...part('memberB', 'SwarmMember'), qualifiedName: 'Swarm::PA::memberB' },
      { ...part('groundStation', 'GroundStation'), qualifiedName: 'Swarm::PA::groundStation' },
    ];
    const s = generateSkeleton({ rule: 'T04', from: pa, root: 'Swarm', systemName: 'Swarm' });
    expect(s.text).toContain('part fleetCi : FleetItem [12];');
    expect(s.text).toContain('part groundStationCi : GroundStationItem;');
    expect(s.text).not.toContain('memberACi');
    expect(s.carried.parts).toBe(2);
  });

  it('T-03 writes the brief\'s bearer as a #Node, and leaves other actors actors', () => {
    const la: LayerView = { ...view([part('mainComponent', 'SwarmLogical'), part('meshRadio', 'MeshRadio', true), part('operator', 'Operator', true)], []), layer: 'LA' };
    const population = { memberDef: 'SwarmDrone', fleetPart: 'fleet', size: 12, meshPort: 'MeshPort', meshInterface: 'MeshLink', bearer: 'MeshRadio' };
    const pa = generateSkeleton({ rule: 'T03', from: la, root: 'Swarm', systemName: 'Swarm', population }).text;
    expect(pa).toContain('#Node part def MeshRadio {');
    expect(pa).not.toContain('#Actor part def MeshRadio');
    expect(pa).toContain('#Actor part def Operator {');
    // At LA the radio is still the environment.
    const laSkeleton = generateSkeleton({ rule: 'T02', from: { ...la, layer: 'SA' }, root: 'Swarm', systemName: 'Swarm', population }).text;
    expect(laSkeleton).toContain('#Actor part def MeshRadio {');
  });
});
