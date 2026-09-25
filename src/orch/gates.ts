/**
 * Where a person gets a say.
 *
 * The same run is autonomous or reviewed depending on which gates are armed —
 * there is no second workflow for "with a human in it". A gate that is not
 * armed is recorded as taken automatically, so the packet always says who
 * decided.
 *
 * A step that could not be repaired opens its gate whatever the mode — when it
 * HAS one. S20, S30, S31, S32, S40 and S41 have no gate (`src/spec/steps.ts`),
 * so a blocked step there stops the run with no gate request. And a gate opened
 * by a blocked step cannot release it: `machine.ts` returns after the decision
 * because the layer below would be built on a layer the checks refused. What
 * the decision does is record who saw it; the way on is an edit and a `resume`.
 */
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { createInterface } from 'node:readline/promises';
import type { ModelLayout } from '../model/layout.ts';
import type { GateId } from '../spec/steps.ts';

export interface GateRequest {
  gate: GateId;
  step: string;
  layer?: string;
  blocked: boolean;
  summary: string;
  auditDir?: string;
  items: Array<{ code: string; message: string; blocking: boolean }>;
  at: string;
}

export interface GateDecision {
  decision: 'approve' | 'reject' | 'auto';
  comments?: string;
}

export interface GateController {
  readonly kind: string;
  decide(request: GateRequest): Promise<GateDecision>;
}

/** Nobody is watching: record the decision and go on. */
export class AutoGate implements GateController {
  readonly kind = 'auto';
  async decide(): Promise<GateDecision> {
    return { decision: 'auto' };
  }
}

/**
 * A file on disk, so a run can be gated without holding a terminal open.
 *
 * The request is written, then the run waits for a decision file that
 * `mbse-workflow gate` writes. Nothing polls faster than a person can type.
 */
export class FileGate implements GateController {
  readonly kind = 'file';
  #layout: ModelLayout;
  #pollMs: number;
  #timeoutMs: number;

  constructor(layout: ModelLayout, opts: { pollMs?: number; timeoutMs?: number } = {}) {
    this.#layout = layout;
    this.#pollMs = opts.pollMs ?? 2_000;
    this.#timeoutMs = opts.timeoutMs ?? 24 * 60 * 60 * 1000;
  }

  async decide(request: GateRequest): Promise<GateDecision> {
    mkdirSync(this.#layout.gatesDir, { recursive: true });
    const requestPath = this.#layout.gateRequestPath(request.gate);
    const decisionPath = this.#layout.gateDecisionPath(request.gate);
    writeFileSync(requestPath, `${JSON.stringify(request, null, 2)}\n`);
    process.stderr.write(
      `\n  ${request.gate}: waiting for a decision.\n` +
        `    mbse-workflow gate --out ${this.#layout.dir} --gate ${request.gate} --approve\n` +
        `    mbse-workflow gate --out ${this.#layout.dir} --gate ${request.gate} --reject "<what to change>"\n`,
    );
    const until = Date.now() + this.#timeoutMs;
    while (Date.now() < until) {
      if (existsSync(decisionPath)) {
        const decision = JSON.parse(readFileSync(decisionPath, 'utf8')) as GateDecision;
        return decision;
      }
      await sleep(this.#pollMs);
    }
    throw new Error(`${request.gate}: no decision within the gate timeout`);
  }
}

/** A terminal is attached: ask. */
export class TtyGate implements GateController {
  readonly kind = 'tty';
  async decide(request: GateRequest): Promise<GateDecision> {
    const rl = createInterface({ input: process.stdin, output: process.stderr });
    try {
      process.stderr.write(`\n${request.summary}\n`);
      const answer = (await rl.question(`${request.gate}: approve? [y/N or a comment] `)).trim();
      if (answer.toLowerCase() === 'y' || answer.toLowerCase() === 'yes') return { decision: 'approve' };
      if (answer === '' || answer.toLowerCase() === 'n' || answer.toLowerCase() === 'no') {
        return { decision: 'reject' };
      }
      return { decision: 'reject', comments: answer };
    } finally {
      rl.close();
    }
  }
}

const sleep = (ms: number): Promise<void> => new Promise((r) => setTimeout(r, ms));
