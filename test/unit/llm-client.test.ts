/**
 * The model client: what it sends, what it accepts back, what it retries.
 */
import { describe, expect, it, vi, beforeEach } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { z } from 'zod';

const calls: Array<{ args: string[]; input: string; opts?: { env?: Record<string, string> } }> = [];
let responses: Array<{ stdout: string; err?: Error }> = [];

vi.mock('node:child_process', () => ({
  execFile: (
    _bin: string,
    args: string[],
    opts: { env?: Record<string, string> },
    cb: (err: Error | null, stdout: string) => void,
  ) => {
    const next = responses.shift() ?? { stdout: '{}' };
    let input = '';
    queueMicrotask(() => cb(next.err ?? null, next.stdout));
    return { stdin: { end: (text: string) => { input = text; calls.push({ args, input, opts }); } } };
  },
}));

const { ClaudeCliClient } = await import('../../src/llm/claude-cli.ts');
const fixture = (name: string): string =>
  readFileSync(resolve(import.meta.dirname, `../fixtures/claude/${name}.json`), 'utf8');

const schema = z.object({ greeting: z.string(), n: z.number() });

describe('the claude CLI client', () => {
  beforeEach(() => {
    calls.length = 0;
    responses = [];
  });

  it('asks for one prompt, one structured answer, and no tools', async () => {
    responses = [{ stdout: fixture('result-ok') }];
    const client = new ClaudeCliClient({ defaultModel: 'sonnet' });
    const result = await client.complete({ tag: 't', system: 'sys', user: 'ask', schema });
    const args = calls[0].args;
    expect(args).toContain('-p');
    expect(args).toContain('--output-format');
    expect(args[args.indexOf('--max-turns') + 1]).toBe('4');
    expect(args[args.indexOf('--tools') + 1]).toBe('');
    expect(args[args.indexOf('--model') + 1]).toBe('sonnet');
    // Measured on this machine: --bare answers "Not logged in" in headless mode.
    expect(args).not.toContain('--bare');
    expect(JSON.parse(args[args.indexOf('--json-schema') + 1]).properties.greeting).toBeDefined();
    expect(calls[0].input).toBe('ask');
    expect(result.data).toEqual({ greeting: 'Hello, Ada!', n: 7 });
    expect(result.costUsd).toBeCloseTo(0.352992, 5);
  });

  it('runs in an environment of its own: no session variables, project settings only', async () => {
    responses = [{ stdout: fixture('result-ok') }];
    process.env.CLAUDE_CODE_SESSION_ID = 'the-session-running-the-workflow';
    process.env.CLAUDE_EFFORT = 'max';
    process.env.PATH_MARKER = 'kept';
    try {
      const client = new ClaudeCliClient();
      await client.complete({ tag: 't', system: 's', user: 'u', schema });
      const env = calls[0].opts?.env ?? {};
      // v7: `advisorModel` in the user's settings put another model's turn inside
      // five author calls, and the session's own variables came along too.
      expect(Object.keys(env).filter((k) => /^CLAUDE/.test(k))).toEqual([]);
      expect(env.PATH_MARKER).toBe('kept');
      const args = calls[0].args;
      expect(args[args.indexOf('--setting-sources') + 1]).toBe('project');
    } finally {
      delete process.env.CLAUDE_CODE_SESSION_ID;
      delete process.env.CLAUDE_EFFORT;
      delete process.env.PATH_MARKER;
    }
  });

  it('raises the per-turn output ceiling only when asked, and reports spend after every call', async () => {
    responses = [{ stdout: fixture('result-ok') }, { stdout: fixture('result-ok') }];
    let notified = 0;
    const raised = new ClaudeCliClient({ maxOutputTokens: 128000 });
    raised.onSpend = () => { notified += 1; };
    await raised.complete({ tag: 't', system: 's', user: 'u', schema });
    expect(calls[0].opts?.env?.CLAUDE_CODE_MAX_OUTPUT_TOKENS).toBe('128000');
    expect(notified).toBe(1);
    const plain = new ClaudeCliClient();
    await plain.complete({ tag: 't', system: 's', user: 'u', schema });
    expect(calls[1].opts?.env?.CLAUDE_CODE_MAX_OUTPUT_TOKENS).toBeUndefined();
  });

  it('reads an answer that came back as fenced text', async () => {
    const loose = JSON.stringify({ is_error: false, result: '```json\n{"greeting":"hi","n":1}\n```', total_cost_usd: 0.1 });
    responses = [{ stdout: loose }];
    const client = new ClaudeCliClient();
    expect((await client.complete({ tag: 't', system: 's', user: 'u', schema })).data).toEqual({ greeting: 'hi', n: 1 });
  });

  it('says what was wrong and asks again when the answer misses a field', async () => {
    responses = [
      { stdout: JSON.stringify({ is_error: false, result: '{"greeting":"hi"}', total_cost_usd: 0.1 }) },
      { stdout: JSON.stringify({ is_error: false, structured_output: { greeting: 'hi', n: 2 }, total_cost_usd: 0.1 }) },
    ];
    const client = new ClaudeCliClient();
    const result = await client.complete({ tag: 't', system: 's', user: 'u', schema });
    expect(result.attempts).toBe(2);
    expect(calls[1].input).toContain('did not fit the schema');
    expect(calls[1].input).toContain('n');
    expect(result.data.n).toBe(2);
  });

  it('gives up after its retries, saying what it saw', async () => {
    const error = fixture('result-error');
    responses = [{ stdout: error }, { stdout: error }, { stdout: error }];
    const client = new ClaudeCliClient({ retries: 2 });
    await expect(client.complete({ tag: 't', system: 's', user: 'u', schema })).rejects.toThrow(/Not logged in/);
  });

  it('refuses to start a call once the run budget is spent', async () => {
    responses = [{ stdout: JSON.stringify({ is_error: false, structured_output: { greeting: 'a', n: 1 }, total_cost_usd: 30 }) }];
    const client = new ClaudeCliClient({ runBudgetUsd: 10 });
    await client.complete({ tag: 't1', system: 's', user: 'u', schema });
    await expect(client.complete({ tag: 't2', system: 's', user: 'u', schema })).rejects.toThrow(/budget/);
    expect(client.spent().costUsd).toBe(30);
  });

  it('counts a call the timeout killed: no cost, but a floor on what was spent', async () => {
    const killed = Object.assign(new Error('Command failed: claude -p'), { killed: true, signal: 'SIGTERM' });
    responses = [{ stdout: '', err: killed }, { stdout: JSON.stringify({ is_error: false, structured_output: { greeting: 'a', n: 1 }, total_cost_usd: 2 }) }];
    const client = new ClaudeCliClient({ retries: 1, timeoutMs: 1000 });
    await client.complete({ tag: 't', system: 's', user: 'u', schema });
    expect(client.spent()).toMatchObject({ calls: 1, costUsd: 2, killed: 1 });
  });
});
