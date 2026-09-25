/**
 * T-05: the physical layer as something that can fly.
 *
 * What the generator promises is that nothing in the simulation is invented —
 * every number traces to a brief budget or a model element — and that the one
 * thing it does invent, the time compression, is declared everywhere it bites.
 */
import { describe, expect, it } from 'vitest';
import { parse } from 'yaml';
import { sectorGrid, simulationOf, SimulationRefused, type SimulationInput } from '../../src/realization/simulation.ts';

const input = (over: Partial<SimulationInput> = {}): SimulationInput => ({
  root: 'SurveillanceDroneSwarm',
  population: { memberDef: 'SurveillanceDrone', fleetPart: 'fleet', size: 12, bearer: 'MeshRadio' },
  nodes: ['MeshRadio', 'GroundLinkRadio', 'StoredMapsStore', 'RechargePoint', 'GroundStation'],
  memberMachines: [
    { qualifiedName: 'SurveillanceDroneSwarm::PA::SurveillanceDrone::MemberState', name: 'MemberState', states: ['Landed', 'Launching', 'Watching', 'Isolated', 'Recalled', 'OutsideClearance', 'Landing'] },
    { qualifiedName: 'SurveillanceDroneSwarm::PA::SurveillanceDrone::MemberMode', name: 'MemberMode', states: ['Nominal', 'NavigationDegraded', 'SensingDegraded', 'Quarantined'] },
  ],
  coordination: ['handOverSector', 'rotateRecharge', 'redistributeCoverage', 'deconflictMembers', 'relayLink'],
  c2: ['taskMission', 'recallAndLand'],
  rules: [
    { name: 'RecallWins', kind: 'winsUntil', of: 'member' },
    { name: 'ReturnsWhenIsolated', kind: 'canAlwaysReturn', of: 'member' },
  ],
  modes: [{ name: 'NavigationDegraded', of: 'member' }, { name: 'MeshDegraded', of: 'fleet' }],
  budgets: { areaOfInterestKm2: 25, memberFlightEnduranceMinutes: 40, memberRechargeMinutes: 60, fleetSize: 12 },
  measures: [
    { name: 'areaUnderWatchShare', sense: 'max', target: 0.9 },
    { name: 'coverageLossOnMemberLoss', sense: 'min', target: 0.25 },
    { name: 'reportLatencySeconds', sense: 'min', target: 60, unit: 's' },
  ],
  ...over,
});

describe('the world comes from the brief, not from taste', () => {
  it('sizes the area from the area budget and gives every member a sector', () => {
    const { files } = simulationOf(input());
    // 25 km² → 5000 m on a side.
    // 25 km² → 5000 m on a side: the visible ground is the area itself.
    expect(files['world.sdf']).toContain('<size>5000 5000</size>');
    expect(files['world.sdf'].match(/<model name="sector_\d+">/g)).toHaveLength(12);
    expect(files['world.sdf'].match(/<model name="pad_\d+">/g)).toHaveLength(12);
    expect(files['world.sdf']).toContain('ground_station');
    // The grid is as square as twelve allows.
    expect(sectorGrid(12)).toEqual({ columns: 4, rows: 3 });
    expect(sectorGrid(9)).toEqual({ columns: 3, rows: 3 });
  });

  it('leaves out what the model does not have', () => {
    const { files } = simulationOf(input({ nodes: ['MeshRadio'] }));
    expect(files['world.sdf']).not.toContain('ground_station');
    expect(files['world.sdf']).not.toContain('pad_0');
  });
});

describe('the duty cycle, compressed and declared', () => {
  it('scales flight and recharge, and says so in every file that depends on it', () => {
    const { files, assumptions } = simulationOf(input({ timeScale: 10 }));
    const fleet = parse(files['fleet.yaml']) as { duty_cycle: Record<string, unknown> };
    expect(fleet.duty_cycle.flight_seconds).toBe(240); // 40 min / 10
    expect(fleet.duty_cycle.recharge_seconds).toBe(360); // 60 min / 10
    expect(fleet.duty_cycle.time_scale).toBe(10);
    expect((parse(files['scenario.yaml']) as { time_scale: number }).time_scale).toBe(10);
    expect(assumptions[0]).toContain('40 min of flight runs as 240 s');
    expect(JSON.parse(files['trace.json']).timeScale).toBe(10);
  });

  it('runs unscaled when asked, and refuses a scale that is not one', () => {
    expect((parse(simulationOf(input({ timeScale: 1 })).files['fleet.yaml']) as { duty_cycle: { flight_seconds: number } }).duty_cycle.flight_seconds).toBe(2400);
    expect(() => simulationOf(input({ timeScale: 0 }))).toThrow(SimulationRefused);
  });
});

describe('the fleet is in the world, on the ports the fleet file names', () => {
  it('includes one vehicle per member, by the name the runtime will make', () => {
    const { files } = simulationOf(input());
    const includes = files['world.sdf'].match(/<uri>model:\/\/member_\d+<\/uri>/g) ?? [];
    expect(includes).toHaveLength(12);
    // The models themselves are NOT generated here: the stock airframe lives
    // in the runtime image and this generator has never seen it. A wrapper
    // model that merge-included the stock one and overrode the port was tried,
    // and it is inert — the world loads airframes with no autopilot attached,
    // and the only symptom is SITL never receiving a JSON frame.
    expect(Object.keys(files).some((f) => f.startsWith('models/'))).toBe(false);
    const fleet = parse(files['fleet.yaml']) as Record<string, string>;
    expect(fleet.airframe).toBe('iris_with_ardupilot');
    expect(fleet.models_materialised_by).toContain('models.py');
  });

  it('gives the world what an autopilot needs to fly in it', () => {
    const { files } = simulationOf(input());
    const world = files['world.sdf'];
    // Both of these were missing once, and neither failure says anything: the
    // world loads, the vehicles sit there, and SITL never receives a frame.
    expect(world, 'the IMU system: without it the plugin has nothing to send')
      .toContain('gz-sim-imu-system');
    // WP0.3 measured that 2.5 ms already stops the EKF initialising.
    expect(world).toContain('<max_step_size>0.001</max_step_size>');
    // And nothing that costs a render engine while there is nothing to render.
    expect(world, 'the sensors system with no camera in the world')
      .not.toContain('gz-sim-sensors-system');
    // Every pad is near the origin, because a <plane> collision only holds a
    // vehicle up there: spawned 3.5 km out the fleet falls through the floor,
    // arms regardless, and never climbs. Measured.
    const poses = [...world.matchAll(/<uri>model:\/\/member_\d+<\/uri>\s*<pose>(-?[\d.]+) (-?[\d.]+)/g)]
      .map((m) => Math.hypot(Number(m[1]), Number(m[2])));
    expect(poses).toHaveLength(12);
    for (const distance of poses) {
      expect(distance, 'a member starts too far from the origin to rest on the floor')
        .toBeLessThan(200);
    }
  });

  it('tells the runtime where every sector is, matching the world it drew', () => {
    const { files } = simulationOf(input());
    const fleet = parse(files['fleet.yaml']) as {
      sectors: { id: number; centre: [number, number]; size: [number, number] }[];
      watch_altitude_m: number;
    };
    expect(fleet.sectors).toHaveLength(12);
    expect(fleet.watch_altitude_m).toBeGreaterThan(0);
    for (const sector of fleet.sectors) {
      // Inside the area, which is 5000 m on a side centred on the origin.
      expect(Math.abs(sector.centre[0])).toBeLessThan(2500);
      expect(Math.abs(sector.centre[1])).toBeLessThan(2500);
      // And the world draws a model at that very centre, so the picture and
      // the coverage report are talking about the same square.
      expect(files['world.sdf'], `sector ${sector.id}`)
        .toContain(`<model name="sector_${sector.id}"><static>true</static><pose>${sector.centre[0]} ${sector.centre[1]}`);
    }
  });

  it('gives every instance the port its own model listens on', () => {
    const { files } = simulationOf(input());
    const fleet = parse(files['fleet.yaml']) as {
      instances: { id: number; model: string; fdm_port: number; mavlink_port: number }[];
    };
    expect(fleet.instances).toHaveLength(12);
    for (const instance of fleet.instances) {
      // ArduPilot's own convention: instance n is ten ports along.
      expect(instance.fdm_port, `instance ${instance.id}`).toBe(9002 + 10 * instance.id);
      expect(instance.mavlink_port, `instance ${instance.id}`).toBe(5760 + 10 * instance.id);
      // And the world includes the model this instance names, so the runtime
      // has something to materialise against. A mismatch is an aircraft whose
      // two halves never meet, and it looks like a vehicle that will not arm.
      expect(files['world.sdf'], instance.model)
        .toContain(`<uri>model://${instance.model}</uri>`);
    }
    // No two instances share a port.
    expect(new Set(fleet.instances.map((i) => i.fdm_port)).size).toBe(12);
  });

  it('starts every member on a pad, not stacked at the origin', () => {
    const { files } = simulationOf(input());
    const poses = [...files['world.sdf'].matchAll(/<uri>model:\/\/member_\d+<\/uri>\s*<pose>([^<]+)<\/pose>/g)]
      .map((m) => m[1].trim());
    expect(poses).toHaveLength(12);
    expect(new Set(poses).size, 'two members share a starting pose').toBe(12);
  });
});

describe('the duty cycle belongs to the agent, and the file says so', () => {
  it('does not hand the autopilot battery parameters that do nothing', () => {
    const { files } = simulationOf(input());
    const fleet = parse(files['fleet.yaml']) as {
      autopilot_params: Record<string, unknown>;
      charge_model: Record<string, string>;
    };
    // These were generated once, and they were inert: through the JSON backend
    // SITL takes battery state from the simulator, and ardupilot_gazebo sends
    // none, so no BATT_* failsafe can fire. Writing them made the fleet look as
    // though the autopilot enforced the endurance. Measured in WP0.4.
    for (const parameter of Object.keys(fleet.autopilot_params)) {
      expect(parameter, 'an inert battery parameter is back').not.toMatch(/BATT/);
    }
    // The fence does work, and is kept.
    expect(fleet.autopilot_params).toHaveProperty('FENCE_ENABLE', 1);
  });

  it('never claims an autopilot failsafe fires, in any file it writes', () => {
    // The first fix corrected fleet.yaml and the same false claim survived in
    // scenario.yaml, because the test named a file instead of the claim. This
    // checks every artefact, so a third one cannot hide it.
    //
    // It forbids the claim, not the word: saying the failsafe *never* fires is
    // exactly what these files should say, and the first version of this test
    // rejected its own explanation.
    const { files } = simulationOf(input());
    for (const [name, body] of Object.entries(files)) {
      const claims = body.replace(/never fires?/gi, 'DOES NOT FIRE');
      expect(claims, `${name} promises a failsafe that cannot fire`)
        .not.toMatch(/failsafe (fires|will fire|triggers)/i);
      // And no file may set a battery parameter: through the JSON backend they
      // do nothing, and writing them makes the fleet look as though the
      // autopilot enforced the endurance.
      expect(body, `${name} sets a battery parameter the JSON backend ignores`)
        .not.toMatch(/^\s*(SIM_)?BATT_\w+\s*[:=]/m);
    }
  });

  it('names who owns charge, and what it does not demonstrate', () => {
    const { files } = simulationOf(input());
    const fleet = parse(files['fleet.yaml']) as { charge_model: Record<string, string> };
    expect(fleet.charge_model.owner).toContain('rotateRecharge');
    expect(fleet.charge_model.why_not_the_autopilot).toContain('JSON backend');
    // A demonstration that cannot run a battery flat says so where a reader
    // will find it, not only in a report nobody opens.
    expect(fleet.charge_model.not_exercised).toContain('never runs out of power');
    expect(files['fleet.yaml']).not.toContain("autopilot's own failsafe fires");
  });
});

describe('what the runtime is told', () => {
  it('maps every state of every member machine, and marks the ones no flight mode fits', () => {
    const { files } = simulationOf(input());
    // Parsed, not grepped: a value like ">= 0.9" or a description with a colon
    // in it made the first hand-written version of these files unparseable.
    const mapping = parse(files['mapping.yaml']) as {
      states: Array<{ state: string; of: string; autopilot: string | null; kind: string }>;
      coordination_behaviours: string[];
      rules_to_monitor: Array<{ rule: string; kind: string; of: string }>;
      measures: Array<{ measure: string; target: string }>;
    };
    expect(mapping.states).toHaveLength(11);
    expect(mapping.states.find((r) => r.state === 'Recalled')).toMatchObject({ autopilot: 'RTL', kind: 'flight mode' });
    // A condition an agent carries is not a flight mode, and it says so.
    expect(mapping.states.find((r) => r.state === 'SensingDegraded')).toMatchObject({ autopilot: null, kind: 'agent condition', of: expect.stringContaining('MemberMode') });
    expect(mapping.coordination_behaviours).toContain('SurveillanceDroneSwarm::PA::handOverSector');
    expect(mapping.rules_to_monitor).toContainEqual({ rule: 'RecallWins', kind: 'winsUntil', of: 'member' });
    // The target is the brief's and the sense says which way round it reads;
    // an estimate rides along when the architecture stated one.
    expect(mapping.measures).toContainEqual(
      expect.objectContaining({ measure: 'areaUnderWatchShare', target: '>= 0.9', sense: 'max' }),
    );
    expect(mapping.measures).toContainEqual(
      expect.objectContaining({ measure: 'coverageLossOnMemberLoss', target: '<= 0.25', sense: 'min' }),
    );
  });

  it('writes the forerunner scenario: two cycles, then a member lost', () => {
    const scenario = parse(simulationOf(input()).files['scenario.yaml']) as {
      name: string;
      duration_seconds: number;
      timeline: Array<{ at: number; event: string; detail: string }>;
      acceptance: Array<Record<string, string>>;
    };
    expect(scenario.name).toBe('rotation-and-loss');
    expect(scenario.duration_seconds).toBe(1200); // (240 + 360) × 2
    expect(scenario.timeline.map((t) => t.event)).toEqual(['SurveillanceDroneSwarm::PA::taskMission', 'first rotation', 'member lost']);
    expect(scenario.timeline[2].detail).toContain('redistributeCoverage');
    expect(scenario.acceptance).toContainEqual(expect.objectContaining({ measure: 'areaUnderWatchShare', target: '>= 0.9' }));
  });

  it('writes YAML a runtime can actually read, and XML a parser accepts', () => {
    const { files } = simulationOf(input());
    for (const name of ['fleet.yaml', 'mapping.yaml', 'scenario.yaml']) {
      expect(() => parse(files[name]), name).not.toThrow();
      expect(parse(files[name]), name).toBeTypeOf('object');
    }
    // The world is SDF: one well-formed document with a single <world>.
    const world = files['world.sdf'];
    expect(world.startsWith('<?xml version="1.0" ?>')).toBe(true);
    expect((world.match(/<world /g) ?? []).length).toBe(1);
    expect((world.match(/<model /g) ?? []).length).toBe((world.match(/<\/model>/g) ?? []).length);
  });
});

describe('every artefact says where it came from', () => {
  it('traces each file to the elements it was generated from', () => {
    const { files, trace } = simulationOf(input());
    expect(trace.map((t) => t.file).sort()).toEqual(['fleet.yaml', 'mapping.yaml', 'scenario.yaml', 'world.sdf']);
    for (const entry of trace) {
      expect(entry.from.length, entry.file).toBeGreaterThan(0);
      for (const name of entry.from) expect(name, entry.file).toContain('SurveillanceDroneSwarm::');
    }
    expect(Object.keys(files).sort()).toEqual(['fleet.yaml', 'mapping.yaml', 'scenario.yaml', 'trace.json', 'world.sdf']);
    const world = trace.find((t) => t.file === 'world.sdf')!;
    expect(world.from).toContain('SurveillanceDroneSwarm::Common::areaOfInterestKm2');
  });
});

describe('what it refuses', () => {
  it('will not fly a brief with no population', () => {
    expect(() => simulationOf(input({ population: undefined }))).toThrow(/no population/);
  });

  it('will not guess a budget the brief does not fix', () => {
    expect(() => simulationOf(input({ budgets: { fleetSize: 12 } }))).toThrow(/areaOfInterestKm2/);
    expect(() => simulationOf(input({ budgets: { areaOfInterestKm2: 25, fleetSize: 12, memberFlightEnduranceMinutes: 40 } }))).toThrow(/memberRechargeMinutes/);
  });
});
