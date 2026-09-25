/**
 * The prefix claim, tested against the model it was measured on.
 *
 * Two things have to hold for per-layer authoring to work at all: assembling
 * every fragment must give back exactly the file they were split from (no
 * re-indenting, no lost blank line — a byte that moves moves every diagnostic
 * line with it), and each PREFIX must be a model Sysprose loads clean, because
 * that is what each step is checked against.
 */
import { describe, expect, it, beforeAll } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { assemble, toFragmentLine } from '../../src/model/assembler.ts';
import { makeLayout } from '../../src/model/layout.ts';
import { InProcessBackend } from '../../src/sysprose/inprocess.ts';
import { hasCorpus, referenceModelPath } from '../../src/config/corpus.ts';
import { AUTHORED_LAYERS, type Layer } from '../../src/spec/layers.ts';

const FIXTURE = resolve(import.meta.dirname, '../fixtures/levelcrossing');
const layout = makeLayout(FIXTURE, 'LevelCrossing');
const backend = new InProcessBackend({
  dir: process.env.SYSPROSE_DIR ?? resolve(process.env.HOME ?? '', 'sysprose'),
  expectedCommit: 'a66ba1f',
});

describe.skipIf(!hasCorpus())('assembly and prefixes', () => {
  let original: string;
  beforeAll(() => {
    original = readFileSync(referenceModelPath(), 'utf8');
  });

  it('reassembles the fragments into exactly the file they came from', () => {
    expect(assemble(layout, 'EPBS').text).toBe(original);
  });

  it('maps an assembled line back to the fragment that holds it', () => {
    const full = assemble(layout, 'EPBS');
    const oa = full.offsets.find((o) => o.layer === 'OA');
    expect(oa).toBeDefined();
    const mapped = toFragmentLine(full, oa!.startLine + 3);
    expect(mapped?.layer).toBe('OA');
    expect(mapped?.line).toBe(4);
    // And the line really is the same text on both sides.
    const fragment = readFileSync(layout.fragmentPath('OA'), 'utf8').split('\n');
    expect(fragment[3]).toBe(full.text.split('\n')[oa!.startLine + 2]);
  });

  it.each(['Kinds', 'Common', ...AUTHORED_LAYERS] as Layer[])(
    'the prefix up to %s is a model that loads clean',
    async (layer) => {
      const prefix = assemble(layout, layer);
      const report = await backend.check(prefix.text, `prefix-${layer}`);
      expect(report.diagnostics).toEqual([]);
      expect(report.ok).toBe(true);
      expect(prefix.layers).toContain(layer);
    },
  );

  it('substitutes an alternative for a layer without touching the others', () => {
    const base = assemble(layout, 'LA');
    const alt = assemble(layout, 'LA', { substitute: { LA: '    package LA {\n        doc /* alt */\n    }\n' } });
    expect(alt.text).not.toBe(base.text);
    expect(alt.text).toContain('doc /* alt */');
    expect(alt.fragmentHashes.SA).toBe(base.fragmentHashes.SA);
    expect(alt.fragmentHashes.LA).not.toBe(base.fragmentHashes.LA);
  });
});
