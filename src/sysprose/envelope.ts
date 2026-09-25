/**
 * Reading what the two Sysprose CLIs print.
 *
 * Two things make this more than `JSON.parse`. The parser can print a
 * chevrotain ambiguity warning on stdout ahead of the report, so the text is
 * cut to its first `{`. And exit code 1 does not mean one thing: for a
 * reporting subcommand it means the model did not load cleanly, for `verify`
 * and `consistency` it means REFUTED, and `bounds`, `refine`, `fault-tree` and
 * `check-behaviour` each carry a contract of their own. Branching on the number
 * without the contract is how an automation reports a refuted requirement as a
 * parse failure, so the contract is read from the command table and carried
 * beside the number.
 */
import { COMMANDS, type CommandSpec, type ExitContract } from '@sysprose/scripts/lib/sysprose-spec';

/** `npm run check` is not a subcommand and carries a contract of its own. */
export type Contract = ExitContract | 'check';
import type { CheckReport } from './types.ts';

export interface CliEnvelope<T = unknown> {
  ok: boolean;
  file: string;
  payload: T;
  payloadKey: string;
  verdict?: { exitCode: number; [k: string]: unknown };
  degraded?: { errors: number; warnings: number; diagnostics: unknown[] };
  exitCode: number;
  contract: Contract;
  /** What this exit code means under this command's contract, in one line. */
  meaning: string;
}

/** Cut the leading noise a parser warning can put ahead of the report. */
export function toJsonText(stdout: string): string {
  const at = stdout.indexOf('{');
  if (at < 0) throw new Error(`no JSON in output: ${stdout.slice(0, 200)}`);
  return stdout.slice(at);
}

export function commandSpec(name: string): CommandSpec {
  const cmd = COMMANDS.find((c) => c.name === name);
  if (!cmd) throw new Error(`unknown sysprose subcommand \`${name}\``);
  return cmd;
}

const MEANINGS: Record<Contract, Record<number, string>> = {
  report: {
    0: 'clean',
    1: 'the model did not load cleanly — the report is of what parsed',
    2: 'usage or IO error',
  },
  verify: {
    0: 'every obligation discharged non-vacuously',
    1: 'refuted',
    2: 'inconclusive, vacuous, empty, or no solver',
  },
  refine: { 0: 'every chain refines', 1: 'a chain does not refine', 2: 'inconclusive or usage error' },
  bounds: { 0: 'every bound decided', 2: 'undecided, or usage error' },
  'fault-tree': { 0: 'enumerated, no single point of failure', 1: 'a single point of failure', 2: 'usage error or unenumerable' },
  behaviour: { 0: 'holds on every reachable configuration', 1: 'refuted', 2: 'inconclusive or usage error' },
  write: { 0: 'written', 2: 'usage or IO error, or a degraded model' },
  check: { 0: 'clean', 1: 'at least one file has findings', 2: 'usage or IO error' },
};

export function meaningOf(contract: Contract, exitCode: number): string {
  return MEANINGS[contract]?.[exitCode] ?? `exit ${exitCode} under the ${contract} contract`;
}

/** One subcommand's `{ok, file, …, <payloadKey>}` envelope. */
export function parseEnvelope<T>(name: string, stdout: string, exitCode: number): CliEnvelope<T> {
  const cmd = commandSpec(name);
  const raw = JSON.parse(toJsonText(stdout)) as Record<string, unknown>;
  return {
    ok: raw.ok === true,
    file: String(raw.file ?? ''),
    payload: raw[cmd.payloadKey] as T,
    payloadKey: cmd.payloadKey,
    verdict: raw.verdict as CliEnvelope<T>['verdict'],
    degraded: raw.degraded as CliEnvelope<T>['degraded'],
    exitCode,
    contract: cmd.exitContract,
    meaning: meaningOf(cmd.exitContract, exitCode),
  };
}

/** `npm run check`'s `{ok, files: CheckReport[]}` envelope. */
export function parseCheckEnvelope(
  stdout: string,
  exitCode: number,
): { ok: boolean; files: CheckReport[]; exitCode: number; meaning: string } {
  const raw = JSON.parse(toJsonText(stdout)) as { ok: boolean; files: CheckReport[] };
  return { ok: raw.ok, files: raw.files, exitCode, meaning: meaningOf('check', exitCode) };
}
