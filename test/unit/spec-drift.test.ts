/**
 * The typed step table still says what the design says.
 *
 * The table in `src/spec/steps.ts` is a copy of the workflow design, kept in
 * code because a check needs a scoped post-condition the yaml cannot express.
 * A copy drifts; this is what notices. It skips when the corpus is absent,
 * because the corpus stays on the machine that has it.
 */
import { describe, expect, it } from 'vitest';
import { existsSync, readFileSync } from 'node:fs';
import { parse } from 'yaml';
import { corpusPath } from '../../src/config/corpus.ts';
import { STEPS } from '../../src/spec/steps.ts';
import { CONVENTIONS } from '../../src/spec/conventions.ts';

const designPath = corpusPath('06-agent-workflow.yaml');
// The house rules are numbered in the mapping, which is a different document.
const mappingPath = corpusPath('03-sysprose-mapping/mapping.yaml');
const has = existsSync(designPath);

interface DesignStep {
  id: string;
  name: string;
  agent: string;
  layer?: string;
  knob?: string;
  gate?: string;
  checks?: string[];
}

describe.skipIf(!has)('the step table matches the design it was copied from', () => {
  const design = parse(readFileSync(designPath, 'utf8')) as {
    steps: DesignStep[];
    knobs: Record<string, unknown>;
  };

  it('has the same steps, in the same order', () => {
    expect(STEPS.map((s) => s.id)).toEqual(design.steps.map((s) => s.id));
  });

  it('agrees on each step\'s layer, knob and gate', () => {
    for (const spec of STEPS) {
      const row = design.steps.find((s) => s.id === spec.id);
      expect(row, spec.id).toBeDefined();
      expect(spec.layer ?? undefined, `${spec.id} layer`).toBe(row?.layer ?? undefined);
      expect(spec.knob ?? undefined, `${spec.id} knob`).toBe(row?.knob ?? undefined);
      expect(spec.gate ?? undefined, `${spec.id} gate`).toBe(
        row?.gate && row.gate !== 'none' ? row.gate : undefined,
      );
    }
  });

  it('runs every command the design asks for, or says why not', () => {
    for (const spec of STEPS) {
      const row = design.steps.find((s) => s.id === spec.id);
      const asked = (row?.checks ?? []).map((c) => String(c).split(' ')[0]);
      const runs = new Set(spec.checks.map((c) => c.cmd));
      const deferred = (spec.deferredChecks ?? []).join(' ');
      for (const cmd of asked) {
        if (cmd === 'check' || runs.has(cmd as never)) continue;
        expect(deferred, `${spec.id} drops \`${cmd}\` without saying so`).toContain(cmd);
      }
    }
  });

  it('knows the same knobs', () => {
    const fromDesign = Object.keys(design.knobs).sort();
    const used = new Set(STEPS.flatMap((s) => [s.knob, ...s.checks.map((c) => (typeof c.blocking === 'object' ? c.blocking.knob : undefined))]));
    for (const knob of used) {
      if (knob) expect(fromDesign, `${knob} is not a knob of the design`).toContain(knob);
    }
  });

  it('carries every house rule the mapping numbers', () => {
    if (!existsSync(mappingPath)) return;
    const mapping = parse(readFileSync(mappingPath, 'utf8')) as { conventions: Array<{ id: string }> };
    expect(CONVENTIONS.map((c) => c.id)).toEqual(mapping.conventions.map((c) => c.id));
  });
});
