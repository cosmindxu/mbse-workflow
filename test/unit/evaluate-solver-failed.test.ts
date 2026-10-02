/**
 * A trade-off measure the solver crashed under twice is left out for every
 * alternative, shown in the trade-off, and carried on the step's verdict.
 *
 * Before, the alternative whose read crashed scored ½ on the measure where the
 * other earned 1 or 0, so a trap in z3 could move the choice, and the only
 * record was a log line.
 */
import { mkdirSync, mkdtempSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';
import {
  SOLVER_CRASHED_TWICE,
  evaluateAlternatives,
  leaveOutCrashed,
  measureClaimsLines,
  moeScore,
  rationaleFor,
  solverFailedItems,
  type AlternativeMetrics,
} from '../../src/agents/evaluate.ts';
import { classifyCode, type Knobs } from '../../src/check/classify.ts';
import { loadConfig } from '../../src/config/load.ts';
import { FakeLlmClient } from '../../src/llm/fake.ts';
import type { Moe, SeedOutput } from '../../src/llm/schemas.ts';
import { makeLayout } from '../../src/model/layout.ts';
import { emptyState } from '../../src/orch/state.ts';
import { noteFor } from '../../src/spec/codes.ts';
import { step as stepById } from '../../src/spec/steps.ts';
import { SolverCrashedError, type Loaded, type SysproseBackend } from '../../src/sysprose/backend.ts';

type Row = AlternativeMetrics['moes'][number];
const row = (name: string, over: Partial<Row> = {}): Row => ({ name, outcome: 'optimum', value: 1, sense: 'max', target: 0.9, unit: '', met: true, ...over });
const crashedRow = (name: string): Row => ({ name, outcome: SOLVER_CRASHED_TWICE, sense: 'max', target: 0.9, unit: '', detail: 'the solver crashed (WASM trap: memory access out of bounds)' });
const alt = (k: number, moes: Row[]): AlternativeMetrics => ({
  k, elements: 10, connections: 2, unconnectedPorts: 0, orphanDefinitions: 0, functionsRealised: 1, functionsAbove: 1, repairIterations: 0, warnings: 0, moes,
});

describe('a measure whose read crashed twice', () => {
  it('leaves the measures term of every alternative, so the crash moves no score', () => {
    const before = [
      alt(1, [row('coverage', { met: false, value: 0.8 }), crashedRow('latency')]),
      alt(2, [row('coverage', { met: false, value: 0.8 }), row('latency', { met: true })]),
    ];
    // As scored before: ½ for the crash against 1 for the read that worked.
    expect(moeScore(before[0])).toBe(0.25);
    expect(moeScore(before[1])).toBe(0.5);

    const { metrics, crashed } = leaveOutCrashed(before);
    expect(crashed).toEqual([{ name: 'latency', k: 1, detail: 'the solver crashed (WASM trap: memory access out of bounds)' }]);
    expect(metrics.map((m) => m.moes.find((x) => x.name === 'latency')?.unscored)).toEqual(['solver crashed', 'solver crashed']);
    expect(metrics.map(moeScore)).toEqual([0, 0]);
    // The input is not rewritten: the record of what was read stays as read.
    expect(before[1].moes[1].unscored).toBeUndefined();
  });

  it('keeps a measure left out for another reason under that reason', () => {
    const { metrics } = leaveOutCrashed([alt(1, [{ ...crashedRow('hours'), target: undefined, unscored: 'no target' }]), alt(2, [row('hours', { unscored: 'no target' })])]);
    expect(metrics.map((m) => m.moes[0].unscored)).toEqual(['no target', 'no target']);
  });

  it('changes nothing when no read crashed', () => {
    const metrics = [alt(1, [row('coverage')]), alt(2, [row('coverage', { met: false })])];
    const out = leaveOutCrashed(metrics);
    expect(out.crashed).toEqual([]);
    expect(out.metrics).toEqual(metrics);
  });

  it('is carried on the verdict as a note naming the measure and the alternative, never blocking', () => {
    const [item] = solverFailedItems([{ name: 'latency', k: 1, detail: 'the solver crashed (WASM trap: x)' }], 'Swarm::LA::');
    expect(item).toMatchObject({ source: 'predicate', code: 'solver/failed', severity: 'warning', blocking: false, qualifiedName: 'Swarm::LA::latency' });
    expect(item.message).toContain("the solver crashed twice reading alternative 1's estimate of `latency` (the solver crashed (WASM trap: x))");
    expect(item.message).toContain('not scored for any alternative');
    expect(item.hint).toBe(noteFor('solver/failed')?.note);
    expect(noteFor('solver/failed')?.note).toContain('never blocking');
    const knobs = { modes_states: true, interfaces: true, variability: true, safety: true, views: false, verification: true, requirements_intake: false, infrastructure_intake: false } as Knobs;
    for (const severity of ['warning', 'error'] as const) expect(classifyCode('solver/failed', severity, stepById('S33'), knobs).blocking).toBe(false);
  });

  it('is shown in the trade-off, for every alternative, and to the reviewing model', () => {
    const { metrics } = leaveOutCrashed([
      alt(1, [row('coverage'), crashedRow('latency')]),
      alt(2, [row('coverage'), row('latency', { value: 0.95 })]),
    ]);
    const text = rationaleFor('LA', 2, metrics, [{ k: 1, total: 0.5, moe: 1, rubric: 0, structure: 0, resilience: 0 }, { k: 2, total: 0.6, moe: 1, rubric: 0, structure: 0, resilience: 0 }], { recommended: 2, rationale: 'x', scores: [] });
    expect(text).toContain('> **1 measure(s) not scored for any alternative: the solver crashed twice reading them** — `latency` (alternative 1).');
    expect(text.indexOf('not scored for any alternative')).toBeLessThan(text.indexOf('## Score'));
    expect(text).toContain('| 1 | `latency` | solver crashed twice | ≥ 0.9 | — (not scored: the solver crashed twice reading it for alternative 1) |');
    expect(text).toContain('| 2 | `latency` | 0.95 | ≥ 0.9 | yes (not scored: the solver crashed twice reading it for alternative 1) |');

    const latency: Moe = { name: 'latency', unit: '', sense: 'max', target: 0.9, doc: 'how fast' };
    expect(measureClaimsLines([latency], metrics).join('\n')).toContain('- `latency`: target ≥ 0.9, the solver crashed twice reading it: reported, not scored');
  });
});

describe('the trade-off step, over a solver that crashes twice on one read', () => {
  const coverage: Moe = { name: 'coverage', unit: '', sense: 'max', target: 0.9, doc: 'share watched', kind: 'measure' };
  const latency: Moe = { name: 'latency', unit: 's', sense: 'min', target: 60, doc: 'report age', kind: 'measure' };
  const brief = { systemName: 'Swarm', moes: [coverage, latency] } as unknown as SeedOutput;

  /** Each alternative states both estimates; alternative 1's latency read crashes twice. */
  const backend = (): SysproseBackend => {
    const values: Record<string, Record<string, number>> = { 'alt-1': { coverage: 0.95, latency: 40 }, 'alt-2': { coverage: 0.95, latency: 70 } };
    const fake = {
      withModel: async <T>(text: string, name: string, fn: (m: Loaded) => Promise<T> | T) =>
        fn({ model: {}, text, displayName: name, report: { summary: { errors: 0, warnings: 0 }, diagnostics: [], elements: { count: 0 } } } as unknown as Loaded),
      stats: () => ({ nodeCount: 10 }),
      connectivity: () => ({ connectionCount: 2, unconnectedPorts: [] }),
      orphans: () => ({ orphans: [] }),
      trace: () => ({ links: [] }),
      elements: () => [],
      tags: () => ({ byElement: new Map(), byKeyword: new Map(), has: () => false, taggedWith: () => [] }),
      bounds: async (m: Loaded, qn: string, sense: 'min' | 'max') => {
        const name = qn.split('::').pop()!;
        if (m.displayName === 'alt-1' && name === 'latency') throw new SolverCrashedError('memory access out of bounds');
        return { bounds: [{ sense, outcome: 'optimum', value: values[m.displayName][name] }] };
      },
    };
    return fake as unknown as SysproseBackend;
  };

  it('scores the alternatives on the same measures, says why, and hands the verdict its note', async () => {
    const dir = mkdtempSync(join(tmpdir(), 'evaluate-crash-'));
    const layout = makeLayout(dir, 'Swarm');
    layout.ensure();
    mkdirSync(layout.fragmentsDir, { recursive: true });
    for (const k of [1, 2]) writeFileSync(layout.fragmentPath('LA', k), `    package LA {\n        doc /* alternative ${k} */\n    }\n`);
    const config = loadConfig(undefined, { llmBackend: 'fake' });
    const state = emptyState({ root: 'Swarm', mode: 'autonomous', knobs: config.knobs, sysprose: { dir: '', commit: '', expected: '', matches: true } });
    state.brief = brief;
    const criteria = (score: number) => ['cohesion', 'coupling', 'realisability', 'evolvability'].map((name) => ({ name, score, reason: 'r' }));
    const llm = new FakeLlmClient({ 'S33:EVALUATE': { recommended: 1, rationale: 'scripted', scores: [{ alternative: 1, criteria: criteria(3) }, { alternative: 2, criteria: criteria(3) }] } });
    const lines: string[] = [];

    const result = await evaluateAlternatives(
      { config, layout, backend: backend(), llm, state, knobs: config.knobs, log: (l) => lines.push(l) },
      stepById('S33'),
      'LA',
      [{ k: 1, iterations: 0 }, { k: 2, iterations: 0 }],
    );

    // Retried once by the reader, crashed again: one retry counted.
    expect(result.solverRetries).toBe(1);
    // Alternative 2's 70 s misses the latency target; scored, it would have
    // cost alternative 2 against alternative 1's ½. Left out, both are judged
    // on coverage alone, and tie.
    expect(result.metrics.map((m) => m.moes.find((x) => x.name === 'latency')).map((x) => [x?.outcome, x?.unscored])).toEqual([
      [SOLVER_CRASHED_TWICE, 'solver crashed'],
      ['optimum', 'solver crashed'],
    ]);
    expect(result.scores.map((s) => s.moe)).toEqual([1, 1]);
    expect(result.items).toHaveLength(1);
    expect(result.items[0]).toMatchObject({ code: 'solver/failed', blocking: false, qualifiedName: 'Swarm::LA::latency' });
    expect(result.items[0].message).toContain("alternative 1's estimate of `latency`");
    expect(lines.join('\n')).toContain("`latency` not scored for any alternative: the solver crashed twice reading alternative 1's estimate");

    const tradeOff = readFileSync(result.rationalePath, 'utf8');
    expect(tradeOff).toContain('`latency` (alternative 1)');
    expect(tradeOff).toContain('| 2 | `latency` | 70 s | ≤ 60 s | no (not scored: the solver crashed twice reading it for alternative 1) |');
    // The reviewing model was told the same.
    expect(llm.requests[0].user).toContain('`latency`: target ≤ 60 s, the solver crashed twice reading it: reported, not scored');
  });
});
