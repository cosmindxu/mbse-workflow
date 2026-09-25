/**
 * The Sysprose CLIs as separate processes.
 *
 * The workflow does its own checking in process — a spawn costs ~3 s against
 * ~170 ms — so this is not the working path. It is here for the one job that
 * needs an independent witness: the final audit re-runs the headline checks
 * through the shipped CLI, so the packet's numbers are the numbers a reader
 * gets by typing the command themselves rather than the numbers this project
 * computed about itself. It also records the fixtures the parity test compares
 * against.
 */
import { execFile } from 'node:child_process';
import { existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { parseCheckEnvelope, parseEnvelope, type CliEnvelope } from './envelope.ts';
import type { CheckReport } from './types.ts';

export interface SpawnOptions {
  /** The Sysprose checkout. */
  dir: string;
  timeoutMs?: number;
}

export interface CliRun<T> extends CliEnvelope<T> {
  /** The command a reader can type to get this back. */
  command: string;
  durationMs: number;
}

const runner = (dir: string): string => {
  const tsx = resolve(dir, 'node_modules/.bin/tsx');
  if (!existsSync(tsx)) throw new Error(`no tsx in ${dir}/node_modules — run npm install there`);
  return tsx;
};

function run(
  bin: string,
  args: string[],
  input: string,
  timeoutMs: number,
): Promise<{ stdout: string; stderr: string; code: number }> {
  return new Promise((resolvePromise, reject) => {
    const child = execFile(
      bin,
      args,
      { maxBuffer: 64 * 1024 * 1024, timeout: timeoutMs, encoding: 'utf8' },
      (err, stdout, stderr) => {
        // A non-zero exit is an ANSWER here, not a failure: the exit contract is
        // part of the report. Only a signal or a spawn failure is an error.
        const code = (err as (Error & { code?: number | string }) | null)?.code;
        if (err && typeof code !== 'number') return reject(err);
        resolvePromise({ stdout, stderr, code: typeof code === 'number' ? code : 0 });
      },
    );
    child.stdin?.end(input);
  });
}

/** One `sysprose <cmd> - --json` run over `text`. */
export async function runSysprose<T>(
  opts: SpawnOptions,
  cmd: string,
  args: string[],
  text: string,
): Promise<CliRun<T>> {
  const started = Date.now();
  const argv = [resolve(opts.dir, 'scripts/sysprose.ts'), cmd, '-', ...args, '--json'];
  const { stdout, code } = await run(runner(opts.dir), argv, text, opts.timeoutMs ?? 300_000);
  return {
    ...parseEnvelope<T>(cmd, stdout, code),
    command: `npm run sysprose -- ${cmd} <file> ${args.join(' ')} --json`,
    durationMs: Date.now() - started,
  };
}

/** One `npm run check -- - --json` run over `text`. */
export async function runCheck(
  opts: SpawnOptions,
  text: string,
): Promise<{ ok: boolean; files: CheckReport[]; exitCode: number; meaning: string; command: string; durationMs: number }> {
  const started = Date.now();
  const argv = [resolve(opts.dir, 'scripts/sysml-check.ts'), '-', '--json'];
  const { stdout, code } = await run(runner(opts.dir), argv, text, opts.timeoutMs ?? 300_000);
  return {
    ...parseCheckEnvelope(stdout, code),
    command: 'npm run check -- <file> --json',
    durationMs: Date.now() - started,
  };
}
