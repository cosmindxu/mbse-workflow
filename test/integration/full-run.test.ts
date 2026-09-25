/**
 * The whole machine, end to end, without spending a model call.
 *
 * The fake client is scripted with fragments derived from the reference model,
 * so what is under test is everything around the agents: the order of the
 * steps, the transitions, the assembly, the checks, the repair loop, the
 * alternatives and their evaluation, the packets, the state file, and the final
 * audit — with a real Sysprose behind all of it.
 */
import { describe, expect, it, beforeAll } from 'vitest';
import { existsSync, mkdtempSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { resolve } from 'node:path';
import { runWorkflow } from '../../src/orch/machine.ts';
import { InProcessBackend } from '../../src/sysprose/inprocess.ts';
import { FakeLlmClient } from '../../src/llm/fake.ts';
import { AutoGate } from '../../src/orch/gates.ts';
import { loadConfig } from '../../src/config/load.ts';
import { loadState } from '../../src/orch/state.ts';
import { hasCorpus } from '../../src/config/corpus.ts';
import { makeLayout } from '../../src/model/layout.ts';
import { runStepChecks } from '../../src/check/checker.ts';
import { step as stepById } from '../../src/spec/steps.ts';
import type { SeedOutput } from '../../src/llm/schemas.ts';

const FIXTURE = resolve(import.meta.dirname, '../fixtures/levelcrossing/fragments');
const fragment = (name: string): string => readFileSync(resolve(FIXTURE, name), 'utf8');

/** The reference model, taken apart into the answers a run would have got. */
function cannedAnswers() {
  const common = fragment('1_Common.sysml').replace(
    '    }\n',
    [
      '        // the measures the architectures are scored on',
      '        #MoE attribute maxDepartureDelaySeconds : ScalarValues::Real = 300.0;',
      '        #MoE attribute detectionCoverageRatio : ScalarValues::Real = 0.99;',
      '    }',
      '',
    ].join('\n'),
  );

  const brief: SeedOutput = {
    systemName: 'LevelCrossing',
    systemEntity: 'authority',
    mission: 'Keep road and rail traffic apart at a level crossing.',
    functionSentence: 'LevelCrossing secures a crossing from open to protected before a train arrives.',
    stakeholders: [{ name: 'Railway authority', role: 'operates the crossing' }],
    environment: [
      { name: 'trainSchedule', quadrant: 'input', doc: 'when trains are expected' },
      { name: 'signalCommand', quadrant: 'output', doc: 'what the crossing shows' },
      { name: 'safetyRegulation', quadrant: 'constraining', doc: 'the rules it must meet' },
      { name: 'power', quadrant: 'resource', doc: 'what it runs on' },
    ],
    capabilities: [{ name: 'ForbidSimultaneousAccess', doc: 'road and rail never occupy the crossing together' }],
    moes: [
      { name: 'maxDepartureDelaySeconds', unit: 's', sense: 'min', target: 300, doc: 'how long a departure may be held' },
      { name: 'detectionCoverageRatio', unit: '', sense: 'max', target: 0.99, doc: 'how much of the crossing is watched' },
    ],
    // What the brief fixes by name (CV-18, CV-19): the whole chain has to carry
    // one of each, under these names, for every step to clear.
    rules: [{ name: 'BarriersBeforeTrain', doc: 'no train passes before the barriers are down', kind: 'precededBy', of: 'system' }],
    modes: [{ name: 'BarriersDown', doc: 'road closed, rail may proceed', of: 'system' }],
    items: [{ name: 'TrainSchedule', fields: [{ name: 'publicationTime', doc: 'when the schedule was issued' }] }],
    hazards: [{ name: 'BarrierFailureHazard', doc: 'a barrier stays up' }],
    extraKinds: [],
    commonFragment: common,
    rationale: 'Scripted answer: the reference model, taken apart.',
  };

  // The physical layer of the reference model is a thin thread — it implements
  // one logical function. A complete run has to implement all of them, so the
  // canned answer carries the other two, which is what the gate demands.
  const pa = fragment('6_PA.sysml').replace(
    /\n    \}\s*$/,
    [
      '',
      '        action def LaunchDepartureSequence; action def SwitchOnSignal;',
      '        action launchDepartureCmd : LaunchDepartureSequence;',
      '        action switchOnSignalCmd : SwitchOnSignal;',
      '        allocate launchDepartureCmd to cabinet;',
      '        allocate switchOnSignalCmd to cabinet;',
      '        trace launchDepartureCmd to LevelCrossing::LA::launchDeparture;',
      '        trace switchOnSignalCmd to LevelCrossing::LA::switchOnSignal;',
      '    }',
      '',
    ].join('\n'),
  );

  // SA states the rule and carries it, with the mode, on the system's machine.
  const sa = fragment('4_SA.sysml')
    .replace('        part def ControlSystem {\n', `        part def ControlSystem {\n${guardMachine}\n`)
    .replace(/\n    \}\s*$/, '\n        #Rule requirement BarriersBeforeTrain { subject s : ControlSystem; doc /* no train passes before the barriers are down */ }\n    }\n');

  const rename = (text: string, pairs: Array<[string, string]>): string =>
    pairs.reduce((acc, [from, to]) => acc.replaceAll(from, to), text);

  return {
    brief,
    oa: fragment('3_OA.sysml'),
    sa,
    // S31 writes functions only now: the reference LA, with its three
    // components taken out and every function put on the placeholder.
    la: functionsOnly(fragment('5_LA.sysml')),
    laAlt2: rename(fragment('5_LA.sysml'), [
      ['ManagementSystem', 'SupervisionSystem'],
      ['RailFacilities', 'TrackSubsystem'],
      ['RoadFacilities', 'RoadSubsystem'],
    ]),
    pa,
    paAlt2: rename(pa, [['ControlCabinet', 'ControlEnclosure'], ['ProcessingBoard', 'ComputeBoard']]),
    epbs: [
      '    package EPBS {',
      '        #prompt part epbsGuidance { doc /* EPBS: configuration items realise PA components. */ }',
      '        #CI_HWCI part def AssemblyItem { doc /* the delivered assembly */ }',
      '        part assemblyCi : AssemblyItem;',
      '        trace assemblyCi to LevelCrossing::PA::assembly;',
      '    }',
      '',
    ].join('\n'),
  };
}

/** The reference LA without its components: what a function layer is. */
function functionsOnly(la: string): string {
  const defs = ['ManagementSystem', 'RailFacilities', 'RoadFacilities'];
  const usages = ['mgmt', 'rail', 'road'];
  let out = la;
  for (const def of defs) {
    const m = new RegExp(`^[ \\t]*(?:#\\w+\\s+)?part def ${def}\\b[^\\n]*`, 'm').exec(out);
    if (!m) continue;
    let end = m.index + m[0].length;
    if (m[0].includes('{')) {
      let depth = 0;
      for (let i = out.indexOf('{', m.index); i < out.length; i += 1) {
        if (out[i] === '{') depth += 1;
        else if (out[i] === '}' && (depth -= 1) === 0) {
          end = i + 1;
          break;
        }
      }
    }
    const lineStart = out.lastIndexOf('\n', m.index) + 1;
    const lineEnd = out.indexOf('\n', end);
    out = out.slice(0, lineStart) + out.slice(lineEnd < 0 ? out.length : lineEnd + 1);
  }
  const names = usages.join('|');
  out = out
    .split('\n')
    .filter((l) => !new RegExp(`^\\s*(part (${names})\\s*:|trace (${names}) to|allocate \\w+ to (${names});|connection .*\\b(${names})\\.|interface .*\\b(${names})\\.)`).test(l))
    .join('\n');
  const placeholder = [
    '        part def LevelCrossingLogical { doc /* placeholder: the system, to be decomposed by the alternatives */ }',
    '        part mainComponent : LevelCrossingLogical;',
    '        trace mainComponent to LevelCrossing::SA::system;',
    '        allocate launchDeparture to mainComponent;',
    '        allocate detectVehicleAccess to mainComponent;',
    '        allocate switchOnSignal to mainComponent;',
  ].join('\n');
  return out.replace(/\n    \}\s*$/, `\n${placeholder}\n    }\n`);
}

/** A machine that carries the brief's mode and rule — every layer's system part has one. */
const guardMachine = [
  'state def CrossingGuard {',
  '    doc /* the crossing as road and rail see it */',
  '    @SysproseVerification::PropertyPattern { doc /* BarriersBeforeTrain: no train passes before the barriers are down */ attribute pattern = "precedence"; attribute scope = "globally"; attribute s = "state BarriersDown"; attribute p = "state TrainPassing"; }',
  '    initial Start;',
  '    state Open { doc /* road open */ }',
  '    state BarriersDown { doc /* road closed */ }',
  '    state TrainPassing { doc /* a train on the crossing */ }',
  '    transition Start -> Open;',
  '    transition Open -> BarriersDown;',
  '    transition BarriersDown -> TrainPassing;',
  '    transition TrainPassing -> Open;',
  '}',
].join('\n');

/** A logical architecture: one part that performs every function. */
const laSection = (def: string, part: string, doc: string): string =>
  [
    `part def ${def} { doc /* ${doc} */ ${guardMachine} }`,
    `part ${part} : ${def};`,
    `allocate launchDeparture to ${part};`,
    `allocate detectVehicleAccess to ${part};`,
    `allocate switchOnSignal to ${part};`,
    // CV-17: each architecture states its estimates; the two differ, so the measures term can decide.
    `#Estimate attribute maxDepartureDelaySeconds :> Common::maxDepartureDelaySeconds = ${part === 'supervision' ? '240.0' : '320.0'} { doc /* ${doc}: worst-case hold */ }`,
    `#Estimate attribute detectionCoverageRatio :> Common::detectionCoverageRatio = 0.995 { doc /* ${doc}: sensors on every approach */ }`,
  ].join('\n');

/** A physical architecture: one part that performs every carried function. */
const paSection = (def: string, doc: string): string =>
  [
    `part def ${def} { doc /* ${doc} */ ${guardMachine} }`,
    `part assembly : ${def};`,
    'allocate launchDeparture to assembly;',
    'allocate detectVehicleAccess to assembly;',
    'allocate switchOnSignal to assembly;',
    `#Estimate attribute maxDepartureDelaySeconds :> Common::maxDepartureDelaySeconds = 250.0 { doc /* ${doc}: worst-case hold */ }`,
    `#Estimate attribute detectionCoverageRatio :> Common::detectionCoverageRatio = 0.99 { doc /* ${doc}: sensors on every approach */ }`,
  ].join('\n');

const evaluation = (alternatives: number[]) => ({
  scores: alternatives.map((k) => ({
    alternative: k,
    criteria: [
      { name: 'cohesion', score: k === 1 ? 4 : 3, reason: 'scripted' },
      { name: 'coupling', score: 3, reason: 'scripted' },
      { name: 'realisability', score: 4, reason: 'scripted' },
      { name: 'evolvability', score: 3, reason: 'scripted' },
    ],
  })),
  recommended: 1,
  rationale: 'Scripted comparison for the end-to-end test.',
});

describe.skipIf(!hasCorpus())('a whole run, with a fake model and a real checker', () => {
  let dir: string;
  let state: ReturnType<typeof loadState>;
  let llm: FakeLlmClient;

  beforeAll(async () => {
    const canned = cannedAnswers();
    dir = mkdtempSync(resolve(tmpdir(), 'mbse-run-'));
    const config = loadConfig(undefined, {
      llmBackend: 'fake',
      knobs: { safety: false, verification: false, views: false },
      // The canned fragments are the reference model, which predates the
      // documentation gate; the final audit still measures coverage below.
      limits: { doc_coverage_min: 0 },
    });
    llm = new FakeLlmClient({
      'S00:SEED': canned.brief,
      'S10:AUTHOR': { fragment: canned.oa, rationale: 'operational analysis', todos: [], commonAdditions: [] },
      'S21:AUTHOR': { fragment: canned.sa, rationale: 'system analysis', todos: [], commonAdditions: [] },
      'S31:AUTHOR': { fragment: canned.la, rationale: 'logical functions', todos: [], commonAdditions: [] },
      // The function layer is the orchestrator's; an alternative answers with
      // its components only. The reference LA already allocates every function,
      // so a section that adds one used component is a complete architecture.
      'S32:AUTHOR:alt-1': { declarations: laSection('SupervisionNode', 'supervision', 'one node supervises everything'), rationale: 'logical alternative 1', todos: [], commonAdditions: [] },
      'S32:AUTHOR:alt-2': { declarations: laSection('TrackNode', 'trackNode', 'trackside logic'), rationale: 'logical alternative 2', todos: [], commonAdditions: [] },
      'S33:EVALUATE': evaluation([1, 2]),
      // The PA head carries the three logical functions unallocated: a physical
      // alternative has to give each of them a part. Both name theirs `assembly`
      // so the configuration items below realise whichever one is chosen.
      'S41:AUTHOR:alt-1': { declarations: paSection('CabinetAssembly', 'one cabinet does everything'), rationale: 'physical alternative 1', todos: [], commonAdditions: [] },
      'S41:AUTHOR:alt-2': { declarations: paSection('DistributedAssembly', 'trackside units'), rationale: 'physical alternative 2', todos: [], commonAdditions: [] },
      'S42:EVALUATE': evaluation([1, 2]),
      'S50:AUTHOR': { fragment: canned.epbs, rationale: 'configuration items', todos: [], commonAdditions: [] },
    });

    const result = await runWorkflow({
      dir,
      mode: 'autonomous',
      config,
      backend: new InProcessBackend({ dir: config.sysprose.dir, expectedCommit: config.sysprose.expected_commit }),
      llm,
      gates: new AutoGate(),
      briefText: 'A level crossing that keeps road and rail traffic apart.',
      log: () => {},
    });
    state = result.state;
  }, 900_000);

  it('runs every step to done, and skips the lanes that are off', () => {
    const statuses = Object.fromEntries(Object.entries(state!.steps).map(([id, r]) => [id, r?.status]));
    expect(statuses.S00).toBe('done');
    expect(statuses.S01).toBe('skipped');
    expect(statuses.S02).toBe('skipped');
    for (const id of ['S10', 'S20', 'S21', 'S30', 'S31', 'S32', 'S33', 'S40', 'S41', 'S42', 'S50', 'S70']) {
      expect(statuses[id], `${id} should be done`).toBe('done');
    }
    expect(statuses.S60).toBe('skipped');
  });

  it('carries what the brief fixed by name, and says so in the brief summary', () => {
    const summary = readFileSync(resolve(dir, '00-brief.md'), 'utf8');
    for (const heading of ['## Hazards the brief names', '## Rules the system never breaks', '## Modes', '## What the items carry']) expect(summary).toContain(heading);
    // The gates held: the rule and the mode are on the chosen architectures' machines.
    const model = readFileSync(resolve(dir, 'LevelCrossing.sysml'), 'utf8');
    expect(model.match(/doc \/\* BarriersBeforeTrain:/g)?.length).toBeGreaterThanOrEqual(3);
  });

  it('names the model after the system the brief settled on', () => {
    expect(state!.root).toBe('LevelCrossing');
    expect(existsSync(resolve(dir, 'LevelCrossing.sysml'))).toBe(true);
  });

  it('produces a model the shipped checker loads clean', () => {
    const audit = JSON.parse(readFileSync(resolve(dir, 'audit/final/final.json'), 'utf8'));
    expect(audit.witness.exitCode).toBe(0);
    expect(audit.witness.diagnostics).toBe(0);
    expect(audit.closure.length).toBe(4);
    // Every logical function is realised physically — the gate that the thin
    // thread of the reference model does not meet.
    const laToPa = audit.closure.find((c: { from: string }) => c.from === 'LA');
    expect(laToPa.realised).toBe(laToPa.total);
  });

  it('writes a packet for every step it ran, with the commands to reproduce it', () => {
    for (const id of ['S10', 'S21', 'S31', 'S41', 'S50']) {
      const verdict = JSON.parse(readFileSync(resolve(dir, `audit/${id}/verdict.json`), 'utf8'));
      expect(verdict.checks.length).toBeGreaterThan(0);
      expect(verdict.checks.every((c: { command: string }) => c.command.startsWith('npm run'))).toBe(true);
      expect(existsSync(resolve(dir, `audit/${id}/rationale.md`))).toBe(true);
    }
  });

  it('chooses between the alternatives and writes the trade-off into the model', () => {
    const la = readFileSync(resolve(dir, 'fragments/5_LA.sysml'), 'utf8');
    expect(la).toContain('#prose part laTradeOff');
    expect(la).toContain('Alternative');
    const rationale = readFileSync(resolve(dir, 'audit/S33/trade-off.md'), 'utf8');
    expect(rationale).toContain('architecture trade-off');
    expect(state!.steps.S32?.alternatives?.length).toBe(2);
    expect(state!.steps.S32?.alternatives?.some((a) => a.chosen)).toBe(true);
  });

  it('decides the measures from each alternative\'s own estimates, and the score tells them apart', () => {
    const rationale = readFileSync(resolve(dir, 'audit/S33/trade-off.md'), 'utf8');
    // Alternative 1 holds a departure 240 s at worst (≤ 300: met), alternative 2 320 s (missed).
    expect(rationale).toMatch(/\| 1 \| `maxDepartureDelaySeconds` \| 240 s \| ≤ 300 s \| yes \|/);
    expect(rationale).toMatch(/\| 2 \| `maxDepartureDelaySeconds` \| 320 s \| ≤ 300 s \| no \|/);
    expect(rationale).not.toContain('undecided');
    expect(existsSync(resolve(dir, 'audit/S33/alt-1/bounds-maxDepartureDelaySeconds.json'))).toBe(true);
    const audit = readFileSync(resolve(dir, 'audit/final/README.md'), 'utf8');
    expect(audit).toContain('## Measures');
    expect(audit).toMatch(/\| `detectionCoverageRatio` \| ≥ 0\.99 \| 0\.995 ✓ \| 0\.99 ✓ \|/);
  });

  it('generates each layer from the one above it before an agent sees it', () => {
    const transition = JSON.parse(readFileSync(resolve(dir, 'audit/S20/step.json'), 'utf8'));
    expect(transition.functions).toBeGreaterThan(0);
    expect(transition.capabilities).toBeGreaterThan(0);
  });

  it('spends nothing, and records what it asked for', () => {
    expect(state!.llm.costUsd).toBe(0);
    expect(llm.requests.length).toBeGreaterThanOrEqual(11);
    const author = llm.requests.find((r) => r.tag === 'S21:AUTHOR');
    expect(author?.system).toContain('package SA');
    expect(author?.user).toContain('What is in OA');
    expect(author?.user).toContain('Your starting point');
  });

  it('leaves a state file a resume can start from', () => {
    const reloaded = loadState(resolve(dir, 'state.json'));
    expect(reloaded?.brief?.systemName).toBe('LevelCrossing');
    expect(reloaded?.steps.S50?.prefixHash).toBeTruthy();
    expect(reloaded?.sysprose.commit).toMatch(/^[0-9a-f]{7}$/);
  });

  it('measures whether a person can review it, instead of claiming so', () => {
    const audit = JSON.parse(readFileSync(resolve(dir, 'audit/final/final.json'), 'utf8'));
    const r = audit.reviewability;
    expect(r.docCoverage.map((d: { layer: string }) => d.layer)).toContain('LA');
    for (const row of r.docCoverage) expect(row.coverage).toBeGreaterThanOrEqual(0);
    expect(Array.isArray(r.unexplained)).toBe(true);
    expect(r.reviewSurface.some((s: { step: string }) => s.step === 'S21')).toBe(true);
    const readme = readFileSync(resolve(dir, 'audit/final/README.md'), 'utf8');
    expect(readme).toContain('Can a person review this?');
  });

  it('re-checks a fragment a person edited and invalidates only what was built on it', async () => {
    const { invalidate } = await import('../../src/orch/invalidate.ts');
    const before = loadState(resolve(dir, 'state.json'))!;
    const layout = makeLayout(dir, 'LevelCrossing');
    // Nothing changed: nothing invalidated.
    expect(invalidate(structuredClone(before), layout).invalidated).toEqual([]);
    // A contributor touches SA.
    const saPath = layout.fragmentPath('SA');
    const original = readFileSync(saPath, 'utf8');
    writeFileSync(saPath, original.replace('    }\n', '        doc /* edited by a person */\n    }\n'));
    try {
      const state = structuredClone(before);
      const result = invalidate(state, layout);
      expect(result.changed).toEqual(['SA']);
      // The edited layer is re-checked, never re-authored or regenerated.
      expect(result.recheck).toEqual(['S21']);
      expect(result.invalidated).not.toContain('S20');
      expect(result.invalidated).not.toContain('S21');
      expect(state.steps.S20?.status).toBe('done');
      expect(state.steps.S21?.status).toBe('done');
      // Everything built on it runs again.
      expect(result.resumeAt).toBe('S30');
      expect(result.invalidated).toContain('S31');
      expect(result.invalidated).toContain('S33');
      expect(result.invalidated).toContain('S70');
      expect(result.invalidated).not.toContain('S10');
      expect(state.steps.S10?.status).toBe('done');
      expect(state.steps.S33?.status).toBe('pending');
    } finally {
      writeFileSync(saPath, original);
    }
  });

  it('re-checks a blocked step whose fragment a person fixed, instead of authoring it again', async () => {
    const { invalidate } = await import('../../src/orch/invalidate.ts');
    const before = loadState(resolve(dir, 'state.json'))!;
    const layout = makeLayout(dir, 'LevelCrossing');
    const saPath = layout.fragmentPath('SA');
    const original = readFileSync(saPath, 'utf8');
    writeFileSync(saPath, original.replace('    }\n', '        doc /* fixed by a person after the step blocked */\n    }\n'));
    try {
      const state = structuredClone(before);
      state.steps.S21!.status = 'blocked';
      const result = invalidate(state, layout);
      expect(result.changed).toEqual(['SA']);
      // Measured: a blocked step was left out of the re-check, so the resume
      // authored SA again and replaced the fragment the person had just fixed.
      expect(result.recheck).toEqual(['S21']);
      expect(result.invalidated).not.toContain('S21');
      expect(result.resumeAt).toBe('S30');
    } finally {
      writeFileSync(saPath, original);
    }
  });

  it('reads the hash of the step that finished last, not the step that comes last', async () => {
    const { invalidate } = await import('../../src/orch/invalidate.ts');
    const before = loadState(resolve(dir, 'state.json'))!;
    const layout = makeLayout(dir, 'LevelCrossing');
    const state = structuredClone(before);
    // A run re-entered at S21: S21 holds the current hashes, S22 those of the
    // previous run. Measured: reading STEPS in order handed the verdict to the
    // stale record, every layer looked edited, and the resume would have
    // re-authored the model from OA down.
    state.steps.S21!.finishedAt = '2026-09-16T01:55:53.377Z';
    state.steps.S22!.finishedAt = '2026-09-11T10:00:00.000Z';
    state.steps.S22!.fragmentHashes = { ...state.steps.S22!.fragmentHashes!, SA: 'stale0000000000' };
    expect(invalidate(state, layout).changed).toEqual([]);
  });

  it('re-checks what is on disk when a contributor edits a fragment', async () => {
    const config = loadConfig(undefined, { knobs: { safety: false, verification: false } });
    const layout = makeLayout(dir, 'LevelCrossing');
    const verdict = await runStepChecks(stepById('S21'), {
      backend: new InProcessBackend({ dir: config.sysprose.dir, expectedCommit: config.sysprose.expected_commit }),
      layout,
      knobs: config.knobs,
    });
    expect(verdict.blocking).toBe(false);
  });
});

