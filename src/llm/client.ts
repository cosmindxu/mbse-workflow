/**
 * One prompt, one structured answer.
 *
 * Deliberately small: the agents in this workflow do not hold conversations,
 * do not call tools and do not see the file system. Everything an agent is
 * allowed to affect goes through the object it returns, which is validated
 * before anything is written. That is what makes the run reproducible enough
 * to audit, and what lets the whole state machine be tested against a fake.
 */
import type { ZodType } from 'zod';

export interface LlmRequest<T> {
  /** `<step>:<agent>` (plus `:alt-<k>`) — the key the log and the packet use. */
  tag: string;
  system: string;
  user: string;
  schema: ZodType<T>;
  model?: string;
  timeoutMs?: number;
  maxBudgetUsd?: number;
}

export interface LlmResult<T> {
  data: T;
  raw: string;
  model: string;
  attempts: number;
  durationMs: number;
  costUsd?: number;
  usage?: { input: number; output: number };
}

export interface LlmClient {
  readonly kind: 'claude-cli' | 'fake';
  complete<T>(request: LlmRequest<T>): Promise<LlmResult<T>>;
  /**
   * What this client has spent so far — this process, which is one leg of a run.
   * `killed` counts calls the timeout ended: they may be billed and report no cost.
   */
  spent(): { calls: number; costUsd: number; durationMs: number; killed?: number };
  /**
   * Called after every call that changed `spent()`. The run saves its state
   * here: saved only when a step finished, a leg stopped mid-step lost what its
   * finished calls cost — 7.41 USD in v6.
   */
  onSpend?: () => void;
}

export class LlmError extends Error {
  readonly tag: string;
  readonly attempts: number;
  constructor(message: string, tag: string, attempts: number) {
    super(message);
    this.name = 'LlmError';
    this.tag = tag;
    this.attempts = attempts;
  }
}
