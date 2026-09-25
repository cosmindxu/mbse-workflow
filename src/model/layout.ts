/**
 * Where a run keeps its files.
 *
 * The model is authored as one fragment per layer and assembled into one file
 * per layer — the fragment is what an agent writes and a reviewer edits, the
 * build is what Sysprose reads. Nothing under `build/` is ever edited: it is
 * derived, and re-derived after every change, which is what lets a contributor
 * edit a fragment mid-run without the two drifting apart.
 */
import { mkdirSync } from 'node:fs';
import { resolve } from 'node:path';
import { buildFileName, fragmentFileName, type Layer } from '../spec/layers.ts';
import type { GateId, StepId } from '../spec/steps.ts';

export interface ModelLayout {
  /** The root package name — the system's name. */
  readonly root: string;
  readonly dir: string;
  readonly briefPath: string;
  readonly briefJsonPath: string;
  readonly fragmentsDir: string;
  readonly rootHeaderPath: string;
  readonly buildDir: string;
  readonly auditDir: string;
  readonly gatesDir: string;
  readonly statePath: string;
  readonly llmLogPath: string;
  readonly finalPath: string;
  fragmentPath(layer: Layer, alternative?: number): string;
  buildPath(layer: Layer, alternative?: number): string;
  auditDirFor(step: StepId | 'final'): string;
  gateRequestPath(gate: GateId): string;
  gateDecisionPath(gate: GateId): string;
  ensure(): void;
}

export function makeLayout(dir: string, root: string): ModelLayout {
  const at = (...parts: string[]): string => resolve(dir, ...parts);
  return {
    root,
    dir: resolve(dir),
    briefPath: at('00-brief.md'),
    briefJsonPath: at('brief.json'),
    fragmentsDir: at('fragments'),
    rootHeaderPath: at('fragments/_root-header.txt'),
    buildDir: at('build'),
    auditDir: at('audit'),
    gatesDir: at('gates'),
    statePath: at('state.json'),
    llmLogPath: at('audit/llm-log.jsonl'),
    finalPath: at(`${root}.sysml`),
    fragmentPath: (layer, alternative) => at('fragments', fragmentFileName(layer, alternative)),
    // An alternative under test gets its own built file: two authors checking
    // two versions of the same layer must not write over each other.
    buildPath: (layer, alternative) =>
      at('build', alternative === undefined ? buildFileName(layer) : buildFileName(layer).replace('.sysml', `.alt-${alternative}.sysml`)),
    auditDirFor: (step) => at('audit', step),
    gateRequestPath: (gate) => at('gates', `${gate}.request.json`),
    gateDecisionPath: (gate) => at('gates', `${gate}.decision.json`),
    ensure() {
      for (const d of [dir, at('fragments'), at('build'), at('audit'), at('gates')]) {
        mkdirSync(d, { recursive: true });
      }
    },
  };
}
