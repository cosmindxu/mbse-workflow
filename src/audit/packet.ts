/**
 * What a reader gets instead of having been there.
 *
 * One directory per step: the verdict, every payload the checks produced, the
 * diff of what changed, and the agent's own account of what it decided. The
 * commands are in the verdict too, so a reader who does not trust any of it can
 * re-run the check themselves and compare.
 */
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { createTwoFilesPatch } from 'diff';
import type { Verdict } from '../check/checker.ts';
import type { ModelLayout } from '../model/layout.ts';
import type { StepId } from '../spec/steps.ts';

export interface PacketInput {
  layout: ModelLayout;
  step: StepId;
  verdict?: Verdict;
  /** The fragment before this step, when there was one. */
  before?: string;
  after?: string;
  fragmentPath?: string;
  rationales?: string[];
  todos?: string[];
  extra?: Record<string, unknown>;
}

export function writePacket(input: PacketInput): string {
  const dir = input.layout.auditDirFor(input.step);
  mkdirSync(dir, { recursive: true });

  if (input.verdict) {
    writeFileSync(resolve(dir, 'verdict.json'), `${JSON.stringify(summarise(input.verdict), null, 2)}\n`);
  }
  if (input.after !== undefined && input.fragmentPath) {
    writeFileSync(
      resolve(dir, 'fragment.diff'),
      createTwoFilesPatch(
        `${input.fragmentPath} (before)`,
        `${input.fragmentPath} (after)`,
        input.before ?? '',
        input.after,
      ),
    );
  }
  if (input.rationales?.length || input.todos?.length) {
    writeFileSync(resolve(dir, 'rationale.md'), rationale(input));
  }
  if (input.extra) {
    writeFileSync(resolve(dir, 'step.json'), `${JSON.stringify(input.extra, null, 2)}\n`);
  }
  return dir;
}

/** The verdict, without the payloads — those are files of their own. */
export function summarise(verdict: Verdict): Record<string, unknown> {
  return {
    step: verdict.step,
    layer: verdict.layer,
    alternative: verdict.alternative,
    blocking: verdict.blocking,
    prefix: verdict.prefixPath,
    prefixHash: verdict.prefixHash,
    elements: verdict.elementCount,
    durationMs: verdict.durationMs,
    checks: verdict.checks.map((c) => ({
      name: c.name,
      command: c.cli,
      blocking: c.blocking,
      ok: c.ok,
      durationMs: c.durationMs,
      payload: c.payloadFile,
      findings: c.items.length,
    })),
    items: verdict.items.map((i) => ({
      code: i.code,
      severity: i.severity,
      blocking: i.blocking,
      element: i.qualifiedName,
      layer: i.layer,
      line: i.fragmentLine,
      rule: i.cv,
      message: i.message,
      check: i.check,
    })),
  };
}

function rationale(input: PacketInput): string {
  const lines = [`# ${input.step}`, ''];
  for (const [i, text] of (input.rationales ?? []).entries()) {
    lines.push(i === 0 ? '## What was decided' : `## Repair ${i}`, '', text.trim(), '');
  }
  if (input.todos?.length) {
    lines.push('## Deliberately left for later', '', ...input.todos.map((t) => `- ${t}`), '');
  }
  if (input.verdict) {
    const blocking = input.verdict.items.filter((i) => i.blocking);
    const inherited = input.verdict.items.filter((i) => i.inherited !== undefined);
    const notes = input.verdict.items.filter((i) => !i.blocking && i.inherited === undefined);
    lines.push('## Checks', '');
    for (const c of input.verdict.checks) {
      lines.push(`- \`${c.name}\` ${c.ok ? 'clear' : 'has findings'} — \`${c.cli}\``);
    }
    lines.push('');
    if (blocking.length > 0) {
      lines.push('## Still blocking', '', ...blocking.map((i) => `- \`${i.code}\` ${i.qualifiedName ?? ''}: ${i.message}`), '');
    }
    if (inherited.length > 0) {
      lines.push('## Inherited from a layer above, not repaired here', '', ...inherited.map((i) => `- \`${i.code}\` (${i.inherited}) ${i.qualifiedName ?? ''}: ${i.message}`), '');
    }
    if (notes.length > 0) {
      lines.push('## Reported', '', ...notes.map((i) => `- \`${i.code}\` ${i.qualifiedName ?? ''}: ${i.message}`), '');
    }
  }
  return lines.join('\n');
}

export const readIfExists = (path: string): string | undefined =>
  existsSync(path) ? readFileSync(path, 'utf8') : undefined;
