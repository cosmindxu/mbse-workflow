/**
 * What an edit costs, measured on the kept v7 run — and the simulation the
 * final audit uses agrees with a real edit and a real invalidation.
 */
import { describe, expect, it } from 'vitest';
import { appendFileSync, cpSync, existsSync, mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { makeLayout } from '../../src/model/layout.ts';
import { loadState } from '../../src/orch/state.ts';
import { invalidate } from '../../src/orch/invalidate.ts';
import { contributionSurface, readCallLog } from '../../src/audit/contribution.ts';

const example = resolve(import.meta.dirname, '../../examples/drone-swarm-v7');

describe.skipIf(!existsSync(example))('contribution ease on v7', () => {
  const state = loadState(join(example, 'state.json'))!;
  const layout = makeLayout(example, state.root);
  const rows = contributionSurface(state, layout, readCallLog(layout.llmLogPath));
  const row = (layer: string) => rows.find((r) => r.layer === layer)!;

  it('re-checks the edited layer\'s writer and re-runs only what is built on it', () => {
    expect(row('SA').recheck).toEqual(['S21']);
    expect(row('SA').invalidated[0]).toBe('S30');
    expect(row('EPBS').invalidated).toEqual([]);
    // Re-running from LA costs less than re-running from SA, which costs less than from OA.
    expect(row('LA').rerunUsd).toBeLessThan(row('SA').rerunUsd);
    expect(row('SA').rerunUsd).toBeLessThan(row('OA').rerunUsd);
  });

  it('treats an edit to Kinds as an edit to Common: SEED is re-checked, never re-run', () => {
    expect(row('Kinds').recheck).toEqual(['S00']);
    expect(row('Kinds').invalidated).not.toContain('S00');
  });

  it('matches a real edit and a real invalidation, and leaves the kept run alone', () => {
    const dir = mkdtempSync(join(tmpdir(), 'contribution-'));
    try {
      cpSync(join(example, 'fragments'), join(dir, 'fragments'), { recursive: true });
      const copy = loadState(join(example, 'state.json'))!;
      const scratch = makeLayout(dir, copy.root);
      appendFileSync(scratch.fragmentPath('SA'), '\n// a reviewer\'s note\n');
      const real = invalidate(copy, scratch);
      expect(real.changed).toEqual(['SA']);
      expect(real.recheck).toEqual(row('SA').recheck);
      expect(real.invalidated).toEqual(row('SA').invalidated);
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
    expect(loadState(join(example, 'state.json'))!.steps.S30?.status).toBe('done');
  });

  it('re-checks a layer a person kept below an edit, instead of authoring it again', () => {
    const dir = mkdtempSync(join(tmpdir(), 'contribution-'));
    try {
      cpSync(join(example, 'fragments'), join(dir, 'fragments'), { recursive: true });
      const copy = loadState(join(example, 'state.json'))!;
      const scratch = makeLayout(dir, copy.root);
      appendFileSync(scratch.fragmentPath('PA'), "\n// a reviewer's note\n");
      // Measured on v9: two equations added to PA sent EPBS back to its author,
      // and the 498-line layer came back as 177 lines. Kept, EPBS is re-checked
      // against the new PA; a kept layer above the edit says nothing new.
      const real = invalidate(copy, scratch, ['EPBS', 'SA']);
      expect(real.changed).toEqual(['PA']);
      expect(real.kept).toEqual(['EPBS']);
      expect(real.recheck).toEqual(['S42', 'S50']);
      expect(real.invalidated).not.toContain('S50');
      expect(copy.steps.S50?.status).toBe('done');
      expect(real.invalidated).toEqual(['S60', 'S70']);
      // Without it, the same edit re-authors EPBS.
      expect(invalidate(loadState(join(example, 'state.json'))!, scratch).invalidated).toContain('S50');
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });

  it('re-runs nothing that produces a layer a person edited, even below the first edit', () => {
    const dir = mkdtempSync(join(tmpdir(), 'contribution-'));
    try {
      cpSync(join(example, 'fragments'), join(dir, 'fragments'), { recursive: true });
      const copy = loadState(join(example, 'state.json'))!;
      const scratch = makeLayout(dir, copy.root);
      appendFileSync(scratch.fragmentPath('SA'), "\n// a reviewer's note\n");
      appendFileSync(scratch.fragmentPath('LA'), "\n// a second reviewer's note\n");
      const real = invalidate(copy, scratch);
      expect(real.changed).toEqual(['SA', 'LA']);
      expect(real.recheck).toEqual(['S21', 'S33']);
      // LA's transition, author, alternatives and evaluation would each
      // rewrite the person's LA; its audit and everything for PA still run.
      for (const id of ['S30', 'S31', 'S32', 'S33']) expect(real.invalidated, id).not.toContain(id);
      expect(real.invalidated).toContain('S34');
      expect(real.invalidated).toContain('S40');
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });
});
