/**
 * The nine packages a model is written in, and the order they stack in.
 *
 * Sysprose is one file, one model — no imports, no workspace — so a layer is a
 * package inside one root package, and "the model up to layer n" is the file
 * that holds layers 0..n. In this layering, references only ever point upward
 * (A1-R-05), which is what makes that prefix a valid model on its own: measured
 * on the reference example, all seven prefixes load clean.
 */
export const LAYERS = ['Kinds', 'Common', 'Needs', 'Imposed', 'OA', 'SA', 'LA', 'PA', 'EPBS'] as const;
export type Layer = (typeof LAYERS)[number];

/** The five authored layers, in the order they are written. */
export const AUTHORED_LAYERS = ['OA', 'SA', 'LA', 'PA', 'EPBS'] as const satisfies readonly Layer[];
export type AuthoredLayer = (typeof AUTHORED_LAYERS)[number];

/** File-name prefixes: the sort order of the directory IS the assembly order. */
export const FRAGMENT_NUMBER: Record<Layer, string> = {
  Kinds: '0',
  Common: '1',
  Needs: '2',
  Imposed: '2b',
  OA: '3',
  SA: '4',
  LA: '5',
  PA: '6',
  EPBS: '7',
};

export const layerIndex = (layer: Layer): number => LAYERS.indexOf(layer);

export const fragmentFileName = (layer: Layer, alternative?: number): string =>
  `${FRAGMENT_NUMBER[layer]}_${layer}${alternative === undefined ? '' : `.alt-${alternative}`}.sysml`;

export const buildFileName = (layer: Layer): string => `${FRAGMENT_NUMBER[layer]}_${layer}.sysml`;

/** The layer an authored layer is derived from, or undefined for the first one. */
export function previousAuthoredLayer(layer: Layer): AuthoredLayer | undefined {
  const at = (AUTHORED_LAYERS as readonly Layer[]).indexOf(layer);
  return at > 0 ? AUTHORED_LAYERS[at - 1] : undefined;
}

export const isLayer = (value: string): value is Layer => (LAYERS as readonly string[]).includes(value);
