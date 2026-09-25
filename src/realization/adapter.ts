/**
 * From a finished run to the simulation's inputs.
 *
 * T-05's generator is pure and knows nothing about where a model lives; this is
 * the half that reads a run directory and hands it what it needs. Splitting
 * them that way keeps the generator testable against a fixture, but it also
 * means the fixture is the only thing the generator had ever seen until this
 * file existed — so this is where the mapping table in
 * `docs/plans/swarm-3d-forerunner.md` meets the model a swarm run actually
 * produced.
 *
 * The rule the plan sets is kept here: the adapter keys on **tags and brief
 * fields**, never on one run's literal names. `population.memberDef` says
 * which definition is the member; `#Node` says which parts get built; a MoE's
 * `kind` says whether it is a budget or a measure. A future brief naming its
 * drones something else goes through unchanged.
 */
import { readFileSync } from 'node:fs';
import { basename, join } from 'node:path';

import type { SysproseBackend } from '../sysprose/backend.ts';
import type { ElementRow } from '../sysprose/types.ts';
import type { MachineView, SimulationInput } from './simulation.ts';

/** What a brief says, as far as the simulation is concerned. */
interface BriefShape {
  systemName?: string;
  population?: { memberDef: string; fleetPart: string; size: number; bearer?: string };
  coordinationFunctions?: readonly { name: string }[] | readonly string[];
  c2Functions?: readonly { name: string }[] | readonly string[];
  rules?: readonly { name: string; kind: string; of: string }[];
  modes?: readonly { name: string; of: string }[];
  moes?: readonly {
    name: string;
    kind?: string;
    sense?: string;
    target?: number | null;
    unit?: string;
  }[];
}

export class AdapterRefused extends Error {}

/** `Root::PA::SurveillanceDrone::MemberState` → `Root::PA::SurveillanceDrone`. */
const parentOf = (qualifiedName: string): string =>
  qualifiedName.split('::').slice(0, -1).join('::');

const simpleName = (qualifiedName: string): string =>
  qualifiedName.split('::').at(-1) ?? qualifiedName;

/**
 * A brief may name a function as a string or as an object with a name; both
 * shapes have been written, and neither is worth a migration.
 */
const namesOf = (entries: readonly { name: string }[] | readonly string[] | undefined): string[] =>
  (entries ?? []).map((entry) => (typeof entry === 'string' ? entry : entry.name));

/**
 * The model file a run produced. The run directory holds one, named after the
 * system, beside the fragments it was built from.
 */
function modelPathOf(runDir: string, brief: BriefShape): string {
  if (brief.systemName) return join(runDir, `${brief.systemName}.sysml`);
  throw new AdapterRefused(
    `${basename(runDir)}/brief.json states no systemName, so the model file cannot be named.`,
  );
}

/**
 * Budgets and measures are both MoEs; `kind` tells them apart. A budget is a
 * number the brief fixes and the architecture must live within; a measure is
 * something the architecture is scored on. The simulation needs the first as
 * world dimensions and the second as acceptance criteria, so they are split
 * here rather than in the generator.
 */
function moesOf(brief: BriefShape): Pick<SimulationInput, 'budgets' | 'measures'> {
  const budgets: Record<string, number> = {};
  const measures: { name: string; sense: 'min' | 'max'; target: number; unit?: string }[] = [];

  for (const moe of brief.moes ?? []) {
    if (moe.target === null || moe.target === undefined) continue;
    if (moe.kind === 'budget') {
      budgets[moe.name] = moe.target;
      continue;
    }
    // Anything not marked a budget is a measure: earlier briefs left the kind
    // off entirely for measures, and that reading is the one that matches them.
    const sense = moe.sense === 'min' ? 'min' : 'max';
    measures.push({
      name: moe.name,
      sense,
      target: moe.target,
      ...(moe.unit ? { unit: moe.unit } : {}),
    });
  }
  return { budgets, measures };
}

/**
 * The member's own state machines, with their states.
 *
 * Machines are `StateDefinition`s owned by the member definition at PA; a
 * machine's states are the `StateUsage`s directly under it. Both facts are
 * read the same way the gates read them (`src/check/predicates.ts`), so a
 * machine the gates can see is a machine the simulation can map.
 */
function memberMachinesOf(rows: readonly ElementRow[], memberPath: string): MachineView[] {
  const machines = rows.filter(
    (row) => row.metaclass === 'StateDefinition' && parentOf(row.qualifiedName) === memberPath,
  );
  return machines.map((machine) => ({
    qualifiedName: machine.qualifiedName,
    name: machine.name,
    states: rows
      .filter(
        (row) =>
          row.metaclass === 'StateUsage' && parentOf(row.qualifiedName) === machine.qualifiedName,
      )
      .map((row) => row.name),
  }));
}

export interface AdapterOptions {
  /** Wall-clock compression, declared and carried into every generated file. */
  timeScale?: number;
}

/**
 * Read a run directory and build the generator's input.
 *
 * It refuses rather than inventing: a run with no population has no fleet to
 * fly, and a missing model file is not something to work around. What it does
 * *not* check is whether the budgets the generator needs are present — that
 * refusal belongs to `simulationOf`, which names the ones it wants, and
 * duplicating it here would put the same rule in two places.
 */
export async function simulationInputOf(
  runDir: string,
  backend: SysproseBackend,
  options: AdapterOptions = {},
): Promise<SimulationInput> {
  let brief: BriefShape;
  try {
    brief = JSON.parse(readFileSync(join(runDir, 'brief.json'), 'utf8')) as BriefShape;
  } catch (error) {
    throw new AdapterRefused(
      `${basename(runDir)} has no readable brief.json: ${(error as Error).message}`,
    );
  }

  if (!brief.population) {
    throw new AdapterRefused(
      `${basename(runDir)} states no population, so there is no fleet to fly. ` +
        'A simulation of this brief would be a single system, and T-05 is about a swarm.',
    );
  }

  const modelPath = modelPathOf(runDir, brief);
  let text: string;
  try {
    text = readFileSync(modelPath, 'utf8');
  } catch (error) {
    throw new AdapterRefused(`cannot read ${modelPath}: ${(error as Error).message}`);
  }

  const root = brief.systemName!;
  const memberPath = `${root}::PA::${brief.population.memberDef}`;

  const { rows, nodeNames, estimates } = await backend.withModel(text, basename(modelPath), (model) => {
    const elements = backend.elements(model);
    const tags = backend.tags(model);
    // What the architecture claims for each measure. The report's whole point
    // is claimed against simulated, and the claim lives here — as an
    // `#Estimate` at PA, either a literal or (CV-17) fixed by a constraint.
    // An estimate with no literal is carried as null rather than as a guess:
    // the report then says the architecture derived it and this did not read
    // the derivation, which is true, instead of inventing a number.
    const claimed: Record<string, number | null> = {};
    for (const qualifiedName of tags.taggedWith('Estimate')) {
      if (!qualifiedName.startsWith(`${root}::PA::`)) continue;
      const row = elements.find((e) => e.qualifiedName === qualifiedName);
      if (!row) continue;
      const value = Number.parseFloat(row.value);
      claimed[simpleName(qualifiedName)] = Number.isFinite(value) ? value : null;
    }
    // `#Node` is what the architecture says gets built or bought, and the tag
    // is how every other part of this project finds them. Only the ones at PA
    // matter: a node named at LA is a logical component, not a thing.
    const nodes = tags
      .taggedWith('Node')
      .filter((qualifiedName) => qualifiedName.startsWith(`${root}::PA::`))
      .map(simpleName);
    return { rows: elements, nodeNames: [...new Set(nodes)].sort(), estimates: claimed };
  });

  return {
    root,
    population: brief.population,
    nodes: nodeNames,
    memberMachines: memberMachinesOf(rows, memberPath),
    coordination: namesOf(brief.coordinationFunctions),
    c2: namesOf(brief.c2Functions),
    rules: (brief.rules ?? []).map((rule) => ({ name: rule.name, kind: rule.kind, of: rule.of })),
    modes: (brief.modes ?? []).map((mode) => ({ name: mode.name, of: mode.of })),
    ...(() => {
      const split = moesOf(brief);
      return {
        budgets: split.budgets,
        // Each measure carries what the architecture claimed for it, so the
        // report can put the claim beside the result without a second lookup.
        measures: split.measures.map((m) => ({
          ...m,
          ...(m.name in estimates ? { estimate: estimates[m.name] } : {}),
        })),
      };
    })(),
    ...(options.timeScale === undefined ? {} : { timeScale: options.timeScale }),
  };
}
