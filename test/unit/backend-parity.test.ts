/**
 * The in-process backend answers what the CLI answers.
 *
 * Fixtures in `test/fixtures/checks/` were recorded by running
 * `npm run sysprose -- <cmd> <example> --json --out …` against the validated
 * reference example. If a payload here drifts from one of them, the audit packets
 * this project writes stop being reproducible with the CLI — which is the whole
 * claim the packets make — so the test compares them whole rather than by
 * sampling a field or two.
 */
import { describe, expect, it, beforeAll } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { InProcessBackend } from '../../src/sysprose/inprocess.ts';
import type { Loaded } from '../../src/sysprose/backend.ts';
import { hasCorpus, referenceModelPath } from '../../src/config/corpus.ts';

const EXAMPLE = referenceModelPath();
const fixture = (name: string): any =>
  JSON.parse(readFileSync(resolve(import.meta.dirname, `../fixtures/checks/${name}.json`), 'utf8'));


const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

/**
 * Element ids are minted per load, so two runs of the same report differ in
 * every id and in nothing else. Comparing "modulo identity" is what makes the
 * comparison meaningful: each side's own `{id, qualifiedName}` pairs name the
 * elements, every id is replaced by the name it belongs to, and an id that
 * names nothing (a relationship's own id) collapses to a marker — so a link
 * that moved to a different element still fails, while a fresh uuid does not.
 */
function canonical(value: unknown): unknown {
  const names = new Map<string, string>();
  const collect = (v: unknown): void => {
    if (Array.isArray(v)) return v.forEach(collect);
    if (v && typeof v === 'object') {
      const o = v as Record<string, unknown>;
      if (typeof o.id === 'string' && typeof o.qualifiedName === 'string' && o.qualifiedName) {
        names.set(o.id, o.qualifiedName);
      }
      Object.values(o).forEach(collect);
    }
  };
  collect(value);
  const walk = (v: unknown): unknown => {
    if (typeof v === 'string') return UUID.test(v) ? (names.get(v) ?? '<opaque-id>') : v;
    if (Array.isArray(v)) return v.map(walk);
    if (v && typeof v === 'object') {
      return Object.fromEntries(Object.entries(v as Record<string, unknown>).map(([k, x]) => [k, walk(x)]));
    }
    return v;
  };
  return walk(value);
}

const backend = new InProcessBackend({
  dir: process.env.SYSPROSE_DIR ?? resolve(process.env.HOME ?? '', 'sysprose'),
  expectedCommit: 'a66ba1f',
});

// The reference model and the payloads recorded from it live in the local study
// corpus and are not committed here — `npm run record-fixtures` makes them.
describe.skipIf(!hasCorpus())('in-process backend parity with the recorded CLI payloads', () => {
  let text: string;
  let payloads: Record<string, unknown> = {};

  beforeAll(async () => {
    text = readFileSync(EXAMPLE, 'utf8');
    // One load, every report: the same discipline the checker uses.
    payloads = await backend.withModel(text, EXAMPLE, (m: Loaded) => ({
      check: m.report,
      elements: backend.elements(m),
      'trace-allocate': backend.trace(m, 'allocate'),
      'trace-trace': backend.trace(m, 'trace'),
      'trace-satisfy': backend.trace(m, 'satisfy'),
      'trace-verify': backend.trace(m, 'verify'),
      connectivity: backend.connectivity(m),
      orphans: backend.orphans(m),
      requirements: backend.requirements(m),
      stats: backend.stats(m),
      reach: backend.reach(m),
      'prompts-oa': backend.prompts(m, 'LevelCrossing::OA'),
      'where-used-dtm': backend.whereUsed(m, 'LevelCrossing::PA::detectTrainInMotion', 2),
    }));
  });

  it('loads the example cleanly', () => {
    const report = payloads.check as any;
    expect(report.ok).toBe(true);
    expect(report.diagnostics).toEqual([]);
    expect(report.elements.count).toBe(fixture('check').files[0].elements.count);
  });

  for (const [name, key] of [
    ['elements', 'elements'],
    ['trace-allocate', 'trace'],
    ['trace-trace', 'trace'],
    ['trace-satisfy', 'trace'],
    ['trace-verify', 'trace'],
    ['connectivity', 'connectivity'],
    ['orphans', 'orphans'],
    ['requirements', 'requirements'],
    ['stats', 'stats'],
    ['reach', 'reach'],
    ['prompts-oa', 'prompts'],
    ['where-used-dtm', 'whereUsed'],
  ] as const) {
    it(`${name} matches the recorded CLI payload`, () => {
      expect(canonical(payloads[name])).toEqual(canonical(fixture(name)[key]));
    });
  }
});

describe('version', () => {
  it('reports the checkout it drives and whether it is the measured commit', async () => {
    const v = await backend.version();
    expect(v.commit).toMatch(/^[0-9a-f]{7}$|^unknown$/);
    expect(v.expected).toBe('a66ba1f');
    expect(typeof v.matches).toBe('boolean');
  });
});
