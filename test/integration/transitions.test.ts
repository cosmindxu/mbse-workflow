/**
 * A generated layer is a model.
 *
 * The transitions are the automation the whole approach was chosen for, so the
 * bar is not "it looks right": each skeleton is assembled into the prefix it
 * would really be checked in and put through the checker. A rule that emits
 * text this dialect does not accept sends every downstream step into a repair
 * loop it cannot win.
 */
import { describe, expect, it, beforeAll } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { makeLayout } from '../../src/model/layout.ts';
import { assemble } from '../../src/model/assembler.ts';
import { InProcessBackend } from '../../src/sysprose/inprocess.ts';
import { generateSkeleton, type TransitionRule } from '../../src/transition/skeleton.ts';
import { preflight } from '../../src/model/fragments.ts';
import { hasCorpus, referenceModelPath } from '../../src/config/corpus.ts';
import type { Layer } from '../../src/spec/layers.ts';
import type { Skeleton } from '../../src/transition/skeleton.ts';

const FIXTURE = resolve(import.meta.dirname, '../fixtures/levelcrossing');
const layout = makeLayout(FIXTURE, 'LevelCrossing');
const backend = new InProcessBackend({
  dir: process.env.SYSPROSE_DIR ?? resolve(process.env.HOME ?? '', 'sysprose'),
  expectedCommit: 'a66ba1f',
});

const RULES: Array<[TransitionRule, Layer, Layer]> = [
  ['T01', 'OA', 'SA'],
  ['T02', 'SA', 'LA'],
  ['T03', 'LA', 'PA'],
  ['T04', 'PA', 'EPBS'],
];

describe.skipIf(!hasCorpus())('transition skeletons', () => {
  const skeletons = new Map<TransitionRule, Skeleton>();

  beforeAll(async () => {
    const text = readFileSync(referenceModelPath(), 'utf8');
    const made = await backend.withModel(text, 'transitions', (m) =>
      RULES.map(([rule, from]) => [
        rule,
        generateSkeleton({
          rule,
          from: backend.layerView(m, from),
          root: 'LevelCrossing',
          systemName: 'LevelCrossing',
          systemEntity: rule === 'T01' ? 'authority' : undefined,
        }),
      ] as const),
    );
    for (const [rule, skeleton] of made) skeletons.set(rule, skeleton);
  });

  it.each(RULES)('%s generates a %s layer that loads clean inside its prefix', async (rule, from, to) => {
    const skeleton = skeletons.get(rule)!;
    // The prefix it would really be checked in: every layer above it, then the
    // generated one in place of the hand-written fragment.
    const assembly = assemble(layout, to, { substitute: { [to]: skeleton.text } });
    const report = await backend.check(assembly.text, `skeleton-${rule}`);
    const errors = report.diagnostics.filter((d) => d.severity === 'error');
    expect(errors.map((d) => `${d.code} ${d.message}`)).toEqual([]);
    expect(skeleton.layer).toBe(to);
  });

  it.each(RULES)('%s passes preflight', (rule, _from, to) => {
    const result = preflight(skeletons.get(rule)!.text, to, { root: 'LevelCrossing' });
    expect(result.problems.filter((p) => p.severity === 'error')).toEqual([]);
    expect(result.ok).toBe(true);
  });

  it('carries every operational activity into SA, allocated and traced', () => {
    const sa = skeletons.get('T01')!;
    expect(sa.carried.functions).toBe(4);
    expect(sa.carried.flows).toBe(2);
    // The guidance element is this project's own bookkeeping and is never
    // carried down as if it were an operational entity.
    expect(sa.text).not.toContain('oaGuidance');
    expect(sa.carried.actors).toBe(3);
    for (const fn of ['analyseRisks', 'authoriseDeparture', 'waitForAuthorisation', 'triggerDeparture']) {
      expect(sa.text).toContain(`trace ${fn} to LevelCrossing::OA::${fn};`);
      expect(sa.text).toMatch(new RegExp(`allocate ${fn} to \\w+;`));
    }
    // An activity the operational entity kept stays with the actor that had it.
    expect(sa.text).toContain('allocate waitForAuthorisation to train;');
    expect(sa.text).toContain('allocate analyseRisks to system;');
  });

  it('marks everything it could not decide with a TODO', () => {
    for (const [rule] of RULES) {
      expect(skeletons.get(rule)!.text).toContain('TODO');
    }
  });

  it('proposes one configuration item per physical part', () => {
    const epbs = skeletons.get('T04')!;
    expect(epbs.carried.parts).toBe(2);
    expect(epbs.text).toContain('trace cabinetCi to LevelCrossing::PA::cabinet;');
    expect(epbs.text).toContain('trace radarCi to LevelCrossing::PA::radar;');
  });
});
