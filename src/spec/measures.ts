/**
 * Measures of effectiveness: how they are written, bounded and scored.
 *
 * A brief measure carries `sense` — which direction is BETTER — and a target.
 * Two things went wrong with that word before this module existed: it was
 * printed as "max 0.95" under a "Held to" header, and the model copied
 * "target (max 0.95)" into its own docs for what is a floor; and it was passed
 * straight to `bounds`, whose sense is the direction to OPTIMISE. Checking a
 * floor needs the least the design can do, so the two are opposite.
 */
import type { Moe } from '../llm/schemas.ts';
import { matchingBrace } from '../model/statements.ts';

type MoeLike = Pick<Moe, 'sense' | 'target'> & { unit?: string; condition?: boolean };

/**
 * The measures the architectures are scored on. A budget — a number the brief
 * fixes, like the fleet it can field — is held by its requirement and never
 * scored: in v6 `fleetSize ≤ 12` read "met" for every alternative and added
 * nothing but a constant to the comparison.
 */
export const scoredMoes = <T extends { kind?: 'measure' | 'budget' }>(moes: readonly T[]): T[] => moes.filter((m) => m.kind !== 'budget');

/**
 * `≥ 0.95`, `≤ 10 s` — the bound a target sets, never the bare sense word.
 * A test condition is `= 0.5`: v9's "half the links jammed" was a budget with
 * sense max, written `>= 0.5` in Common — "at least half", whose mildest case
 * is the very number every estimate was computed at.
 */
export function boundText(moe: MoeLike): string {
  const op = moe.condition ? '=' : moe.sense === 'max' ? '≥' : '≤';
  return `${op} ${moe.target}${moe.unit ? ` ${moe.unit}` : ''}`;
}

/** Whether a target is not the customer's number yet: a placeholder in the brief, or one SEED set. */
export const isProvisional = (moe: { placeholder?: boolean; setBySeed?: boolean }): boolean => moe.placeholder === true || moe.setBySeed === true;

/** The optimisation that yields the worst case against the target. */
export function worstCaseSense(sense: Moe['sense']): 'min' | 'max' {
  return sense === 'max' ? 'min' : 'max';
}

/**
 * Outcomes of `bounds` that give a value the score may rely on. A
 * `bound-without-optimality` has a value but not the proof that it is the
 * tightest, so on its own it is shown and not counted; `derived` is that same
 * value confirmed as a point by asking both ways (see `worstCase`).
 */
const DECIDED = new Set(['optimum', 'supremum', 'infimum', 'derived']);
export const isDecided = (outcome: string | undefined): boolean => outcome !== undefined && DECIDED.has(outcome);

/** Whether a decided worst-case value meets the target; `undefined` when undecided. */
export function meets(moe: MoeLike, outcome: string | undefined, value: number | null | undefined): boolean | undefined {
  if (!isDecided(outcome) || value === null || value === undefined) return undefined;
  return moe.sense === 'max' ? value >= moe.target : value <= moe.target;
}

/** One `bounds` row, as much of it as the score reads. */
export interface BoundRow {
  outcome?: string;
  value?: number | null;
  detail?: string | null;
}

/**
 * The worst case of a measure, and whether it is a point.
 *
 * A literal estimate bounds to an `optimum`. A derived one — fixed by an
 * `assert constraint` over the layer's own valued attributes — is nonlinear
 * (a product of values), so z3 finds the value and cannot prove it optimal:
 * `bound-without-optimality`. Probed: 12 drones at a 40/60 duty gave 4.8
 * airborne and a derived coverage of 0.96, both that way. The robust test for
 * a point is to ask both ways: equal minimum and maximum is one value, whatever
 * the optimality code says.
 */
export async function worstCase(
  bound: (sense: 'min' | 'max') => Promise<BoundRow | undefined>,
  sense: Moe['sense'],
): Promise<{ outcome: string; value?: number; detail?: string }> {
  const worst = await bound(worstCaseSense(sense));
  const value = worst?.value ?? undefined;
  const outcome = worst?.outcome ?? 'inconclusive';
  if (isDecided(outcome) || value === undefined) return { outcome, value, detail: worst?.detail ?? undefined };
  const other = await bound(sense === 'max' ? 'max' : 'min');
  const otherValue = other?.value ?? undefined;
  if (otherValue !== undefined && Math.abs(otherValue - value) <= 1e-9 * Math.max(1, Math.abs(value)))
    return { outcome: 'derived', value, detail: worst?.detail ?? undefined };
  return { outcome, value, detail: worst?.detail ?? undefined };
}

/** The line an architecture writes to state its estimate for one measure (CV-17). */
export function estimateLine(name: string): string {
  return `#Estimate attribute ${name} :> Common::${name} = <worst-case value> { doc /* how this design gets there */ }`;
}

/**
 * The expression one layer's `assert constraint` fixes a measure to (CV-17):
 * `m == <expr>` or `<expr> == m`, read from that layer's package text. The
 * first such equation is the one Sysprose reads as the definition, and so is
 * the one returned. Undefined when the layer states the measure as a literal.
 */
export function definingExpression(layerText: string, measure: string): string | undefined {
  const open = /\bassert\s+constraint\b[^{;]*\{/g;
  for (let m = open.exec(layerText); m; m = open.exec(layerText)) {
    const start = m.index + m[0].length - 1;
    const close = matchingBrace(layerText, start);
    if (close < 0) continue;
    const body = layerText
      .slice(start + 1, close)
      .replace(/\bdoc\s*\/\*[\s\S]*?\*\//g, ' ')
      .replace(/\/\*[\s\S]*?\*\//g, ' ')
      .replace(/\/\/[^\n]*/g, ' ');
    const sides = body.split('==');
    if (sides.length !== 2) continue;
    const [lhs, rhs] = sides.map((x) => x.trim());
    if (lhs === measure) return rhs;
    if (rhs === measure) return lhs;
  }
  return undefined;
}

const EXPRESSION_WORDS = new Set(['and', 'or', 'not', 'xor', 'implies', 'true', 'false', 'null']);

/** The names an expression reads, once each, in order: the inputs of a derived estimate. */
export function expressionNames(expr: string): string[] {
  const names = expr.match(/(?<![\w.])[A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z_][A-Za-z0-9_]*)*/g) ?? [];
  return [...new Set(names.filter((n) => !EXPRESSION_WORDS.has(n)))];
}
