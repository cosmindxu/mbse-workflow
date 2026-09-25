/**
 * The CLI witness works: the final audit re-runs its headline checks through
 * the shipped Sysprose CLI, so this is the path those numbers come from.
 */
import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { runCheck, runSysprose } from '../../src/sysprose/spawn.ts';
import { toJsonText } from '../../src/sysprose/envelope.ts';
import { hasCorpus, referenceModelPath } from '../../src/config/corpus.ts';

const SYSPROSE = process.env.SYSPROSE_DIR ?? resolve(process.env.HOME ?? '', 'sysprose');
const EXAMPLE = referenceModelPath();

describe.skipIf(!hasCorpus())('sysprose CLI, spawned', () => {
  const text = readFileSync(EXAMPLE, 'utf8');

  it('checks a clean model: exit 0, no diagnostics', async () => {
    const r = await runCheck({ dir: SYSPROSE }, text);
    expect(r.exitCode).toBe(0);
    expect(r.ok).toBe(true);
    expect(r.files[0].diagnostics).toEqual([]);
    expect(r.meaning).toBe('clean');
  });

  it('reports requirement coverage, with the exit contract read from the command table', async () => {
    const r = await runSysprose<{ coverage: number; total: number }>({ dir: SYSPROSE }, 'requirements', [], text);
    expect(r.contract).toBe('report');
    expect(r.exitCode).toBe(0);
    expect(r.payloadKey).toBe('requirements');
    expect(r.payload.total).toBe(4);
    expect(r.payload.coverage).toBe(1);
  });
});

describe('envelope', () => {
  it('cuts a parser warning printed ahead of the report', () => {
    expect(toJsonText('Ambiguous Alternatives Detected: <...>\n{"ok":true}')).toBe('{"ok":true}');
  });
});
