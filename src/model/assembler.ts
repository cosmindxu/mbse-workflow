/**
 * Fragments in, one model out.
 *
 * Sysprose is one file, one model. Layer references only point upward, so the
 * file that holds layers 0..n is a model in its own right — measured on the
 * reference example, every one of its seven prefixes loads clean. That is what
 * lets a step be checked against exactly the layers that exist so far, and what
 * keeps an authoring prompt down to one layer's text.
 *
 * The assembly also carries the line map. A diagnostic points into the built
 * file; the author edits a fragment; without the map every repair prompt would
 * be quoting the wrong line.
 */
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname } from 'node:path';
import { LAYERS, layerIndex, type Layer } from '../spec/layers.ts';
import type { ModelLayout } from './layout.ts';
import { sha } from './hash.ts';

export interface AssemblyOffset {
  layer: Layer;
  path: string;
  /** 1-based line of the fragment's first line inside the assembled text. */
  startLine: number;
  endLine: number;
  lines: number;
}

export interface Assembly {
  text: string;
  upTo: Layer;
  layers: Layer[];
  offsets: AssemblyOffset[];
  hash: string;
  /** Fragment hashes, by layer — what invalidation compares. */
  fragmentHashes: Partial<Record<Layer, string>>;
}

export interface AssembleOptions {
  /** Use this text for a layer instead of its fragment file (an alternative under test). */
  substitute?: Partial<Record<Layer, string>>;
}

const DEFAULT_HEADER = (root: string): string =>
  `    doc /* ${root} — layered model. One package per perspective; references point upward only. */\n`;

/** Build the model that holds every layer up to and including `upTo`. */
export function assemble(layout: ModelLayout, upTo: Layer, opts: AssembleOptions = {}): Assembly {
  const wanted = LAYERS.filter((l) => layerIndex(l) <= layerIndex(upTo));
  const header = existsSync(layout.rootHeaderPath)
    ? readFileSync(layout.rootHeaderPath, 'utf8')
    : DEFAULT_HEADER(layout.root);

  const parts: string[] = [`package ${layout.root} {\n`, header];
  const offsets: AssemblyOffset[] = [];
  const fragmentHashes: Partial<Record<Layer, string>> = {};
  // The root line plus the header block are already in front of the first fragment.
  let line = 1 + countLines(header);

  const layers: Layer[] = [];
  for (const layer of wanted) {
    const substituted = opts.substitute?.[layer];
    const path = layout.fragmentPath(layer);
    let text: string;
    if (substituted !== undefined) {
      text = substituted;
    } else if (existsSync(path)) {
      text = readFileSync(path, 'utf8');
    } else {
      // A layer with no fragment is a layer this run does not have — an intake
      // lane switched off, or a step not reached yet. Skipping it is what makes
      // the prefix "the model so far" rather than a file with a hole in it.
      continue;
    }
    if (!text.endsWith('\n')) text += '\n';
    const lines = countLines(text);
    offsets.push({ layer, path, startLine: line + 1, endLine: line + lines, lines });
    fragmentHashes[layer] = sha(text);
    parts.push(text);
    layers.push(layer);
    line += lines;
  }
  parts.push('}\n');

  const text = parts.join('');
  return { text, upTo, layers, offsets, hash: sha(text), fragmentHashes };
}

/** Write the assembly to `build/<n>_<LAYER>.sysml` and return the path. */
export function writeBuild(layout: ModelLayout, assembly: Assembly, alternative?: number): string {
  const path = layout.buildPath(assembly.upTo, alternative);
  // Derived output: the directory is this function's to make. A run that
  // checks a layout it did not create (a fixture, a contributor's copy) must
  // not fail for want of an empty folder.
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, assembly.text);
  return path;
}

/** Which fragment, and which line in it, a line of the assembled file belongs to. */
export function toFragmentLine(
  assembly: Assembly,
  prefixLine: number,
): { layer: Layer; line: number; path: string } | undefined {
  for (const o of assembly.offsets) {
    if (prefixLine >= o.startLine && prefixLine <= o.endLine) {
      return { layer: o.layer, line: prefixLine - o.startLine + 1, path: o.path };
    }
  }
  return undefined;
}

const countLines = (text: string): number => {
  if (text === '') return 0;
  const n = text.split('\n').length;
  return text.endsWith('\n') ? n - 1 : n;
};
