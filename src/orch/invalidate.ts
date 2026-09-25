/**
 * What a person's edit undoes.
 *
 * Every step records the hash of each fragment it was checked against. On
 * resume, the fragments on disk are hashed again; the first layer whose hash
 * moved invalidates its own steps and everything after them, because every
 * later layer was written to realise a version of it that no longer exists.
 * Without this, contributor mode is "edit and hope": the run resumes at the
 * next pending step and the downstream layers go on tracing to elements that
 * were renamed or removed.
 *
 * Granularity is the layer, deliberately. Element-level impact would need the
 * old fragment's text, and the state file keeps hashes, not copies.
 */
import { mkdirSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { assemble } from '../model/assembler.ts';
import type { ModelLayout } from '../model/layout.ts';
import { LAYERS, layerIndex, type Layer } from '../spec/layers.ts';
import { STEPS, type StepId } from '../spec/steps.ts';
import type { RunState } from './state.ts';

export interface Invalidation {
  /** Layers whose fragment differs from what the last run checked. */
  changed: Layer[];
  /**
   * The step that wrote each changed layer. It is NOT re-run — that would hand
   * the person's edit back to the model to rewrite — it is re-checked, and
   * repaired only as far as the checker demands.
   */
  recheck: StepId[];
  /** Steps set back to pending because they were built on the old version. */
  invalidated: StepId[];
  /** The first step the resumed run will execute after the rechecks. */
  resumeAt?: StepId;
}

/** The step whose output a layer's fragment is: the last one that writes it. */
export function writerOf(layer: Layer): StepId | undefined {
  // Kinds has no step of its own: SEED writes it beside Common.
  if (layer === 'Kinds') return writerOf('Common');
  const writers = STEPS.filter(
    (s) => s.layer === layer && ['SEED', 'REQ-INTAKE', 'INFRA-INTAKE', 'AUTHOR', 'EVALUATE'].includes(s.agent),
  );
  return writers.at(-1)?.id;
}

export function invalidate(state: RunState, layout: ModelLayout): Invalidation {
  const now = assemble(layout, 'EPBS').fragmentHashes;

  // The hash each layer had when the step that saw it LAST finished — by the
  // clock, not by the step table. Step order is not recency the moment a run
  // re-enters an earlier step: after `--from-step S21`, S22..S70 still carry
  // the hashes of the previous run while S21 carries the current ones, and
  // reading the table in order hands the verdict to the stale records.
  // Measured: a resume of a run re-entered at S21 reported Common and SA as
  // edited by a person, invalidated from OA down, and would have re-authored
  // the whole model — the two hashes were its own predecessor's.
  const recorded: Partial<Record<Layer, string>> = {};
  const byRecency = STEPS.map((step) => state.steps[step.id])
    .filter((r) => r !== undefined && ['done', 'blocked'].includes(r.status) && r.fragmentHashes !== undefined)
    .sort((a, b) => (a!.finishedAt ?? a!.startedAt ?? '').localeCompare(b!.finishedAt ?? b!.startedAt ?? ''));
  for (const record of byRecency) {
    for (const [layer, hash] of Object.entries(record!.fragmentHashes!) as Array<[Layer, string]>) {
      recorded[layer] = hash;
    }
  }

  const changed = LAYERS.filter((layer) => {
    const before = recorded[layer];
    const after = now[layer];
    // A layer nobody has checked yet is not a change; a layer that was checked
    // and is now gone is.
    return before !== undefined && before !== after;
  });
  if (changed.length === 0) return { changed, recheck: [], invalidated: [] };

  // A blocked step counts: the person editing the fragment a step could not
  // repair is the flow this exists for. Measured: the edit was hashed as a
  // change, the step was not re-checked, and the author ran again — paying
  // to replace the fragment the person had just fixed.
  const recheck = changed
    .map(writerOf)
    .filter((id): id is StepId => id !== undefined && ['done', 'blocked'].includes(state.steps[id]?.status ?? ''));

  // Everything built on top of the edited layer: strictly below it, and every
  // step after the first of those. The edited layer's own steps stay done —
  // its transition and its author both produce the fragment the person just
  // replaced, and running either would replace it back.
  // An edited Kinds counts as an edited Common: SEED wrote both, and treating
  // Kinds as the layer before SEED's re-ran SEED, which rewrites Kinds and
  // undoes the edit. Measured on v5 by simulating an edit to every layer.
  const first = Math.min(...changed.map((l) => layerIndex(l === 'Kinds' ? 'Common' : l)));
  const invalidated: StepId[] = [];
  let cascading = false;
  for (const step of STEPS) {
    const record = state.steps[step.id];
    if (step.layer !== undefined && layerIndex(step.layer) > first) cascading = true;
    if (!cascading || !record || record.status === 'skipped') continue;
    if (record.status === 'done' || record.status === 'blocked') {
      record.status = 'pending';
      record.note = `invalidated: ${changed.join(', ')} changed since this step ran`;
      record.gate = undefined;
      invalidated.push(step.id);
    }
  }
  return { changed, recheck, invalidated, resumeAt: invalidated[0] };
}

/** Leave a record beside the run of what the edit cost. */
export function recordInvalidation(layout: ModelLayout, result: Invalidation): string {
  mkdirSync(layout.auditDir, { recursive: true });
  const path = resolve(layout.auditDir, `resume-${new Date().toISOString().replace(/[:.]/g, '-')}.json`);
  writeFileSync(path, `${JSON.stringify({ at: new Date().toISOString(), ...result }, null, 2)}\n`);
  return path;
}
