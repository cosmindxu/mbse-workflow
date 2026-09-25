/**
 * Rebuild the test fixtures from the local study corpus.
 *
 * Two kinds: the reference layered model split at its package boundaries (the
 * layer fragments a run of this workflow would have produced), and the payload
 * of every check, recorded by running the shipped Sysprose CLI over it. Neither
 * is committed — the corpus stays local — so a fresh checkout runs this once
 * before `npm test`.
 *
 *   npm run record-fixtures
 */
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { resolve } from 'node:path';
import { hasCorpus, referenceModelPath } from '../src/config/corpus.ts';
import { runCheck, runSysprose } from '../src/sysprose/spawn.ts';
import { FRAGMENT_NUMBER, type Layer } from '../src/spec/layers.ts';

const here = resolve(import.meta.dirname, '..');
const fixtures = resolve(here, 'test/fixtures');
const sysproseDir = process.env.SYSPROSE_DIR ?? resolve(homedir(), 'sysprose');

if (!hasCorpus()) {
  process.stderr.write(
    `record-fixtures: no corpus at ${referenceModelPath()}\n` +
      '  set MBSE_APPROACHES_DIR to the study corpus, or skip: the tests that need it skip themselves.\n',
  );
  process.exit(2);
}

const text = readFileSync(referenceModelPath(), 'utf8');
const lines = text.split('\n');

/* ── the model, split into layer fragments ─────────────────────────────── */
const fragDir = resolve(fixtures, 'levelcrossing/fragments');
mkdirSync(fragDir, { recursive: true });
const starts: number[] = [];
const names: Layer[] = [];
lines.forEach((line, i) => {
  const m = /^ {4}package (Kinds|Common|OA|SA|LA|PA|EPBS) /.exec(line);
  if (m) {
    starts.push(i);
    names.push(m[1] as Layer);
  }
});
let end = lines.length - 1;
while (lines[end].trim() !== '}') end -= 1;
writeFileSync(resolve(fragDir, '_root-header.txt'), `${lines.slice(1, starts[0]).join('\n')}\n`);
names.forEach((layer, k) => {
  const stop = k + 1 < starts.length ? starts[k + 1] : end;
  // Sliced verbatim, blank separator line included: the fragments have to
  // reassemble into the byte-identical file, or every diagnostic line moves.
  const body = lines.slice(starts[k], stop);
  writeFileSync(resolve(fragDir, `${FRAGMENT_NUMBER[layer]}_${layer}.sysml`), `${body.join('\n')}\n`);
  process.stdout.write(`  fragment ${FRAGMENT_NUMBER[layer]}_${layer}.sysml (${body.length} lines)\n`);
});

/* ── one recorded payload per check ────────────────────────────────────── */
const checkDir = resolve(fixtures, 'checks');
mkdirSync(checkDir, { recursive: true });
const RECORDINGS: Array<[name: string, cmd: string, args: string[]]> = [
  ['elements', 'elements', []],
  ['trace-allocate', 'trace', ['--relation', 'allocate']],
  ['trace-trace', 'trace', ['--relation', 'trace']],
  ['trace-satisfy', 'trace', ['--relation', 'satisfy']],
  ['trace-verify', 'trace', ['--relation', 'verify']],
  ['connectivity', 'connectivity', []],
  ['orphans', 'orphans', []],
  ['requirements', 'requirements', []],
  ['reach', 'reach', []],
  ['stats', 'stats', []],
  ['prompts-oa', 'prompts', ['--element', 'LevelCrossing::OA']],
  ['where-used-dtm', 'where-used', ['--element', 'LevelCrossing::PA::detectTrainInMotion', '--depth', '2']],
];

const check = await runCheck({ dir: sysproseDir }, text);
writeFileSync(resolve(checkDir, 'check.json'), `${JSON.stringify({ ok: check.ok, files: check.files }, null, 2)}\n`);
process.stdout.write(`  check exit ${check.exitCode} — ${check.meaning}\n`);

for (const [name, cmd, args] of RECORDINGS) {
  // Serial, deliberately: one Sysprose process at a time on this host.
  const run = await runSysprose({ dir: sysproseDir }, cmd, args, text);
  writeFileSync(
    resolve(checkDir, `${name}.json`),
    `${JSON.stringify({ ok: run.ok, file: run.file, [run.payloadKey]: run.payload }, null, 2)}\n`,
  );
  process.stdout.write(`  ${name} exit ${run.exitCode} (${run.durationMs} ms)\n`);
}
