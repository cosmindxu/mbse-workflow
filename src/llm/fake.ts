/**
 * The client the tests use.
 *
 * Scripted by tag, so a test can say "AUTHOR-OA returns this broken fragment,
 * then this good one" and watch the repair loop do its job. It records every
 * request, which is how the prompt-building tests assert what an agent was
 * actually told.
 */
import type { LlmClient, LlmRequest, LlmResult } from './client.ts';
import { LlmError } from './client.ts';

export type FakeScript = Record<string, unknown | unknown[] | Error>;

export class FakeLlmClient implements LlmClient {
  readonly kind = 'fake' as const;
  readonly requests: Array<LlmRequest<unknown>> = [];
  #script: FakeScript;
  #used = new Map<string, number>();
  #calls = 0;

  constructor(script: FakeScript) {
    this.#script = script;
  }

  async complete<T>(request: LlmRequest<T>): Promise<LlmResult<T>> {
    this.requests.push(request as LlmRequest<unknown>);
    this.#calls += 1;
    const key = Object.keys(this.#script)
      .filter((k) => request.tag === k || request.tag.startsWith(k))
      .sort((a, b) => b.length - a.length)[0];
    if (key === undefined) throw new LlmError(`fake client has no answer for \`${request.tag}\``, request.tag, 1);
    const entry = this.#script[key];
    if (entry instanceof Error) throw entry;
    let value: unknown = entry;
    if (Array.isArray(entry)) {
      const at = this.#used.get(key) ?? 0;
      value = entry[Math.min(at, entry.length - 1)];
      this.#used.set(key, at + 1);
    }
    if (value instanceof Error) throw value;
    // Validated exactly like a real answer: a fixture that does not fit the
    // schema is a test bug worth failing on, not a shortcut.
    const parsed = request.schema.safeParse(value);
    if (!parsed.success) {
      throw new LlmError(`fake answer for \`${request.tag}\` does not fit the schema: ${parsed.error.message}`, request.tag, 1);
    }
    this.onSpend?.();
    return {
      data: parsed.data,
      raw: JSON.stringify(value),
      model: 'fake',
      attempts: 1,
      durationMs: 0,
      costUsd: 0,
    };
  }

  onSpend?: () => void;

  spent(): { calls: number; costUsd: number; durationMs: number; killed: number } {
    return { calls: this.#calls, costUsd: 0, durationMs: 0, killed: 0 };
  }
}
