/**
 * T-05 — the model, as something that can fly.
 *
 * The four layer transitions turn one layer into the next. This one turns the
 * physical layer into a simulation: a Gazebo world sized by the brief's own
 * area budget, one autopilot instance per member of the population, a scenario
 * timeline, and the two mappings a runtime needs — model state to autopilot
 * mode, coordination function to agent behaviour.
 *
 * Two rules make it a transition rather than a demo script:
 *
 *  - **Nothing is invented.** Every number comes from the model: the area, the
 *    fleet size, the flight and recharge minutes are brief budgets; the sectors
 *    come from the fleet; the states and the rules are the ones the checker
 *    walked. What the model does not say, this refuses to say either.
 *  - **Everything is traceable.** Each generated artefact carries the qualified
 *    name of the element it came from, collected into `trace.json`, so the
 *    demonstration can be read back against the model it claims to show.
 *
 * Time is the one thing the simulation may not take from the model: a 40/60
 * minute duty cycle is unwatchable. It is scaled by a declared factor, and the
 * factor is written into every file that depends on it and into the trace, so a
 * simulated measure is never compared with an unscaled target by accident.
 */

import { stringify } from 'yaml';

/** One member state machine, as the model declares it. */
export interface MachineView {
  /** `Root::PA::SurveillanceDrone::MemberState` */
  qualifiedName: string;
  name: string;
  states: readonly string[];
}

export interface SimulationInput {
  root: string;
  /** The population the brief declares; without one there is nothing to fly. */
  population?: { memberDef: string; fleetPart: string; size: number; bearer?: string };
  /** `#Node` part definitions at PA — the things built or bought. */
  nodes: readonly string[];
  /** The member's state machines at PA, with their states. */
  memberMachines: readonly MachineView[];
  /** What the members settle between themselves, by name. */
  coordination: readonly string[];
  /** What the operator exercises, by name. */
  c2: readonly string[];
  /** The rules the system never breaks. */
  rules: readonly { name: string; kind: string; of: string }[];
  /** The operating modes the brief names. */
  modes: readonly { name: string; of: string }[];
  /** Brief budgets by name, e.g. `areaOfInterestKm2` → 25. */
  budgets: Readonly<Record<string, number>>;
  /** The scored measures, with the targets a run is held to. */
  measures: readonly {
    name: string; sense: 'min' | 'max'; target: number; unit?: string;
    /** What the architecture estimates for this measure; null when derived. */
    estimate?: number | null;
  }[];
  /** Wall-clock compression. 10 turns a 40-minute flight into 4 minutes. */
  timeScale?: number;
}

/** One generated artefact, and the model elements it was made from. */
export interface TraceEntry {
  file: string;
  what: string;
  from: readonly string[];
}

export interface SimulationOutput {
  /** File name → contents, all relative to the simulation directory. */
  files: Record<string, string>;
  trace: readonly TraceEntry[];
  /** What the generator had to assume, for the report to print. */
  assumptions: readonly string[];
}

const BUDGETS = {
  area: 'areaOfInterestKm2',
  endurance: 'memberFlightEnduranceMinutes',
  recharge: 'memberRechargeMinutes',
  fleet: 'fleetSize',
  speed: 'memberCruiseSpeedMps',
} as const;

/**
 * What a member's cruise speed is taken to be when the brief fixes none.
 *
 * Flown at v7's numbers the return leg alone cost 142–306 s of a 240 s budget,
 * so this number decides more than it looks like it does. It is declared in
 * `fleet.yaml` and in the run's assumptions rather than buried here.
 */
const ASSUMED_CRUISE_SPEED = 15;

/**
 * SITL instance `n` binds its JSON backend here and speaks MAVLink ten ports
 * later; the vehicle model's own `fdm_port_in` has to agree, or the two halves
 * of an aircraft never meet. The stride is ArduPilot's, not a choice.
 */
const FDM_PORT_BASE = 9002;
const MAVLINK_PORT_BASE = 5760;
const PORT_STRIDE = 10;

export class SimulationRefused extends Error {}

/** The sector grid: one sector per member, as square as the count allows. */
export function sectorGrid(size: number): { columns: number; rows: number } {
  const columns = Math.ceil(Math.sqrt(size));
  return { columns, rows: Math.ceil(size / columns) };
}

const round = (n: number, places = 2): number => Number(n.toFixed(places));

/** The model directory for member `i`; the world includes it by this name. */
const vehicleModelName = (i: number): string => `member_${i}`;

/**
 * The simulation of one run.
 *
 * Refuses a brief with no population: a swarm demonstration of one drone is a
 * different thing, and pretending otherwise would be the generator inventing
 * the very fact the brief withheld.
 */
export function simulationOf(input: SimulationInput): SimulationOutput {
  const p = input.population;
  if (!p) throw new SimulationRefused('the brief declares no population: there is no fleet to fly, and T-05 will not invent one');
  const scale = input.timeScale ?? 10;
  if (scale <= 0) throw new SimulationRefused(`a time scale of ${scale} is not a compression`);

  const areaKm2 = input.budgets[BUDGETS.area];
  const enduranceMin = input.budgets[BUDGETS.endurance];
  const rechargeMin = input.budgets[BUDGETS.recharge];
  // The speed is not among these: a brief that fixes one is better, and a
  // brief that does not still has a world and a duty cycle. It is assumed and
  // declared instead of refused.
  const required = [BUDGETS.area, BUDGETS.endurance, BUDGETS.recharge, BUDGETS.fleet];
  const missing = required.filter((b) => typeof input.budgets[b] !== 'number');
  if (missing.length > 0) throw new SimulationRefused(`the brief fixes no ${missing.join(', ')}: the world and the duty cycle would be guesses`);

  const side = round(Math.sqrt(areaKm2) * 1000, 0); // metres
  const { columns, rows } = sectorGrid(p.size);
  const sectorWidth = round(side / columns, 1);
  const sectorHeight = round(side / rows, 1);
  const flightSeconds = round((enduranceMin * 60) / scale, 0);
  const rechargeSeconds = round((rechargeMin * 60) / scale, 0);
  const assumptions: string[] = [
    `time scale ${scale}: ${enduranceMin} min of flight runs as ${flightSeconds} s, ${rechargeMin} min of recharge as ${rechargeSeconds} s`,
    `${p.size} sectors, one per member, on a ${columns}×${rows} grid over ${side} m × ${side} m (${areaKm2} km²)`,
    ...(input.budgets[BUDGETS.speed] === undefined
      ? [`cruise speed ${ASSUMED_CRUISE_SPEED} m/s: the brief fixes none, and the transit to a station is most of what a flight budget buys at this scale`]
      : []),
  ];

  const trace: TraceEntry[] = [];
  const files: Record<string, string> = {};

  /* ── world.sdf ─────────────────────────────────────────────────────────── */
  // The pads and the ground station sit at the centre of the watched area, not
  // in a corner. Two reasons, and the second is the one that forced it.
  //
  // It is the better placement: members return from their sectors to recharge,
  // and the centre is the shortest worst-case transit from any of them.
  //
  // And a <plane> collision in Gazebo only generates contact near the world
  // origin — the declared size does not extend it, measured by enlarging the
  // plane threefold and watching the fleet fall through it anyway. Vehicles
  // spawned 3.5 km out fall forever, arm regardless, and never climb. A box
  // holds them anywhere and costs three times the real-time factor with twelve
  // vehicles resting on it. Putting the pads where the floor works keeps the
  // cheap shape and loses nothing the model asked for.
  const padColumns = Math.ceil(Math.sqrt(p.size));
  const padSpacing = 12;
  const pads = Array.from({ length: p.size }, (_, i) => {
    const x = round((i % padColumns) * padSpacing - ((padColumns - 1) * padSpacing) / 2, 1);
    const y = round(
      Math.floor(i / padColumns) * padSpacing - ((Math.ceil(p.size / padColumns) - 1) * padSpacing) / 2,
      1,
    );
    return { i, x, y };
  });
  files['world.sdf'] = [
    '<?xml version="1.0" ?>',
    '<!-- Generated by T-05 from the physical layer. Do not edit: regenerate. -->',
    '<sdf version="1.9">',
    `  <world name="${input.root.toLowerCase()}_watch_area">`,
    '    <!-- 1 ms, measured: at 2.5 ms no autopilot ever initialises its EKF and',
    '         every arm is refused, at four vehicles or at twelve (WP0.3). The',
    '         autopilot needs the kilohertz IMU this step delivers. -->',
    '    <physics name="1ms" type="ignored"><max_step_size>0.001</max_step_size><real_time_factor>1.0</real_time_factor></physics>',
    '    <plugin filename="gz-sim-physics-system" name="gz::sim::systems::Physics"/>',
    '    <!-- Not optional: the ArduPilot plugin reads the member IMU and sends it',
    '         to SITL. Without this system the sensor produces nothing, the plugin',
    '         has nothing to send, and the only symptom is that SITL never',
    '         receives a JSON frame — twelve airframes sit in a world doing',
    '         nothing and no error is printed anywhere. -->',
    '    <plugin filename="gz-sim-imu-system" name="gz::sim::systems::Imu"/>',
    '    <!-- No sensors system: this world carries no camera, and that plugin',
    '         initialises the render engine whether or not there is anything to',
    '         draw. WP4 adds it back together with the camera it needs. -->',
    '    <plugin filename="gz-sim-user-commands-system" name="gz::sim::systems::UserCommands"/>',
    '    <plugin filename="gz-sim-scene-broadcaster-system" name="gz::sim::systems::SceneBroadcaster"/>',
    '    <!-- Where on Earth the area is. Gazebo needs a geodetic origin for the',
    '         autopilot to have a home at all; the reference worlds all carry one',
    '         and the brief does not say where, so this is the stock SITL home. -->',
    '    <spherical_coordinates><latitude_deg>-35.363262</latitude_deg><longitude_deg>149.165237</longitude_deg>',
    '      <elevation>584</elevation><heading_deg>0</heading_deg><surface_model>EARTH_WGS84</surface_model></spherical_coordinates>',
    '    <light type="directional" name="sun"><direction>-0.5 0.1 -0.9</direction><diffuse>1 1 1 1</diffuse><cast_shadows>true</cast_shadows></light>',
    `    <!-- the tasked area: ${BUDGETS.area} = ${areaKm2} km² -->`,
    '    <!-- The floor holds vehicles near the origin, which is where the pads',
    '         are put. Enlarging this plane does not extend where it works. -->',
    `    <model name="ground"><static>true</static><link name="link">`,
    `      <collision name="c"><geometry><plane><normal>0 0 1</normal><size>${side} ${side}</size></plane></geometry>`,
    '        <surface><friction><ode><mu>1.0</mu><mu2>1.0</mu2></ode></friction></surface></collision>',
    `      <visual name="v"><geometry><plane><normal>0 0 1</normal><size>${side} ${side}</size></plane></geometry>`,
    '        <material><ambient>0.29 0.33 0.29 1</ambient></material></visual></link></model>',
    ...Array.from({ length: columns * rows }).flatMap((_, s) => {
      const cx = round(-side / 2 + sectorWidth * (0.5 + (s % columns)), 1);
      const cy = round(-side / 2 + sectorHeight * (0.5 + Math.floor(s / columns)), 1);
      return s < p.size
        ? [
            `    <!-- sector ${s + 1} of ${p.size}: one member watches it -->`,
            `    <model name="sector_${s + 1}"><static>true</static><pose>${cx} ${cy} 0.05 0 0 0</pose><link name="link">`,
            `      <visual name="v"><geometry><box><size>${sectorWidth - 4} ${sectorHeight - 4} 0.1</size></box></geometry>`,
            '        <material><ambient>0.10 0.43 0.40 0.25</ambient><diffuse>0.10 0.43 0.40 0.25</diffuse></material></visual></link></model>',
          ]
        : [];
    }),
    ...(input.nodes.includes('GroundStation')
      ? [
          '    <!-- PA::GroundStation -->',
          `    <model name="ground_station"><static>true</static><pose>${round(padColumns * padSpacing, 1)} 0 0 0 0 0</pose>`,
          '      <link name="link"><visual name="v"><geometry><box><size>6 6 3</size></box></geometry>',
          '        <material><ambient>0.27 0.35 0.42 1</ambient></material></visual></link></model>',
        ]
      : []),
    ...(input.nodes.includes('RechargePoint')
      ? pads.flatMap(({ i, x, y }) => [
          `    <!-- PA::RechargePoint, pad ${i} -->`,
          `    <model name="pad_${i}"><static>true</static><pose>${x} ${y} 0.02 0 0 0</pose><link name="link">`,
          '      <visual name="v"><geometry><cylinder><radius>1.2</radius><length>0.04</length></cylinder></geometry>',
          '        <material><ambient>0.72 0.28 0.06 1</ambient></material></visual></link></model>',
        ])
      : []),
    '    <!-- the fleet: one vehicle per member, each on its own pad and its own',
    '         FDM port. The airframe is the stock ardupilot_gazebo quad; what',
    '         the model fixes is how many there are and where they start. -->',
    ...pads.flatMap(({ i, x, y }) => [
      `    <include>`,
      `      <uri>model://${vehicleModelName(i)}</uri>`,
      `      <pose>${x} ${y} 0.195 0 0 0</pose>`,
      '    </include>',
    ]),
    '  </world>',
    '</sdf>',
    '',
  ].join('\n');
  // The per-member model directories are NOT written here, and the reason is
  // worth stating: the stock airframe lives in the runtime image
  // (`/opt/ardupilot_gazebo/models/iris_with_ardupilot`), and this generator
  // runs on a host that has never seen it. A wrapper model that merge-includes
  // the stock one and overrides `fdm_port_in` was tried and is inert — the
  // world loads twelve airframes that no autopilot is attached to, and the only
  // symptom is that SITL never receives a JSON frame. So the world names the
  // models and `fleet.yaml` fixes their ports, and the runtime materialises
  // them from the airframe it can actually see (`sim/runtime/models.py`).
  trace.push({
    file: 'world.sdf',
    what: `a ${side} m square with ${p.size} sectors, ${input.nodes.includes('RechargePoint') ? `${p.size} recharge pads` : 'no pads'}, the ground station, and ${p.size} vehicles on their pads`,
    from: [
      `${input.root}::Common::${BUDGETS.area}`,
      `${input.root}::Common::${BUDGETS.fleet}`,
      `${input.root}::PA::${p.memberDef}`,
      `${input.root}::PA::${p.fleetPart}`,
      ...input.nodes.filter((n) => n === 'GroundStation' || n === 'RechargePoint').map((n) => `${input.root}::PA::${n}`),
    ],
  });

  /* ── fleet.yaml ────────────────────────────────────────────────────────── */
  // Built as a document and serialised by `yaml`, not printed as lines: a value
  // like ">= 0.9" or a mode description with a colon in it makes hand-written
  // YAML unparseable, which is exactly what the first draft of this did.
  const header = (lines: readonly string[]): string => lines.map((l) => `# ${l}`).join('\n');
  files['fleet.yaml'] = `${header([
    'Generated by T-05. One autopilot instance per member of the population.',
    'The duty cycle belongs to the coordination agent, not to the autopilot:',
    'through Gazebo the autopilot flies an external FDM, and SITL then takes',
    'battery state from the simulator rather than modelling it, so its own',
    'low-battery failsafe never fires (measured: WP0.4 in the plan). That suits',
    'the architecture — rotateRecharge is a #Coordination function allocated to',
    'the coordination node, so charge accounting belongs in that agent.',
  ])}\n${stringify({
    member_definition: `${input.root}::PA::${p.memberDef}`,
    fleet_usage: `${input.root}::PA::${p.fleetPart}`,
    size: p.size,
    size_from: BUDGETS.fleet,
    representatives: ['memberA', 'memberB'],
    // The airframe is the runtime's, not the model's: the architecture fixes
    // how many vehicles there are and where they start, not what a quadcopter
    // is. The runtime copies this one per instance and sets the port below.
    airframe: 'iris_with_ardupilot',
    models_materialised_by: 'sim/runtime/models.py, from fleet.yaml, inside the runtime image',
    ...(p.bearer ? { peer_bearer: p.bearer } : {}),
    duty_cycle: {
      flight_seconds: flightSeconds,
      flight_from: `${BUDGETS.endurance} = ${enduranceMin} min / ${scale}`,
      recharge_seconds: rechargeSeconds,
      recharge_from: `${BUDGETS.recharge} = ${rechargeMin} min / ${scale}`,
      time_scale: scale,
    },
    // Only parameters that take effect through the JSON backend. The battery
    // ones were here and did nothing: writing them made the fleet look as
    // though the autopilot enforced the endurance, and it does not.
    autopilot_params: {
      FENCE_ENABLE: 1,
      FENCE_RADIUS: round(side / 2, 0),
    },
    // Whoever runs the fleet owns the duty cycle. The numbers are the ones
    // above, and they trace to brief budgets, so an agent never carries a
    // flight time of its own.
    charge_model: {
      owner: `${input.root}::PA::rotateRecharge`,
      rule: 'charge = flight_seconds elapsed since launch, against duty_cycle.flight_seconds',
      recall_at: 'the reserve share the agent is configured with, of flight_seconds',
      why_not_the_autopilot:
        'SITL takes battery state from the simulator over the JSON backend and ' +
        'ardupilot_gazebo sends none, so BATT_* failsafes never fire — measured, not assumed',
      not_exercised: 'the simulated vehicle never runs out of power; this demonstrates the rotation, not an energy margin',
    },
    // Where each sector is. The agents fly to these, the coverage metric is
    // computed over them, and they are the same centres the world draws — so a
    // sector in the picture and a sector in the report are one thing.
    sectors: Array.from({ length: p.size }, (_, s) => ({
      id: s + 1,
      centre: [
        round(-side / 2 + sectorWidth * (0.5 + (s % columns)), 1),
        round(-side / 2 + sectorHeight * (0.5 + Math.floor(s / columns)), 1),
      ],
      size: [sectorWidth, sectorHeight],
    })),
    watch_altitude_m: 60,
    // How fast a member transits. The brief fixes this when it states one, and
    // when it does not this is an assumption — declared here and in
    // `assumptions`, because the transit to a station is most of what a flight
    // budget buys at this area's scale and a silent default would decide it.
    cruise_speed_mps: input.budgets[BUDGETS.speed] ?? ASSUMED_CRUISE_SPEED,
    cruise_speed_from:
      input.budgets[BUDGETS.speed] !== undefined
        ? BUDGETS.speed
        : `assumed: the brief states no cruise speed, so ${ASSUMED_CRUISE_SPEED} m/s is this generator's, not the model's`,
    // A member counts as on station when it is within this of its sector's
    // centre. Before that it is still getting there, and it is not watching.
    arrival_radius_m: 75,
    instances: pads.map(({ i, x, y }) => ({
      id: i,
      name: i === 0 ? 'memberA' : i === 1 ? 'memberB' : `member${i}`,
      sector: i + 1,
      home: [x, y, 0],
      // Written here so the runtime reads them rather than recomputing a
      // convention: the world's models were generated against these.
      model: vehicleModelName(i),
      fdm_port: FDM_PORT_BASE + PORT_STRIDE * i,
      mavlink_port: MAVLINK_PORT_BASE + PORT_STRIDE * i,
    })),
  })}`;
  trace.push({
    file: 'fleet.yaml',
    what: `${p.size} instances, the duty cycle and the geofence`,
    from: [`${input.root}::PA::${p.memberDef}`, `${input.root}::PA::${p.fleetPart}`, `${input.root}::Common::${BUDGETS.endurance}`, `${input.root}::Common::${BUDGETS.recharge}`],
  });

  /* ── mapping.yaml ──────────────────────────────────────────────────────── */
  const MODE_OF_STATE: Record<string, string> = {
    Landed: 'on the ground, disarmed',
    Launching: 'GUIDED, climbing to the watch altitude',
    Watching: 'AUTO, flying its sector pattern',
    Recalled: 'RTL',
    Landing: 'LAND',
    Isolated: 'AUTO, no peer traffic accepted',
    OutsideClearance: 'RTL, fence breach',
  };
  const stateRows = input.memberMachines.flatMap((machine) =>
    machine.states.map((state) => ({
      state,
      of: machine.qualifiedName,
      autopilot: MODE_OF_STATE[state] ?? null,
      // A condition an agent carries is not a flight mode, and the runtime has
      // to report which it is rather than claim a state it never entered.
      kind: MODE_OF_STATE[state] ? 'flight mode' : 'agent condition',
    })),
  );
  const bound = (mm: SimulationInput['measures'][number]): string =>
    `${mm.sense === 'max' ? '>=' : '<='} ${mm.target}${mm.unit ? ` ${mm.unit}` : ''}`;
  files['mapping.yaml'] = `${header([
    'Generated by T-05: how the model reads on a real autopilot.',
    'A state with no flight mode is a condition an agent carries, not a gap.',
  ])}\n${stringify({
    states: stateRows,
    coordination_behaviours: input.coordination.map((f) => `${input.root}::PA::${f}`),
    operator_events: input.c2.map((f) => `${input.root}::PA::${f}`),
    rules_to_monitor: input.rules.map((r) => ({ rule: r.name, kind: r.kind, of: r.of })),
    modes_the_brief_names: input.modes.map((m) => ({ mode: m.name, of: m.of })),
    // The target is the brief's; the estimate is the architecture's claim for
    // it. Both travel with the measure so the report can put them beside the
    // simulated value without going back to the model.
    measures: input.measures.map((mm) => ({
      measure: mm.name,
      target: bound(mm),
      sense: mm.sense,
      ...(mm.estimate === undefined
        ? {}
        : { estimate: mm.estimate, estimate_kind: mm.estimate === null ? 'derived' : 'stated' }),
    })),
  })}`;
  trace.push({
    file: 'mapping.yaml',
    what: `${stateRows.length} states, ${input.coordination.length} coordination functions, ${input.rules.length} rules, ${input.measures.length} measures`,
    from: [
      ...input.memberMachines.map((m) => m.qualifiedName),
      ...input.coordination.map((f) => `${input.root}::PA::${f}`),
      ...input.rules.map((r) => `${input.root}::SA::${r.name}`),
    ],
  });

  /* ── scenario.yaml ─────────────────────────────────────────────────────── */
  const cycles = 2;
  const runSeconds = (flightSeconds + rechargeSeconds) * cycles;
  const coverageMeasures = input.measures.filter((mm) => ['areaUnderWatchShare', 'coverageLossOnMemberLoss'].includes(mm.name));
  files['scenario.yaml'] = `${header([
    'Generated by T-05 — the forerunner scenario: hold the watch through a',
    'recharge rotation, then lose one member and re-spread.',
  ])}\n${stringify({
    name: 'rotation-and-loss',
    duration_seconds: runSeconds,
    time_scale: scale,
    timeline: [
      {
        at: 0,
        event: input.c2.includes('taskMission') ? `${input.root}::PA::taskMission` : 'mission start',
        detail: `task the area, ${p.size} sectors, one member each`,
      },
      {
        at: round(flightSeconds * 0.8, 0),
        event: 'first rotation',
        detail: `members reaching the reserve share of their flight budget hand their sector over (${input.root}::PA::handOverSector) and recharge (${input.root}::PA::rotateRecharge)`,
      },
      // The rules the model states have to be put to the test, or their
      // monitors report nothing and a rule nobody exercised reads as a rule
      // that held. One event each for the two the forerunner otherwise leaves
      // untouched.
      ...(input.rules.some((r) => /quarantin/i.test(r.name))
        ? [{
            at: round(flightSeconds * 1.2, 0),
            event: 'member quarantined',
            detail: `a member fails admission (${input.root}::PA::admitMember) and takes no further part in coordination`,
          }]
        : []),
      ...(input.rules.some((r) => /geofence|clearance/i.test(r.name))
        ? [{
            at: round(flightSeconds * 1.6, 0),
            event: 'clearance breached',
            detail: 'a member leaves its cleared airspace and must stop watching until it has landed',
          }]
        : []),
      {
        at: round(runSeconds * 0.6, 0),
        event: 'member lost',
        detail: `kill one airborne instance; the rest re-spread (${input.root}::PA::redistributeCoverage)`,
      },
    ],
    acceptance: [
      ...coverageMeasures.map((mm) => ({
        measure: mm.name,
        target: bound(mm),
        note: "the brief's target; the architecture's own estimate is in audit/final",
      })),
      { rule: 'no sector is unwatched for longer than one handover' },
    ],
  })}`;
  trace.push({
    file: 'scenario.yaml',
    what: `${cycles} duty cycles and one member lost, held to the coverage measures`,
    from: [
      ...['handOverSector', 'rotateRecharge', 'redistributeCoverage'].filter((f) => input.coordination.includes(f)).map((f) => `${input.root}::PA::${f}`),
      ...coverageMeasures.map((mm) => `${input.root}::Common::${mm.name}`),
    ],
  });

  files['trace.json'] = `${JSON.stringify({ root: input.root, timeScale: scale, assumptions, artefacts: trace }, null, 2)}\n`;
  return { files, trace, assumptions };
}
