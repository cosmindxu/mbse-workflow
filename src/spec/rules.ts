/**
 * Rules the system never breaks, as properties a state machine carries (CV-18).
 *
 * Probed at Sysprose 91cc4a5: a `@SysproseVerification::PropertyPattern`
 * carrier inside a `state def` is read by `check-behaviour` with no library
 * declaration in the file, returns `pass` or `fail` with a witness run, and
 * accepts a `doc` — which is how a carrier says which rule it is, since any
 * attribute beyond pattern, scope, p, q, r, s, n makes it refused. Two traps
 * the probe showed: "after Recalled, never Surveilling" fails on a drone that
 * lands and flies again, so "wins until" is `between Q and R`; and a plain
 * "never P" needs a state P that exists and is never reached, which the
 * reachability gate forbids — so it is not a kind here.
 */
export type RuleKind = 'winsUntil' | 'precededBy' | 'canAlwaysReturn';

/** The pattern a kind of rule is written with, and the fields it fills. */
export const RULE_PATTERN: Record<RuleKind, { pattern: string; scope: string; fields: string[] }> = {
  winsUntil: { pattern: 'absence', scope: 'between', fields: ['q', 'r', 'p'] },
  precededBy: { pattern: 'precedence', scope: 'globally', fields: ['p', 's'] },
  canAlwaysReturn: { pattern: 'recovery', scope: 'globally', fields: ['p'] },
};

const PLACEHOLDER: Record<string, string> = {
  q: 'the state that starts it',
  r: 'the state that ends it',
  p: 'the state that must not hold',
  s: 'the state that must come first',
};

/** The carrier to write inside the `state def` for one rule — the exact text an author copies. */
export function ruleTemplate(name: string, kind: RuleKind): string {
  const spec = RULE_PATTERN[kind];
  const hint = (f: string): string =>
    kind === 'canAlwaysReturn' && f === 'p' ? 'the state it can always get back to' : kind === 'precededBy' && f === 'p' ? 'the state that may only follow' : PLACEHOLDER[f];
  return [
    `@SysproseVerification::PropertyPattern { doc /* ${name}: <the rule in words> */`,
    `attribute pattern = "${spec.pattern}"; attribute scope = "${spec.scope}";`,
    ...spec.fields.map((f) => `attribute ${f} = "state <${hint(f)}>";`),
    '}',
  ].join(' ');
}

/** What a kind of rule says, in words a prompt or a message can use. */
export function ruleReading(kind: RuleKind): string {
  return kind === 'winsUntil'
    ? 'between the state that starts it and the state that ends it, the forbidden state never holds'
    : kind === 'precededBy'
      ? 'the second state never holds before the first has'
      : 'from every reachable configuration, the state can be reached again';
}

/** One `@SysproseVerification::PropertyPattern` carrier as written: its doc and its fields. */
export interface Carrier {
  doc: string;
  fields: Record<string, string>;
}

/**
 * Every carrier in a text, read by brace-matching from each
 * `@SysproseVerification::PropertyPattern {`. The result `check-behaviour`
 * returns echoes a carrier's fields but not its doc, so the doc — the rule's
 * name — is joined back on by the fields.
 */
export function carriersIn(text: string, matchingBrace: (text: string, open: number) => number): Carrier[] {
  const out: Carrier[] = [];
  const re = /@SysproseVerification::PropertyPattern\s*\{/g;
  for (const m of text.matchAll(re)) {
    const open = m.index! + m[0].length - 1;
    const close = matchingBrace(text, open);
    if (close < 0) continue;
    const body = text.slice(open + 1, close);
    const doc = /\bdoc\s*\/\*([\s\S]*?)\*\//.exec(body)?.[1]?.trim() ?? '';
    const fields: Record<string, string> = {};
    for (const a of body.replace(/\/\*[\s\S]*?\*\//g, ' ').matchAll(/\battribute\s+(\w+)\s*=\s*"([^"]*)"/g)) fields[a[1]] = a[2].trim();
    out.push({ doc, fields });
  }
  return out;
}

/** The rule a carrier's doc names: `RecallWins: once recalled …` → `RecallWins`. */
export const ruleNameOf = (doc: string): string | undefined => /^\s*([A-Za-z_][A-Za-z0-9_]*)\s*:/.exec(doc)?.[1];

/** Whether a carried property's fields are the carrier's (pattern, scope and every state atom). */
export function sameFields(a: Record<string, string | undefined>, b: Record<string, string | undefined>): boolean {
  return ['pattern', 'scope', 'p', 'q', 'r', 's', 'n'].every((k) => (a[k] ?? '').replace(/\s+/g, ' ').trim() === (b[k] ?? '').replace(/\s+/g, ' ').trim());
}

/** One property a machine of the layer carries, as rules.carried and rules.hold read it. */
export interface RuleRow {
  machine: string;
  owner: string;
  /** The rule the carrier's doc names, when it names one. */
  rule?: string;
  fields: Record<string, string>;
  claim: string;
  /** Sysprose's code for the verdict: `verification/unknown-atom` when a state is misnamed, say. */
  code?: string;
  detail?: string;
}

/**
 * A carrier Sysprose could not read: an attribute beyond the pattern fields,
 * or a state the machine does not have — a typo, or a template placeholder
 * left in. Both come back `inconclusive`, like a walk that hit its bound, and
 * must not pass for a carried rule.
 */
export const isUnreadable = (row: Pick<RuleRow, 'claim' | 'code' | 'detail'>): boolean =>
  row.claim !== 'pass' &&
  row.claim !== 'fail' &&
  (row.code === 'verification/malformed-property' ||
    row.code === 'verification/unknown-atom' ||
    /names no state|is not a property field|is given twice|no fields at all/.test(row.detail ?? ''));
