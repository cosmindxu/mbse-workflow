/**
 * A WASM trap in z3 fails one check, which runs once more — never the run.
 *
 * The trap arrives as an uncaught exception from a solver thread, so the
 * handler is process-wide; the calls in flight are raced against it, and the
 * checker runs the abandoned check again on the fresh module.
 */
import { mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { Worker } from 'node:worker_threads';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { boundsRetried, runStepChecks, solverRetriesNote } from '../../src/check/checker.ts';
import { classifyCode, type Knobs } from '../../src/check/classify.ts';
import { makeLayout } from '../../src/model/layout.ts';
import { noteFor } from '../../src/spec/codes.ts';
import { step as stepById, type StepSpec } from '../../src/spec/steps.ts';
import { SolverCrashedError, type Loaded, type SysproseBackend } from '../../src/sysprose/backend.ts';
import { exitAfterSolverDeath, isWasmTrap, lingersAfterSolverDeath, onSolverTrap, solverCall, solverTrapCount } from '../../src/sysprose/inprocess.ts';

/** The three traps the crashed legs of 2026-10-01 died of, as their logs print them. */
const LOGGED = [
  'Aborted(Runtime error: The application has corrupted its heap memory area (address zero)!)',
  'memory access out of bounds',
  'Aborted(native code called abort())',
];

/** A throw on a worker thread, as the main thread receives it: through Node's serialisation. */
const fromWorker = (source: string): Promise<unknown> =>
  new Promise((resolve) => new Worker(source, { eval: true }).once('error', resolve));

const trap = (message: string): Error => Object.assign(new Error(message), { name: 'RuntimeError' });

describe('what counts as a trap', () => {
  it('knows the three logged traps, however they arrive', async () => {
    for (const message of LOGGED) {
      expect(isWasmTrap(new WebAssembly.RuntimeError(message)), message).toBe(true);
      expect(isWasmTrap(trap(message)), message).toBe(true);
      // By message alone, as Sysprose's own matcher reads it.
      expect(isWasmTrap(new Error(message)), message).toBe(true);
    }
  });

  it('knows a trap re-created by the worker serialisation, which is no longer a RuntimeError instance', async () => {
    const err = await fromWorker(`throw new WebAssembly.RuntimeError(${JSON.stringify(LOGGED[1])})`);
    expect(err).not.toBeInstanceOf(WebAssembly.RuntimeError);
    expect((err as Error).name).toBe('RuntimeError');
    expect(isWasmTrap(err)).toBe(true);
    // A serialised error whose message names nothing z3 says: the name is enough.
    expect(isWasmTrap(await fromWorker('throw new WebAssembly.RuntimeError("table index 7")'))).toBe(true);
  });

  it('leaves an ordinary error alone', () => {
    expect(isWasmTrap(new Error('ENOENT: no such file or directory'))).toBe(false);
    expect(isWasmTrap(new TypeError("Cannot read properties of undefined (reading 'id')"))).toBe(false);
    expect(isWasmTrap(undefined)).toBe(false);
  });
});

describe('a solver call a trap abandons', () => {
  // The handler treats a trap within 250 ms of the last as an echo of the
  // same death; each case starts well clear of the one before.
  let clock = Date.parse('2026-10-01T12:00:00Z');
  beforeEach(() => {
    vi.useFakeTimers({ toFake: ['Date'] });
    clock += 60_000;
    vi.setSystemTime(clock);
  });
  afterEach(() => {
    vi.useRealTimers();
  });

  it('rejects the call in flight with SolverCrashedError, and the next call runs', async () => {
    const before = solverTrapCount();
    const orphan = solverCall(new Promise<never>(() => {}));
    onSolverTrap(trap(LOGGED[1]));
    await expect(orphan).rejects.toBeInstanceOf(SolverCrashedError);
    await expect(orphan).rejects.toThrow(`WASM trap: ${LOGGED[1]}`);
    expect(solverTrapCount()).toBe(before + 1);
    await expect(solverCall(Promise.resolve(42))).resolves.toBe(42);
  });

  it('counts an echo of the same death without abandoning the retry', async () => {
    const before = solverTrapCount();
    const orphan = solverCall(new Promise<never>(() => {}));
    onSolverTrap(trap(LOGGED[0]));
    await expect(orphan).rejects.toBeInstanceOf(SolverCrashedError);
    let answer!: (v: string) => void;
    const retry = solverCall(new Promise<string>((resolve) => (answer = resolve)));
    vi.setSystemTime(clock + 50);
    onSolverTrap('unwind');
    answer('sat');
    await expect(retry).resolves.toBe('sat');
    expect(solverTrapCount()).toBe(before + 2);
  });

  it('ends the process only when a trap or a death was counted', () => {
    expect(lingersAfterSolverDeath(0, 0)).toBe(false);
    expect(lingersAfterSolverDeath(1, 0)).toBe(true);
    expect(lingersAfterSolverDeath(0, 1)).toBe(true);
  });

  it('ends a process whose solver died once its output is flushed, and leaves any other alone', async () => {
    onSolverTrap(trap(LOGGED[2]));
    const exit = vi.spyOn(process, 'exit').mockImplementation((() => undefined) as never);
    try {
      exitAfterSolverDeath();
      // Not at once: after stdout and stderr have drained.
      expect(exit).not.toHaveBeenCalled();
      await vi.waitFor(() => expect(exit).toHaveBeenCalledTimes(1));

      exit.mockClear();
      vi.resetModules();
      const fresh = await import('../../src/sysprose/inprocess.ts');
      expect(fresh.solverTrapCount()).toBe(0);
      fresh.exitAfterSolverDeath();
      await new Promise((r) => setTimeout(r, 50));
      expect(exit).not.toHaveBeenCalled();

      // A death Sysprose's guard found on its own, with no trap here: the
      // abandoned call's keep-alive is the same.
      vi.resetModules();
      vi.doMock('@semantics/smt/z3-bridge', async (original) => ({ ...(await original<object>()), z3DeathCount: () => 1 }));
      const guarded = await import('../../src/sysprose/inprocess.ts');
      expect(guarded.solverTrapCount()).toBe(0);
      guarded.exitAfterSolverDeath();
      await vi.waitFor(() => expect(exit).toHaveBeenCalledTimes(1));
    } finally {
      vi.doUnmock('@semantics/smt/z3-bridge');
      exit.mockRestore();
    }
  });

  it('passes a call that settles on its own straight through', async () => {
    await expect(solverCall(Promise.reject(new Error('unknown constant x')))).rejects.toThrow('unknown constant x');
    await expect(solverCall(Promise.resolve('unsat'))).resolves.toBe('unsat');
  });
});

describe('the checker runs what the solver crashed under once more', () => {
  const knobs: Knobs = {
    modes_states: true,
    interfaces: true,
    variability: true,
    safety: false,
    views: false,
    verification: true,
    requirements_intake: false,
    infrastructure_intake: false,
  };
  const step = (layer: StepSpec['layer'], checks: StepSpec['checks']): StepSpec => ({
    id: 'S41',
    name: 'AUTHOR',
    agent: 'AUTHOR',
    layer,
    uses: [],
    postconditions: [],
    checks,
    failCodes: [],
  });
  const VERIFY = step(undefined, [{ name: 'verify', cmd: 'verify', blocking: true }]);
  const brief = { systemName: 'Sys', aliases: [], moes: ['m1'], capabilities: [] };

  /**
   * A backend whose `verify` and `bounds` fail as scripted — the n-th call
   * throws the n-th entry, if any — and otherwise answer. `m1` is a derived
   * estimate at LA and PA: no literal, 0.5 both ways.
   */
  const backend = (script: { verify?: Error[]; bounds?: Error[] }) => {
    const calls = { verify: 0, bounds: 0 };
    const loaded = {
      model: {},
      report: { summary: { errors: 0 }, diagnostics: [], elements: { count: 0 } },
      text: '',
      displayName: 'fake',
    } as unknown as Loaded;
    const row = (layer: string) => ({ id: layer, qualifiedName: `Sys::${layer}::m1`, name: 'm1', metaclass: 'AttributeUsage', type: '', multiplicity: '', value: '', redefines: '', doc: 'derived' });
    const scripted = async <T>(kind: 'verify' | 'bounds', answer: T): Promise<T> => {
      const failure = script[kind]?.[calls[kind]];
      calls[kind] += 1;
      if (failure) throw failure;
      return answer;
    };
    const fake = {
      withModel: async <T>(_text: string, _name: string, fn: (m: Loaded) => Promise<T> | T) => fn(loaded),
      elements: () => [row('LA'), row('PA')],
      tags: () => ({ byElement: new Map(), byKeyword: new Map(), has: () => true, taggedWith: () => [] }),
      layerView: () => ({}),
      verify: () => scripted('verify', { summary: { proved: 1 } }),
      bounds: () => scripted('bounds', { bounds: [{ value: 0.5 }] }),
    };
    return { backend: fake as unknown as SysproseBackend, calls };
  };
  const run = (s: StepSpec, b: SysproseBackend) =>
    runStepChecks(s, { backend: b, layout: makeLayout(mkdtempSync(join(tmpdir(), 'crash-')), 'Sys'), knobs, brief });
  const crash = (n = 0) => new SolverCrashedError(LOGGED[n]);

  it('reports a check that crashed once as run again, and clear', async () => {
    const fake = backend({ verify: [crash(1)] });
    const verdict = await run(VERIFY, fake.backend);
    expect(fake.calls.verify).toBe(2);
    expect(verdict.solverRetries).toBe(1);
    expect(verdict.blocking).toBe(false);
    expect(verdict.checks[0].ok).toBe(true);
    const item = verdict.items.find((i) => i.code === 'solver/retried');
    expect(item).toMatchObject({ source: 'predicate', severity: 'warning', blocking: false, check: 'verify' });
    expect(item?.message).toContain(`WASM trap: ${LOGGED[1]}`);
    expect(item?.hint).toBe(noteFor('solver/retried')?.note);
  });

  it('fails a check that crashed twice the way any failed check fails', async () => {
    const fake = backend({ verify: [crash(1), crash(0)] });
    const verdict = await run(VERIFY, fake.backend);
    expect(fake.calls.verify).toBe(2);
    expect(verdict.solverRetries).toBe(1);
    expect(verdict.items.map((i) => i.code)).toEqual(['check/failed']);
    expect(verdict.items[0].blocking).toBe(true);
    expect(verdict.items[0].message).toContain('second attempt');
  });

  it('does not run again a check that failed for any other reason', async () => {
    const fake = backend({ verify: [new Error('unknown constant x')] });
    const verdict = await run(VERIFY, fake.backend);
    expect(fake.calls.verify).toBe(1);
    expect(verdict.solverRetries).toBe(0);
    expect(verdict.items.map((i) => i.code)).toEqual(['check/failed']);
  });

  const ESTIMATED = step('PA', [{ name: 'elements', cmd: 'elements', blocking: true, predicates: ['moe.estimated'] }]);
  const CARRIED = step('PA', [{ name: 'elements', cmd: 'elements', blocking: true, predicates: ['moe.carriedEstimate'] }]);

  it('reads an estimate again when the solver crashed under one of its bounds', async () => {
    const fake = backend({ bounds: [crash(0)] });
    const verdict = await run(ESTIMATED, fake.backend);
    // min (crashed), min again, max.
    expect(fake.calls.bounds).toBe(3);
    expect(verdict.solverRetries).toBe(1);
    expect(verdict.blocking).toBe(false);
    // The second read gave the point: the estimate is derived, not missing.
    expect(verdict.items.map((i) => i.code)).toEqual(['solver/retried']);
    expect(verdict.items[0]).toMatchObject({ blocking: false, check: 'elements' });
    expect(verdict.items[0].message).toContain('the min bound of `Sys::PA::m1`');
  });

  it('says a step whose estimate crashed twice could not be checked, never that the estimate is missing', async () => {
    const fake = backend({ bounds: [crash(0), crash(1)] });
    const verdict = await run(ESTIMATED, fake.backend);
    expect(fake.calls.bounds).toBe(2);
    expect(verdict.solverRetries).toBe(1);
    expect(verdict.items.map((i) => i.code).sort()).toEqual(['check/failed', 'solver/retried']);
    expect(verdict.items.some((i) => i.code === 'moe.estimated')).toBe(false);
    const failed = verdict.items.find((i) => i.code === 'check/failed');
    expect(failed).toMatchObject({ blocking: true, check: 'elements' });
    expect(failed?.message).toContain('the solver crashed twice reading the estimates (`Sys::PA::m1`)');
    expect(verdict.blocking).toBe(true);
  });

  it('reads a carried estimate again, and reports one that crashed twice the same way', async () => {
    const once = backend({ bounds: [crash(0)] });
    const retried = await run(CARRIED, once.backend);
    expect(retried.solverRetries).toBe(1);
    expect(retried.items.map((i) => i.code)).toEqual(['solver/retried']);

    const twice = backend({ bounds: [crash(0), crash(1)] });
    const failed = await run(CARRIED, twice.backend);
    expect(failed.solverRetries).toBe(1);
    expect(failed.items.find((i) => i.code === 'check/failed')?.message).toContain('`Sys::PA::m1`');
    expect(failed.items.find((i) => i.code === 'check/failed')?.message).toContain('`moe.carriedEstimate` says nothing');
  });

  it('reads a bound again for the trade-off and the audit, which have no check to note it on', async () => {
    const once = backend({ bounds: [crash(1)] });
    const lines: string[] = [];
    let counted = 0;
    const read = boundsRetried(once.backend, {} as Loaded, (line) => lines.push(line), () => (counted += 1));
    await expect(read('Sys::LA::m1', 'min')).resolves.toEqual({ bounds: [{ value: 0.5 }] });
    expect(once.calls.bounds).toBe(2);
    expect(counted).toBe(1);
    expect(lines).toEqual([expect.stringContaining(`the min bound of \`Sys::LA::m1\`: the solver crashed under it (WASM trap: ${LOGGED[1]})`)]);

    // Twice: thrown as the crash it is, for the reader to say so.
    const twice = backend({ bounds: [crash(0), crash(1)] });
    await expect(boundsRetried(twice.backend, {} as Loaded, () => {}, () => {})('Sys::LA::m1', 'max')).rejects.toBeInstanceOf(SolverCrashedError);
    expect(twice.calls.bounds).toBe(2);
  });

  it('never blocks on solver/retried, and says so in the run line', () => {
    for (const severity of ['warning', 'error'] as const) {
      expect(classifyCode('solver/retried', severity, stepById('S41'), knobs).blocking, severity).toBe(false);
    }
    expect(noteFor('solver/retried')?.note).toContain('never blocking');
    expect(solverRetriesNote(1)).toBe('1 solver crash, retried once');
    expect(solverRetriesNote(3)).toBe('3 solver crashes, each retried once');
  });
});
