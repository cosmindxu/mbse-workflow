/**
 * A measure the brief asks for and gives no number: estimated, reported, never scored.
 *
 * v9's brief asks how long the swarm holds the watch unattended and states no
 * figure. SEED set 12 h itself, every alternative at S33 and S42 missed it, and
 * its own doc said to wait for the customer's figure. Now SEED leaves the
 * target out, and every reader of the brief carries the measure without one.
 */
import { describe, expect, it } from 'vitest';
import { mkdtempSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { resolve } from 'node:path';
import { parse } from 'yaml';
import { MoeSchema, type Moe, type SeedOutput } from '../../src/llm/schemas.ts';
import { FakeLlmClient } from '../../src/llm/fake.ts';
import { loadConfig } from '../../src/config/load.ts';
import { makeLayout } from '../../src/model/layout.ts';
import { emptyState } from '../../src/orch/state.ts';
import { runSeed } from '../../src/agents/seed.ts';
import { briefFactsOf } from '../../src/agents/author.ts';
import { estimateGuidance } from '../../src/agents/alternatives.ts';
import { measureClaimsLines, measuresThatDoNotDiscriminate, rationaleFor, type AlternativeMetrics } from '../../src/agents/evaluate.ts';
import { briefSection } from '../../src/prompts/context.ts';
import { PREDICATES, type PredicateInput } from '../../src/check/predicates.ts';
import { step as stepById } from '../../src/spec/steps.ts';
import { moesOf } from '../../src/realization/adapter.ts';
import { simulationOf, type SimulationInput } from '../../src/realization/simulation.ts';

const watch: Moe = {
  name: 'unattendedWatchDurationHours',
  unit: 'h',
  sense: 'max',
  doc: 'How long the swarm holds the watch before it needs people; the brief states no number, and the customer\'s figure is awaited.',
  kind: 'measure',
};
const coverage: Moe = { name: 'areaUnderWatchFraction', unit: '', sense: 'max', target: 0.9, doc: 'share of the area under watch', kind: 'measure' };
const fleet: Moe = { name: 'fleetSizeMembers', unit: '', sense: 'min', target: 12, doc: 'the drones the customer can field', kind: 'budget' };

const brief: SeedOutput = {
  systemName: 'Swarm',
  systemEntity: 'watcher',
  mission: 'Hold a watch over an area.',
  functionSentence: 'Swarm moves the area from unwatched to watched.',
  stakeholders: [{ name: 'Operator', role: 'reads the reports' }],
  environment: [{ name: 'area', quadrant: 'input', doc: 'the area to watch' }],
  capabilities: [{ name: 'Watch', doc: 'hold the watch' }],
  moes: [coverage, watch, fleet],
  extraKinds: [],
  commonFragment: [
    'package Common {',
    '    #MoE attribute areaUnderWatchFraction { doc /* share of the area under watch */ }',
    '    #MoE attribute unattendedWatchDurationHours { doc /* hours unattended; no number in the brief */ }',
    '}',
  ].join('\n'),
  rationale: 'scripted',
};

describe('SEED', () => {
  it('may answer a measure with no target, and a budget still has one', () => {
    expect(MoeSchema.safeParse(watch).success).toBe(true);
    expect(MoeSchema.safeParse(fleet).success).toBe(true);
  });

  it('is told never to invent a target, and the brief it writes shows none', async () => {
    const dir = mkdtempSync(resolve(tmpdir(), 'mbse-seed-'));
    const layout = makeLayout(dir, 'Swarm');
    layout.ensure();
    const config = loadConfig(undefined, { llmBackend: 'fake' });
    const llm = new FakeLlmClient({ 'S00:SEED': brief });
    const state = emptyState({ root: 'Swarm', mode: 'autonomous', knobs: config.knobs, sysprose: { dir: '', commit: '', expected: '', matches: true } });
    await runSeed({ config, layout, backend: undefined as never, llm, state, knobs: config.knobs, log: () => {} }, 'Hold the watch as long as possible without people. Twelve drones.');

    const user = llm.requests[0].user;
    expect(user).toContain('Where the brief asks for a measure and states no number, leave `target` out');
    expect(user).toContain('never set one yourself');
    expect(user).not.toContain('set a target yourself only where the brief is silent');
    expect(user).toContain('with a `require constraint` holding it to its target when it has one — a measure with no target has none');

    const md = readFileSync(layout.briefPath, 'utf8');
    expect(md).toContain('| `unattendedWatchDurationHours` | max | — | none in the brief | h |');
    expect(md).toContain('| `areaUnderWatchFraction` | max | 0.9 |');
  });
});

describe('the gates and the authors', () => {
  it('still ask every architecture for the estimate, and carry it to the drift check', () => {
    const facts = briefFactsOf(brief);
    // `moe.estimated` and `moe.carriedEstimate` both read this list.
    expect(facts.moes).toEqual(['areaUnderWatchFraction', 'unattendedWatchDurationHours']);
    expect(facts.measures?.find((m) => m.name === watch.name)?.target).toBeUndefined();
    expect(facts.budgets).toEqual({ fleetSizeMembers: 12 });

    const input: PredicateInput = {
      step: stepById('S32'),
      layer: 'LA',
      root: 'Swarm',
      knobs: { modes_states: true, interfaces: true, variability: true, safety: false, views: false, verification: true, requirements_intake: false, infrastructure_intake: false },
      brief: facts,
      payloads: { elements: [] },
      tags: { byElement: new Map(), byKeyword: new Map(), has: () => false, taggedWith: () => [] },
      blocking: true,
      alternative: 1,
    };
    const missing = PREDICATES['moe.estimated'](input).map((i) => i.message).join('\n');
    expect(missing).toContain('no estimate for the measure `unattendedWatchDurationHours`');
  });

  it('show the author the measure with no target, never `≥ undefined`', () => {
    const context = briefSection(brief);
    expect(context).toContain('`unattendedWatchDurationHours` (no target, the brief states none — estimated and reported, not scored)');
    const guidance = estimateGuidance([coverage, watch], 'LA', [fleet]).join(' ');
    expect(guidance).toContain('`unattendedWatchDurationHours` (no target: the brief states none; estimate it all the same)');
    expect(guidance).toContain('`areaUnderWatchFraction` ≥ 0.9');
    expect(`${context}\n${guidance}`).not.toContain('undefined');
  });
});

const metrics = (k: number, rows: AlternativeMetrics['moes']): AlternativeMetrics => ({
  k, elements: 0, connections: 0, unconnectedPorts: 0, orphanDefinitions: 0, functionsRealised: 0, functionsAbove: 0, repairIterations: 0, warnings: 0, moes: rows,
});
const row = (name: string, value: number, over: Partial<AlternativeMetrics['moes'][number]> = {}): AlternativeMetrics['moes'][number] => ({
  name, outcome: 'optimum', value, sense: 'max', target: 0.9, unit: '', met: value >= 0.9, ...over,
});

describe('the trade-off', () => {
  const seedSet: Moe = { name: 'missionHours', unit: 'h', sense: 'max', target: 12, doc: 'SEED set this', kind: 'measure', setBySeed: true };

  it('tells the reviewing model which measures are reported and not scored', () => {
    const text = measureClaimsLines([coverage, watch, seedSet], [metrics(1, [row(coverage.name, 0.8), row(watch.name, 0.7, { target: undefined, unit: 'h', met: undefined, unscored: 'no target' })])]).join('\n');
    expect(text).toContain('- `unattendedWatchDurationHours`: no target, the brief states none: reported, not scored');
    expect(text).toContain('### `unattendedWatchDurationHours` (no target, the brief states none: reported, not scored)');
    expect(text).toContain('- `missionHours`: target ≥ 12 h, set by SEED: reported, not scored');
    expect(text).toContain('### `areaUnderWatchFraction` (target ≥ 0.9)');
  });

  it('shows them in its table as not scored, and does not call them dead weight', () => {
    const alts = [
      metrics(1, [row(coverage.name, 0.8), row(watch.name, 0.7, { target: undefined, unit: 'h', met: undefined, unscored: 'no target' }), row(seedSet.name, 0.7, { target: 12, unit: 'h', met: false, unscored: 'set by SEED' })]),
      metrics(2, [row(coverage.name, 0.95), row(watch.name, 0.7, { target: undefined, unit: 'h', met: undefined, unscored: 'no target' }), row(seedSet.name, 0.7, { target: 12, unit: 'h', met: false, unscored: 'set by SEED' })]),
    ];
    const text = rationaleFor('LA', 2, alts, [{ k: 1, total: 0, moe: 0, rubric: 0, structure: 0, resilience: 0 }, { k: 2, total: 1, moe: 1, rubric: 0, structure: 0, resilience: 0 }], { recommended: 2, rationale: 'x', scores: [] });
    expect(text).toContain('| 1 | `unattendedWatchDurationHours` | 0.7 h | — | — (not scored: no target) |');
    expect(text).toContain('| 1 | `missionHours` | 0.7 h | ≥ 12 h | no (not scored: target set by SEED) |');
    expect(measuresThatDoNotDiscriminate(alts)).toEqual([]);
  });
});

describe('the simulation', () => {
  it('carries a measure with no target, with its estimate, and holds the run to no number for it', () => {
    const split = moesOf({ moes: [{ name: watch.name, kind: 'measure', sense: 'max', unit: 'h' }, { name: coverage.name, kind: 'measure', sense: 'max', target: 0.9 }, { name: fleet.name, kind: 'budget', target: 12 }] });
    expect(split.measures).toContainEqual({ name: watch.name, sense: 'max', unit: 'h' });
    expect(split.budgets).toEqual({ fleetSizeMembers: 12 });

    const input: SimulationInput = {
      root: 'Swarm',
      population: { memberDef: 'Drone', fleetPart: 'fleet', size: 12 },
      nodes: [],
      memberMachines: [{ qualifiedName: 'Swarm::PA::Drone::MemberState', name: 'MemberState', states: ['Landed', 'Watching'] }],
      coordination: [],
      c2: [],
      rules: [],
      modes: [],
      budgets: { areaOfInterestKm2: 25, memberFlightEnduranceMinutes: 40, memberRechargeMinutes: 20, fleetSize: 12 },
      measures: [{ ...split.measures[0], estimate: 0.66, estimateKind: 'derived' }, { name: 'areaUnderWatchShare', sense: 'max', target: 0.9 }],
    };
    const { files } = simulationOf(input);
    const mapping = parse(files['mapping.yaml']) as { measures: Array<Record<string, unknown>> };
    expect(mapping.measures).toContainEqual({ measure: watch.name, sense: 'max', estimate: 0.66, estimate_kind: 'derived' });
    expect(mapping.measures).toContainEqual(expect.objectContaining({ measure: 'areaUnderWatchShare', target: '>= 0.9' }));
    expect(files['mapping.yaml']).not.toContain('undefined');
  });
});
