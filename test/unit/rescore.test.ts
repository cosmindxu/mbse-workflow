/**
 * A recorded trade-off scored again under the current rules: from the step's
 * recorded payloads and scores, with no model call and no solver run, appended
 * beside the record it never rewrites.
 *
 * The fixtures have the shapes a run writes: `step.json` as the EVALUATE step
 * records it, `alt-<k>/bounds-<measure>[.<sense>].json` as `bounds` reports
 * them. The record counted a target the brief no longer states and one SEED
 * set — v9's S33 and S42 counted SEED's 12 h of unattended watch.
 */
import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { rescore, rescoreHeading, rescoreSection, rescoreStep, recordedBounds, withRescore, type RecordedTradeOff } from '../../src/audit/rescore.ts';
import { SOLVER_CRASHED_TWICE, highestScoring, leaveOutCrashed, moeScore, weightedTotal, type AlternativeMetrics } from '../../src/agents/evaluate.ts';
import { hasTarget, meets, scoredMoes, unscoredBecause } from '../../src/spec/measures.ts';
import type { Moe } from '../../src/llm/schemas.ts';
import { makeLayout } from '../../src/model/layout.ts';
import type { RunState } from '../../src/orch/state.ts';

const REPO = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const WEIGHTS = { moe: 0.4, rubric: 0.35, structure: 0.25, resilience: 0.15 };

/** The brief as it stands: no target for the watch, a SEED-set mission time, a placeholder, a budget. */
const MOES: Moe[] = [
  { name: 'areaUnderWatchFraction', unit: '', sense: 'max', target: 0.9, doc: 'share watched', kind: 'measure' },
  { name: 'coverageUnderMeshJammingFraction', unit: '', sense: 'max', target: 0.75, doc: 'jammed', kind: 'measure', placeholder: true },
  { name: 'unattendedWatchDurationHours', unit: 'h', sense: 'max', doc: 'no number in the brief', kind: 'measure' },
  { name: 'missionHours', unit: 'h', sense: 'max', target: 12, doc: 'SEED set this', kind: 'measure', setBySeed: true },
  { name: 'reportAgeSeconds', unit: 's', sense: 'min', target: 60, doc: 'report age', kind: 'measure' },
  { name: 'fleetSizeMembers', unit: '', sense: 'min', target: 12, doc: 'fixed', kind: 'budget' },
];

type Row = AlternativeMetrics['moes'][number];
/** Each alternative's worst case on each measure, as the record holds it and the payloads report it. */
const VALUES: Record<number, Record<string, number>> = {
  1: { areaUnderWatchFraction: 0.78, coverageUnderMeshJammingFraction: 0.8, unattendedWatchDurationHours: 13, missionHours: 14, reportAgeSeconds: 40 },
  2: { areaUnderWatchFraction: 0.78, coverageUnderMeshJammingFraction: 0.8, unattendedWatchDurationHours: 0.7, missionHours: 0.7, reportAgeSeconds: 40 },
};
/** What the record held each measure to: the watch had a 12 h target then, and nothing was left out. */
const RECORDED_TARGETS: Record<string, number> = { areaUnderWatchFraction: 0.9, coverageUnderMeshJammingFraction: 0.75, unattendedWatchDurationHours: 12, missionHours: 12, reportAgeSeconds: 60 };

const recordedRow = (k: number, name: string): Row => {
  const moe = MOES.find((m) => m.name === name)!;
  const value = VALUES[k][name];
  const target = RECORDED_TARGETS[name];
  return { name, sense: moe.sense, target, unit: moe.unit, outcome: name === 'areaUnderWatchFraction' && k === 1 ? 'derived' : 'optimum', value, met: moe.sense === 'max' ? value >= target : value <= target, basis: `basis of ${name}` };
};
const recordedMetrics = (k: number): AlternativeMetrics => ({
  k, elements: 100, connections: 10, unconnectedPorts: 0, orphanDefinitions: 0, functionsRealised: 5, functionsAbove: 5, repairIterations: 0, warnings: 0, acceptedHazards: 0,
  moes: Object.keys(RECORDED_TARGETS).map((name) => recordedRow(k, name)),
});

/**
 * The record. Measures: alternative 1 met 4 of 5 (0.8), alternative 2 met 2
 * of 5 (0.4) — the two it lost on are the watch and SEED's mission time.
 * `decisive` gives alternative 2 the better review and resilience, so that
 * without those two measures it is the higher total.
 */
const record = (decisive: boolean): RecordedTradeOff => {
  const parts = {
    1: { moe: 0.8, rubric: decisive ? 0.5 : 0.75, structure: 0.8, resilience: decisive ? 0.5 : 0.75 },
    2: { moe: 0.4, rubric: decisive ? 0.75 : 0.5, structure: 0.8, resilience: decisive ? 0.75 : 0.5 },
  };
  const total = (p: (typeof parts)[1]) => WEIGHTS.moe * p.moe + WEIGHTS.rubric * p.rubric + WEIGHTS.structure * p.structure + WEIGHTS.resilience * p.resilience;
  return {
    chosen: 1,
    scores: [1, 2].map((k) => ({ k, ...parts[k as 1 | 2], total: total(parts[k as 1 | 2]) })),
    metrics: [recordedMetrics(1), recordedMetrics(2)],
  };
};

/** A `bounds` report as the evaluate step writes it: one row, for the sense asked. */
const report = (qn: string, sense: 'min' | 'max', outcome: string, value: number | null) => ({
  toolAbsent: false,
  measure: { qualifiedName: qn, unit: null },
  bounds: [{ sense, outcome, value, detail: `${sense} \`${qn}\` = ${value}`, siValue: value, witness: [], checks: 1 }],
  axioms: 3,
  exitCode: 0,
});

/** A run directory with S33 recorded, the way a run leaves it. */
function recordedRun(decisive: boolean, opts: { crashed?: boolean } = {}): { dir: string; audit: string } {
  const dir = mkdtempSync(join(tmpdir(), 'rescore-'));
  const audit = join(dir, 'audit', 'S33');
  for (const k of [1, 2]) {
    mkdirSync(join(audit, `alt-${k}`), { recursive: true });
    for (const moe of MOES.filter((m) => m.kind !== 'budget')) {
      if (opts.crashed && k === 1 && moe.name === 'reportAgeSeconds') continue; // a read that crashed twice writes nothing
      const qn = `Swarm::LA::${moe.name}`;
      const worst = moe.sense === 'max' ? 'min' : 'max';
      if (k === 1 && moe.name === 'areaUnderWatchFraction') {
        // Derived: the solver finds the value and cannot prove it optimal, so
        // the other sense was asked too, and the two meet.
        writeFileSync(join(audit, `alt-${k}`, `bounds-${moe.name}.json`), JSON.stringify(report(qn, worst, 'bound-without-optimality', VALUES[k][moe.name])));
        writeFileSync(join(audit, `alt-${k}`, `bounds-${moe.name}.max.json`), JSON.stringify(report(qn, 'max', 'bound-without-optimality', VALUES[k][moe.name])));
      } else {
        writeFileSync(join(audit, `alt-${k}`, `bounds-${moe.name}.json`), JSON.stringify(report(qn, worst, 'optimum', VALUES[k][moe.name])));
      }
    }
  }
  const recorded = record(decisive);
  if (opts.crashed) {
    const row = recorded.metrics[0].moes.find((x) => x.name === 'reportAgeSeconds')!;
    Object.assign(row, { outcome: SOLVER_CRASHED_TWICE, value: undefined, met: undefined, detail: 'the solver crashed (WASM trap: memory access out of bounds)' });
  }
  writeFileSync(join(audit, 'step.json'), `${JSON.stringify(recorded, null, 2)}\n`);
  writeFileSync(join(audit, 'trade-off.md'), '# LA architecture trade-off\n\n**Chosen: alternative 1**\n\n## Review\n\nas it was made\n');
  mkdirSync(join(dir, 'fragments'), { recursive: true });
  writeFileSync(join(dir, 'fragments', '5_LA.sysml'), '    package LA { }\n');
  writeFileSync(join(dir, 'state.json'), JSON.stringify({ version: 1, root: 'Swarm', brief: { moes: MOES } }));
  return { dir, audit };
}
const stateOf = (dir: string) => JSON.parse(readFileSync(join(dir, 'state.json'), 'utf8')) as RunState;

describe('re-scoring a recorded trade-off', () => {
  it('reads each worst case back from the recorded payloads, a derived one from both senses', async () => {
    const { audit } = recordedRun(false);
    const bound = recordedBounds(audit);
    expect(bound(1, 'areaUnderWatchFraction', 'min')).toMatchObject({ outcome: 'bound-without-optimality', value: 0.78 });
    expect(bound(1, 'areaUnderWatchFraction', 'max')).toMatchObject({ sense: 'max', value: 0.78 });
    // Matched by sense: the worst-case file of a floor holds no `max` row.
    expect(bound(2, 'areaUnderWatchFraction', 'max')).toBeUndefined();
    expect(bound(2, 'nothingRecorded', 'min')).toBeUndefined();

    const r = await rescore({ step: 'S33', layer: 'LA', date: '2026-10-02', recorded: record(false), moes: MOES, weights: WEIGHTS, bound });
    const area = r.measures[0].moes.find((x) => x.name === 'areaUnderWatchFraction')!;
    expect(area).toMatchObject({ outcome: 'derived', value: 0.78, met: false, source: 'payload', basis: 'basis of areaUnderWatchFraction' });
  });

  it('leaves out a measure with no target and a target SEED set, labels a placeholder, and never scores a budget', async () => {
    const { audit } = recordedRun(false);
    const r = await rescore({ step: 'S33', layer: 'LA', date: '2026-10-02', recorded: record(false), moes: MOES, weights: WEIGHTS, bound: recordedBounds(audit) });
    const one = r.measures[0].moes;
    expect(one.map((x) => x.name)).toEqual(['areaUnderWatchFraction', 'coverageUnderMeshJammingFraction', 'unattendedWatchDurationHours', 'missionHours', 'reportAgeSeconds']);
    expect(one.find((x) => x.name === 'unattendedWatchDurationHours')).toMatchObject({ unscored: 'no target', target: undefined, met: undefined });
    expect(one.find((x) => x.name === 'missionHours')).toMatchObject({ unscored: 'set by SEED', met: true });
    expect(one.find((x) => x.name === 'coverageUnderMeshJammingFraction')).toMatchObject({ placeholder: true, met: true });
    // Counted now: coverage (missed), jamming (met), report age (met) — 2/3 for both.
    expect(r.rescored.scores.map((s) => s.moe)).toEqual([2 / 3, 2 / 3]);
    expect(r.changes).toEqual([
      '`unattendedWatchDurationHours`: scored against ≥ 12 h then; now no target, not scored',
      '`missionHours`: scored against ≥ 12 h then; now ≥ 12 h set by SEED, not scored',
    ]);
  });

  it('keeps the review, structure and resilience as recorded and sums them with the configured weights', async () => {
    const { audit } = recordedRun(false);
    const recorded = record(false);
    const r = await rescore({ step: 'S33', layer: 'LA', date: '2026-10-02', recorded, moes: MOES, weights: { ...WEIGHTS, moe: 0.5 }, bound: recordedBounds(audit) });
    const [one, two] = r.rescored.scores;
    expect(one).toMatchObject({ rubric: 0.75, structure: 0.8, resilience: 0.75 });
    expect(one.total).toBeCloseTo(0.5 * (2 / 3) + 0.35 * 0.75 + 0.25 * 0.8 + 0.15 * 0.75, 12);
    expect(two.total).toBeCloseTo(0.5 * (2 / 3) + 0.35 * 0.5 + 0.25 * 0.8 + 0.15 * 0.5, 12);
    expect(r.recorded.scores).toEqual(recorded.scores);
    expect(r.changed).toBe(false);
  });

  it('says the choice would change when the record won only on a measure the rules now leave out', async () => {
    const { audit } = recordedRun(true);
    const r = await rescore({ step: 'S33', layer: 'LA', date: '2026-10-02', recorded: record(true), moes: MOES, weights: WEIGHTS, bound: recordedBounds(audit) });
    expect(r.recorded.chosen).toBe(1);
    // Recorded: 0.770 against 0.735. Without the watch and SEED's mission time: 0.717 against 0.842.
    expect(r.recorded.scores.map((s) => Number(s.total.toFixed(3)))).toEqual([0.77, 0.735]);
    expect(r.rescored.scores.map((s) => Number(s.total.toFixed(3)))).toEqual([0.717, 0.842]);
    expect(r.rescored.chosen).toBe(2);
    expect(r.changed).toBe(true);
    const section = rescoreSection(r);
    expect(section).toContain('**THE CHOICE WOULD CHANGE: alternative 2 scores highest under the current rules, and LA was built from alternative 1.**');
    expect(section).toContain('`resume --from-step S33`');
  });

  it('leaves out, for both alternatives, a measure whose read crashed twice — from the record, there being no payload', async () => {
    const { audit } = recordedRun(false, { crashed: true });
    const recorded = JSON.parse(readFileSync(join(audit, 'step.json'), 'utf8')) as RecordedTradeOff;
    const r = await rescore({ step: 'S33', layer: 'LA', date: '2026-10-02', recorded, moes: MOES, weights: WEIGHTS, bound: recordedBounds(audit) });
    const age = r.measures.map((m) => m.moes.find((x) => x.name === 'reportAgeSeconds')!);
    expect(age.map((x) => [x.outcome, x.source, x.unscored])).toEqual([
      [SOLVER_CRASHED_TWICE, 'recorded', 'solver crashed'],
      ['optimum', 'payload', 'solver crashed'],
    ]);
    // Coverage (missed) and jamming (met): ½ for both.
    expect(r.rescored.scores.map((s) => s.moe)).toEqual([0.5, 0.5]);
    expect(r.changes).toContain('`reportAgeSeconds`: scored against ≤ 60 s then; now not scored: the solver crashed twice reading it');
    expect(rescoreSection(r)).toContain('| 2 | `reportAgeSeconds` | 40 s | ≤ 60 s | yes (not scored: the solver crashed twice reading it for alternative 1) |');
  });

  it('takes a read that crashed twice from the record, even beside a payload, and so reproduces a record made under the current rules', async () => {
    const { audit } = recordedRun(false);
    // Alternative 1's coverage is derived: its worst-sense payload was written,
    // then the other sense was asked and crashed twice, so no `.max` payload.
    rmSync(join(audit, 'alt-1', 'bounds-areaUnderWatchFraction.max.json'));
    // Alternative 2's report age crashed twice on the worst sense, beside the
    // payload an earlier run of the step left in `alt-2/` (never cleared).
    const crashed = (k: number, name: string) => (k === 1 && name === 'areaUnderWatchFraction') || (k === 2 && name === 'reportAgeSeconds');
    // The record as the evaluate step now writes it: the brief's targets, and
    // each crashed measure left out for both alternatives.
    const measured = [1, 2].map((k) => ({
      ...recordedMetrics(k),
      moes: scoredMoes(MOES).map((moe): Row => {
        const outcome = crashed(k, moe.name) ? SOLVER_CRASHED_TWICE : 'optimum';
        const value = crashed(k, moe.name) ? undefined : VALUES[k][moe.name];
        return { name: moe.name, sense: moe.sense, target: hasTarget(moe) ? moe.target : undefined, unit: moe.unit, unscored: unscoredBecause(moe), outcome, value, met: crashed(k, moe.name) ? undefined : meets(moe, outcome, value) };
      }),
    }));
    const { metrics } = leaveOutCrashed(measured);
    const scores = metrics.map((m) => {
      const parts = { moe: moeScore(m), rubric: m.k === 1 ? 0.75 : 0.5, structure: 0.8, resilience: 0.5 };
      return { k: m.k, ...parts, total: weightedTotal(WEIGHTS, parts) };
    });
    const recorded: RecordedTradeOff = { chosen: highestScoring(scores), scores, metrics };

    const r = await rescore({ step: 'S33', layer: 'LA', date: '2026-10-02', recorded, moes: MOES, weights: WEIGHTS, bound: recordedBounds(audit) });
    const rows = (name: string) => r.measures.map((m) => m.moes.find((x) => x.name === name)!).map((x) => [x.outcome, x.source, x.unscored]);
    expect(rows('areaUnderWatchFraction')).toEqual([
      [SOLVER_CRASHED_TWICE, 'recorded', 'solver crashed'],
      ['optimum', 'payload', 'solver crashed'],
    ]);
    expect(rows('reportAgeSeconds')).toEqual([
      ['optimum', 'payload', 'solver crashed'],
      [SOLVER_CRASHED_TWICE, 'recorded', 'solver crashed'],
    ]);
    // Only jamming is counted, met by both. Read from the payloads alone, the
    // derived coverage scored ½ and the stale report age 1 for a read that crashed.
    expect(r.rescored.scores.map((s) => s.moe)).toEqual(metrics.map((m) => moeScore(m)));
    expect(r.rescored.scores).toEqual(recorded.scores);
    expect(r.changed).toBe(false);
    expect(r.changes).toEqual([]);
  });

  it('reports a measure new to the brief as no estimate, and one the brief dropped as no longer scored', async () => {
    const { audit } = recordedRun(false);
    const moes: Moe[] = [...MOES.filter((m) => m.name !== 'missionHours'), { name: 'newMeasure', unit: '', sense: 'max', target: 1, doc: 'new', kind: 'measure' }];
    const r = await rescore({ step: 'S33', layer: 'LA', date: '2026-10-02', recorded: record(false), moes, weights: WEIGHTS, bound: recordedBounds(audit) });
    const added = r.measures[0].moes.find((x) => x.name === 'newMeasure');
    expect(added).toMatchObject({ outcome: 'no estimate', source: 'none' });
    expect(added?.met).toBeUndefined();
    expect(r.changes).toContain('`missionHours`: scored against ≥ 12 h then; no longer a measure the brief scores');
    expect(r.changes).toContain('`newMeasure`: not in the record; now scored against ≥ 1');
  });
});

describe('the re-score on disk', () => {
  it('appends to trade-off.md below the untouched record, writes rescore.json, and writes nothing else', async () => {
    const { dir, audit } = recordedRun(false);
    const original = readFileSync(join(audit, 'trade-off.md'), 'utf8');
    const fragment = readFileSync(join(dir, 'fragments', '5_LA.sysml'), 'utf8');
    const stepJson = readFileSync(join(audit, 'step.json'), 'utf8');
    const files = readdirSync(audit, { recursive: true }).map(String).sort();

    const r = await rescoreStep(makeLayout(dir, 'Swarm'), stateOf(dir), 'S33', WEIGHTS, '2026-10-02');
    expect(r.changed).toBe(false);
    const after = readFileSync(join(audit, 'trade-off.md'), 'utf8');
    expect(after.startsWith(original.trimEnd())).toBe(true);
    expect(after).toContain(`\n${rescoreHeading('2026-10-02')}\n`);
    expect(after).toContain('**The choice stands: alternative 1.**');
    expect(after).toContain('| 1 | 0.895 | 0.842 | 0.80 | 0.67 | 0.75 | 0.80 | 0.75 |');
    expect(after).toContain('| 1 | `coverageUnderMeshJammingFraction` | 0.8 | ≥ 0.75 (placeholder) | yes |');
    expect(after).toContain('| 1 | `unattendedWatchDurationHours` | 13 h | — | — (not scored: no target) |');
    expect(after).toContain('| 2 | `missionHours` | 0.7 h | ≥ 12 h | no (not scored: target set by SEED) |');
    // No fragment, no record rewritten; one file added.
    expect(readFileSync(join(dir, 'fragments', '5_LA.sysml'), 'utf8')).toBe(fragment);
    expect(readFileSync(join(audit, 'step.json'), 'utf8')).toBe(stepJson);
    expect(readdirSync(audit, { recursive: true }).map(String).sort()).toEqual([...files, 'rescore.json'].sort());
    const json = JSON.parse(readFileSync(join(audit, 'rescore.json'), 'utf8'));
    expect(json).toMatchObject({ step: 'S33', layer: 'LA', date: '2026-10-02', changed: false, recorded: { chosen: 1 }, rescored: { chosen: 1 } });
  });

  it('replaces its own section of the same date, and keeps an earlier one', async () => {
    const { dir, audit } = recordedRun(false);
    const layout = makeLayout(dir, 'Swarm');
    await rescoreStep(layout, stateOf(dir), 'S33', WEIGHTS, '2026-10-01');
    await rescoreStep(layout, stateOf(dir), 'S33', WEIGHTS, '2026-10-02');
    const once = readFileSync(join(audit, 'trade-off.md'), 'utf8');
    await rescoreStep(layout, stateOf(dir), 'S33', WEIGHTS, '2026-10-02');
    const twice = readFileSync(join(audit, 'trade-off.md'), 'utf8');
    expect(twice).toBe(once);
    expect(twice.split('\n## Re-scored under the current rules (').length - 1).toBe(2);
    expect(twice.indexOf(rescoreHeading('2026-10-01'))).toBeLessThan(twice.indexOf(rescoreHeading('2026-10-02')));
    expect(withRescore('# T\n\nrecord\n', '## Re-scored under the current rules (2026-10-02)\n\nx\n', '2026-10-02')).toBe('# T\n\nrecord\n\n## Re-scored under the current rules (2026-10-02)\n\nx\n');
  });

  it('reads the brief from brief.json when the state has none, and refuses a step that is not a trade-off', async () => {
    const { dir } = recordedRun(false);
    writeFileSync(join(dir, 'brief.json'), JSON.stringify({ moes: MOES }));
    const r = await rescoreStep(makeLayout(dir, 'Swarm'), undefined, 'S33', WEIGHTS, '2026-10-02');
    expect(r.rescored.scores.map((s) => s.moe)).toEqual([2 / 3, 2 / 3]);
    await expect(rescoreStep(makeLayout(dir, 'Swarm'), undefined, 'S32', WEIGHTS, '2026-10-02')).rejects.toThrow('S32 is not a trade-off step');
    await expect(rescoreStep(makeLayout(dir, 'Swarm'), undefined, 'S42', WEIGHTS, '2026-10-02')).rejects.toThrow('S42 has no recorded trade-off');
  });
});

describe('mbse-workflow rescore', () => {
  const cli = (dir: string) =>
    spawnSync(process.execPath, ['--import', 'tsx', 'src/cli.ts', 'rescore', '--out', dir, '--step', 'S33'], { cwd: REPO, encoding: 'utf8', timeout: 120_000 });

  it('exits 0 when the choice stands, and 1, loudly, when it would change', () => {
    const stands = recordedRun(false);
    const ok = cli(stands.dir);
    expect(ok.status, ok.stderr).toBe(0);
    expect(ok.stdout).toContain('alternative 1: total 0.895 -> 0.842 (measures 0.80 -> 0.67)');
    expect(ok.stdout).toContain('the choice stands: alternative 1');
    expect(existsSync(join(stands.audit, 'rescore.json'))).toBe(true);

    const changes = recordedRun(true);
    const fails = cli(changes.dir);
    expect(fails.status).toBe(1);
    expect(fails.stderr).toContain('S33: THE CHOICE WOULD CHANGE — alternative 2 scores highest under the current rules, and LA was built from alternative 1.');
    expect(readFileSync(join(changes.audit, 'trade-off.md'), 'utf8')).toContain('**THE CHOICE WOULD CHANGE');
  });
});
