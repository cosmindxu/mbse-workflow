/**
 * The agents run on the `claude` CLI in headless mode.
 *
 * Measured on this machine, and the reason for the exact flag list below:
 * `--bare` answers `Not logged in` in headless mode, so it is not used;
 * without it the result JSON carries `structured_output` — the answer already
 * parsed against the schema that was handed in — plus `total_cost_usd` and the
 * token counts this project logs. `--tools ""` is what makes a call one prompt
 * and one answer: an agent here has no file system and no way to act, so
 * everything it can affect is in the object it returns.
 */
import { execFile } from 'node:child_process';
import { appendFileSync, mkdirSync } from 'node:fs';
import { dirname } from 'node:path';
import { zodToJsonSchema } from 'zod-to-json-schema';
import { LlmError, type LlmClient, type LlmRequest, type LlmResult } from './client.ts';

export interface ClaudeCliOptions {
  /** How many `claude` processes may run at once. */
  concurrency?: number;
  defaultModel?: string;
  /** Per-call ceiling handed to the CLI. */
  maxBudgetUsd?: number;
  /** The whole run's ceiling, enforced here. */
  runBudgetUsd?: number;
  timeoutMs?: number;
  /**
   * `CLAUDE_CODE_MAX_OUTPUT_TOKENS` for the child. The CLI's default for the
   * Claude 5 models is 64k per turn; v6's largest PA alternative spent 58k in
   * one turn, and a larger brief would cross it.
   */
  maxOutputTokens?: number;
  retries?: number;
  /** JSONL, one line per call. */
  logPath?: string;
  binary?: string;
}

interface ClaudeResult {
  is_error?: boolean;
  subtype?: string;
  result?: string;
  structured_output?: unknown;
  total_cost_usd?: number;
  usage?: { input_tokens?: number; output_tokens?: number };
  modelUsage?: Record<string, unknown>;
  terminal_reason?: string;
}

export class ClaudeCliClient implements LlmClient {
  readonly kind = 'claude-cli' as const;
  #opts: Required<Omit<ClaudeCliOptions, 'logPath' | 'maxBudgetUsd' | 'runBudgetUsd' | 'maxOutputTokens'>> &
    Pick<ClaudeCliOptions, 'logPath' | 'maxBudgetUsd' | 'runBudgetUsd' | 'maxOutputTokens'>;
  onSpend?: () => void;
  #inFlight = 0;
  #queue: Array<() => void> = [];
  #calls = 0;
  #killed = 0;
  #costUsd = 0;
  #durationMs = 0;

  constructor(opts: ClaudeCliOptions = {}) {
    this.#opts = {
      concurrency: opts.concurrency ?? 2,
      defaultModel: opts.defaultModel ?? 'sonnet',
      timeoutMs: opts.timeoutMs ?? 900_000,
      retries: opts.retries ?? 2,
      binary: opts.binary ?? 'claude',
      logPath: opts.logPath,
      maxBudgetUsd: opts.maxBudgetUsd,
      runBudgetUsd: opts.runBudgetUsd,
      maxOutputTokens: opts.maxOutputTokens,
    };
    if (this.#opts.logPath) mkdirSync(dirname(this.#opts.logPath), { recursive: true });
  }

  spent(): { calls: number; costUsd: number; durationMs: number; killed: number } {
    return { calls: this.#calls, costUsd: this.#costUsd, durationMs: this.#durationMs, killed: this.#killed };
  }

  async complete<T>(request: LlmRequest<T>): Promise<LlmResult<T>> {
    if (this.#opts.runBudgetUsd !== undefined && this.#costUsd >= this.#opts.runBudgetUsd) {
      throw new LlmError(
        `run budget spent (${this.#costUsd.toFixed(2)} of ${this.#opts.runBudgetUsd}) before \`${request.tag}\``,
        request.tag,
        0,
      );
    }
    await this.#acquire();
    try {
      return await this.#attempt(request);
    } finally {
      this.#release();
    }
  }

  async #attempt<T>(request: LlmRequest<T>): Promise<LlmResult<T>> {
    const schema = JSON.stringify(zodToJsonSchema(request.schema, { $refStrategy: 'none' }));
    const model = request.model ?? this.#opts.defaultModel;
    let user = request.user;
    let lastError = '';

    for (let attempt = 1; attempt <= this.#opts.retries + 1; attempt += 1) {
      const started = Date.now();
      let stdout: string;
      try {
        stdout = await this.#run(
          [
            '-p',
            '--no-session-persistence',
            '--output-format',
            'json',
            '--json-schema',
            schema,
            '--system-prompt',
            request.system,
            '--tools',
            '',
            // Not 1: with no tools there is nothing an extra turn can do, and a
            // model that thinks before it answers spends one on that — measured,
            // an opus call ended `max_turns` having returned nothing at 1.
            '--max-turns',
            '4',
            // Load the project's settings only. The user's settings are a
            // person's preferences for their own session, and they reach a
            // child `claude` too: measured in v7, `advisorModel: fable` in
            // ~/.claude/settings.json put an advisor turn by another model
            // inside five of the twenty-one author calls — the five longest and
            // dearest — so the run was neither one model nor reproducible.
            '--setting-sources',
            'project',
            '--model',
            model,
            ...(this.#opts.maxBudgetUsd !== undefined ? ['--max-budget-usd', String(this.#opts.maxBudgetUsd)] : []),
          ],
          user,
          request.timeoutMs ?? this.#opts.timeoutMs,
        );
      } catch (err) {
        lastError = err instanceof Error ? err.message : String(err);
        // A call the timeout ended returns no envelope and so no cost, but it ran
        // for the whole timeout and may be billed: one in v5 logged 4.46 USD.
        // Counted, so a run's total can say it is a floor.
        const killed = (err as { killed?: boolean }).killed === true;
        if (killed) {
          this.#killed += 1;
          this.#durationMs += Date.now() - started;
          this.onSpend?.();
        }
        this.#log({ tag: request.tag, model, attempt, ok: false, killed, error: killed ? `killed by the ${Math.round((request.timeoutMs ?? this.#opts.timeoutMs) / 1000)} s timeout` : lastError, durationMs: Date.now() - started });
        continue;
      }
      const durationMs = Date.now() - started;
      this.#calls += 1;
      this.#durationMs += durationMs;

      let result: ClaudeResult;
      try {
        result = JSON.parse(stdout) as ClaudeResult;
      } catch {
        lastError = `the CLI did not return JSON: ${stdout.slice(0, 200)}`;
        this.#log({ tag: request.tag, model, attempt, ok: false, error: lastError, durationMs });
        continue;
      }
      this.#costUsd += result.total_cost_usd ?? 0;
      this.onSpend?.();

      if (result.is_error) {
        lastError = `${result.terminal_reason ?? 'error'}: ${result.result ?? ''}`.trim();
        this.#log({ tag: request.tag, model, attempt, ok: false, error: lastError, durationMs, costUsd: result.total_cost_usd });
        // A refusal or an API error will not be fixed by asking again with the
        // same words; a transient one will. Retrying costs a call and answers
        // both, which is why the loop does not try to tell them apart.
        continue;
      }

      const candidate = result.structured_output ?? parseLoose(result.result ?? '');
      const parsed = request.schema.safeParse(candidate);
      if (parsed.success) {
        this.#log({
          tag: request.tag,
          model,
          attempt,
          ok: true,
          durationMs,
          costUsd: result.total_cost_usd,
          usage: result.usage,
        });
        return {
          data: parsed.data,
          raw: typeof result.result === 'string' ? result.result : JSON.stringify(candidate),
          model,
          attempts: attempt,
          durationMs,
          costUsd: result.total_cost_usd,
          usage: {
            input: result.usage?.input_tokens ?? 0,
            output: result.usage?.output_tokens ?? 0,
          },
        };
      }

      lastError = parsed.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`).join('; ');
      this.#log({ tag: request.tag, model, attempt, ok: false, error: `schema: ${lastError}`, durationMs, costUsd: result.total_cost_usd });
      // Say what was wrong rather than repeating the question: an answer that
      // missed one field usually comes back complete when told which one.
      user = `${request.user}\n\nYour previous answer did not fit the schema:\n${lastError}\nReturn the whole object again, with those fields corrected.`;
    }

    throw new LlmError(`\`${request.tag}\` failed after ${this.#opts.retries + 1} attempts: ${lastError}`, request.tag, this.#opts.retries + 1);
  }

  /**
   * The environment one call runs in: this process's, minus everything that
   * belongs to the Claude Code session that happens to be running the
   * workflow.
   *
   * A child `claude` inherits `CLAUDE_CODE_SESSION_ID`, the messaging socket
   * and token, the effort level and the rest, and then behaves like part of
   * that session rather than like the one prompt this workflow asked for. The
   * run has to be the same whether a person launched it from Claude Code, from
   * a terminal or from CI.
   */
  #childEnv(): NodeJS.ProcessEnv {
    const env: NodeJS.ProcessEnv = {};
    for (const [key, value] of Object.entries(process.env)) {
      if (/^CLAUDE(CODE)?(_|$)/.test(key)) continue;
      env[key] = value;
    }
    if (this.#opts.maxOutputTokens) env.CLAUDE_CODE_MAX_OUTPUT_TOKENS = String(this.#opts.maxOutputTokens);
    return env;
  }

  #run(args: string[], input: string, timeoutMs: number): Promise<string> {
    return new Promise((resolve, reject) => {
      const child = execFile(
        this.#opts.binary,
        args,
        {
          maxBuffer: 32 * 1024 * 1024,
          timeout: timeoutMs,
          encoding: 'utf8',
          env: this.#childEnv(),
        },
        (err, stdout) => {
          // A non-zero exit still prints the result envelope, and the envelope
          // says more than the code does — so it is parsed either way, and only
          // an empty one is an error.
          if (stdout && stdout.trim().startsWith('{')) return resolve(stdout);
          if (err) return reject(err);
          resolve(stdout);
        },
      );
      child.stdin?.end(input);
    });
  }

  #log(entry: Record<string, unknown>): void {
    if (!this.#opts.logPath) return;
    appendFileSync(this.#opts.logPath, `${JSON.stringify({ ts: new Date().toISOString(), ...entry })}\n`);
  }

  #acquire(): Promise<void> {
    if (this.#inFlight < this.#opts.concurrency) {
      this.#inFlight += 1;
      return Promise.resolve();
    }
    return new Promise((resolve) => {
      this.#queue.push(() => {
        this.#inFlight += 1;
        resolve();
      });
    });
  }

  #release(): void {
    this.#inFlight -= 1;
    this.#queue.shift()?.();
  }
}

/** An answer that came back as text: fenced, or with a sentence around it. */
function parseLoose(text: string): unknown {
  const fenced = /```(?:json)?\s*\n([\s\S]*?)\n\s*```/.exec(text);
  const body = fenced ? fenced[1] : text;
  try {
    return JSON.parse(body);
  } catch {
    const at = body.indexOf('{');
    const to = body.lastIndexOf('}');
    if (at >= 0 && to > at) {
      try {
        return JSON.parse(body.slice(at, to + 1));
      } catch {
        return undefined;
      }
    }
    return undefined;
  }
}
