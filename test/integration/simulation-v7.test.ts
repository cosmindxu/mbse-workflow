/**
 * T-05 against a model a swarm run actually produced.
 *
 * `test/unit/simulation.test.ts` exercises the generator against a fixture the
 * test wrote, which proves the generator and nothing about the models it is
 * for. This runs the adapter on `examples/drone-swarm-v7` — a real run, kept
 * under version control for exactly this — and asserts the claims the plan's
 * mapping table makes: that every row of it has a source element, that the
 * generator refuses nothing on a complete brief, and that the artefacts trace
 * back to names the model really contains.
 *
 * It is an integration test because it loads Sysprose; it makes no model calls
 * and costs nothing.
 */
import { describe, expect, it, beforeAll } from 'vitest';
import { resolve } from 'node:path';
import { parse } from 'yaml';
import { InProcessBackend } from '../../src/sysprose/inprocess.ts';
import { simulationInputOf } from '../../src/realization/adapter.ts';
import { simulationOf, type SimulationInput, type SimulationOutput } from '../../src/realization/simulation.ts';

const backend = new InProcessBackend({
  dir: process.env.SYSPROSE_DIR ?? resolve(process.env.HOME ?? '', 'sysprose'),
  expectedCommit: 'any',
});

const RUN = 'examples/drone-swarm-v7';

describe('the v7 run, read into a simulation', () => {
  let input: SimulationInput;
  let output: SimulationOutput;

  beforeAll(async () => {
    input = await simulationInputOf(RUN, backend, { timeScale: 10 });
    output = simulationOf(input);
  }, 120_000);

  it('reads the fleet from the brief, not from a name it guessed', () => {
    expect(input.root).toBe('SurveillanceDroneSwarm');
    expect(input.population).toMatchObject({ memberDef: 'SurveillanceDrone', size: 12 });
    // The bearer is a #Node at PA since v6; the brief names it.
    expect(input.population?.bearer).toBe('MeshRadio');
  });

  it('separates the budgets it must live within from the measures it is scored on', () => {
    // The four the generator refuses to work without.
    expect(input.budgets).toMatchObject({
      areaOfInterestKm2: 25,
      memberFlightEnduranceMinutes: 40,
      memberRechargeMinutes: 60,
      fleetSize: 12,
    });
    // A budget is not also a measure: nothing appears in both.
    const measureNames = new Set(input.measures.map((m) => m.name));
    for (const budget of Object.keys(input.budgets)) {
      expect(measureNames.has(budget), `${budget} counted twice`).toBe(false);
    }
    expect(input.measures.length).toBeGreaterThanOrEqual(10);
    expect(input.measures.find((m) => m.name === 'areaUnderWatchShare')).toMatchObject({
      sense: 'max', target: 0.9,
    });
  });

  it('finds the built things by their tag, and the member machines by ownership', () => {
    // #Node at PA — the things built or bought, the bearer among them.
    expect(input.nodes).toContain('MeshRadio');
    expect(input.nodes.length).toBeGreaterThan(1);
    for (const node of input.nodes) expect(node).not.toContain('::');

    // The member's own machines, each with states.
    expect(input.memberMachines.length).toBeGreaterThan(0);
    for (const machine of input.memberMachines) {
      expect(machine.qualifiedName, machine.name)
        .toBe(`SurveillanceDroneSwarm::PA::SurveillanceDrone::${machine.name}`);
      expect(machine.states.length, `${machine.name} has no states`).toBeGreaterThan(1);
    }
  });

  it('carries the brief\'s coordination, command and rules through', () => {
    expect(input.coordination).toContain('handOverSector');
    expect(input.coordination).toContain('rotateRecharge');
    expect(input.c2.length).toBeGreaterThan(0);
    expect(input.rules.map((r) => r.name)).toContain('RecallWins');
  });

  it('generates every artefact, and refuses none of them', () => {
    expect(Object.keys(output.files).sort())
      .toEqual(['fleet.yaml', 'mapping.yaml', 'scenario.yaml', 'trace.json', 'world.sdf']);
    for (const [name, body] of Object.entries(output.files)) {
      expect(body.length, name).toBeGreaterThan(0);
    }
    // One include per member of the real fleet; the models themselves are the
    // runtime's to make, from the airframe only it has.
    expect(output.files['world.sdf'].match(/<uri>model:\/\/member_\d+<\/uri>/g))
      .toHaveLength(input.population!.size);
  });

  it('sizes the world from the real area budget and gives every member a sector', () => {
    // 25 km² → 5000 m on a side, and twelve sectors for twelve drones.
    expect(output.files['world.sdf']).toContain('<size>5000 5000</size>');
    expect(output.files['world.sdf'].match(/<model name="sector_\d+">/g)).toHaveLength(12);
  });

  it('scales the duty cycle by the declared factor and says so', () => {
    const fleet = parse(output.files['fleet.yaml']) as {
      duty_cycle: { flight_seconds: number; recharge_seconds: number; time_scale: number };
    };
    expect(fleet.duty_cycle).toMatchObject({
      flight_seconds: 240,   // 40 min / 10
      recharge_seconds: 360, // 60 min / 10
      time_scale: 10,
    });
    expect(output.assumptions.join(' ')).toContain('240 s');
  });

  it('maps every state of every real machine, and marks the ones no flight mode fits', () => {
    const mapping = parse(output.files['mapping.yaml']) as {
      states: { state: string; of: string; autopilot: string | null; kind: string }[];
    };
    const stated = input.memberMachines.flatMap((m) => m.states);
    expect(mapping.states).toHaveLength(stated.length);
    // Every mapped state is a state the model really has.
    for (const row of mapping.states) expect(stated, row.state).toContain(row.state);
    // And a state that is a condition rather than a flight mode says so
    // instead of being given an autopilot mode it does not have.
    for (const row of mapping.states) {
      if (row.autopilot === null) expect(row.kind).not.toBe('flight mode');
    }
  });

  it('traces every artefact to elements the model contains', () => {
    const qualifiedNames = new Set<string>();
    for (const machine of input.memberMachines) qualifiedNames.add(machine.qualifiedName);
    expect(output.trace.length).toBeGreaterThan(0);
    for (const entry of output.trace) {
      expect(entry.from.length, entry.file).toBeGreaterThan(0);
      for (const name of entry.from) {
        expect(name, `${entry.file} traces to something outside the model`)
          .toContain('SurveillanceDroneSwarm');
      }
    }
    // The world's size is the area budget's doing, and the trace says so.
    const world = output.trace.find((t) => t.file === 'world.sdf');
    expect(world?.from).toContain('SurveillanceDroneSwarm::Common::areaOfInterestKm2');
  });
});
