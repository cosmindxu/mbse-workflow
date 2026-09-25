/**
 * Hazards as the fragments state them — text, not a loaded model, because the
 * prompt that names them and the repair loop that guards them both run before
 * a model is loaded.
 */
import { existsSync, readFileSync } from 'node:fs';
import type { ModelLayout } from './layout.ts';
import { layerIndex, type Layer } from '../spec/layers.ts';

/**
 * `#Hazard requirement` declarations not tagged `#Accepted`, each as its
 * package path from the root (`SA::Hazards::CoverageGapHazard`). Comments are
 * dropped first so a brace in a doc cannot shift the nesting.
 */
export function hazardPaths(text: string): string[] {
  const code = text.replace(/\/\*[\s\S]*?\*\//g, ' ').replace(/\/\/[^\n]*/g, ' ');
  const stack: Array<string | undefined> = [];
  const out: string[] = [];
  const token = /package\s+([A-Za-z_][A-Za-z0-9_]*)\s*\{|([^\n;{}]*#Hazard\b[^\n;{}]*?\brequirement\s+(?:def\s+)?([A-Za-z_][A-Za-z0-9_]*))|\{|\}/g;
  for (const m of code.matchAll(token)) {
    if (m[1]) stack.push(m[1]);
    else if (m[2]) {
      if (!m[2].includes('#Accepted')) out.push([...stack.filter((p): p is string => p !== undefined), m[3]].join('::'));
    } else if (m[0] === '{') stack.push(undefined);
    else stack.pop();
  }
  return out;
}

/**
 * The simple names of the hazards stated at the system layers above `layer`
 * (SA, then LA) — the ones a lower layer refines by path and must not restate.
 */
export function hazardNamesAbove(layout: ModelLayout, layer: Layer): Set<string> {
  const names = new Set<string>();
  for (const above of ['SA', 'LA', 'PA'] as Layer[]) {
    if (layerIndex(above) >= layerIndex(layer)) continue;
    const path = layout.fragmentPath(above);
    if (!existsSync(path)) continue;
    for (const p of hazardPaths(readFileSync(path, 'utf8'))) names.add(p.split('::').pop()!);
  }
  return names;
}
