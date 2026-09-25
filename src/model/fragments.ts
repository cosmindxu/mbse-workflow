/**
 * What an authoring agent hands back, before Sysprose ever sees it.
 *
 * A model that does not parse costs a full load to find out, and the answer is
 * usually one of four things an LLM does: wrapping the answer in a markdown
 * fence, re-declaring the root package, importing another layer, or naming a
 * feature after a keyword. All four are decidable on the text alone, so they
 * are decided here — the repair loop is for findings about the MODEL, not for
 * shipping-format mistakes.
 */
import { isReservedName } from '../spec/keywords.ts';
import type { Layer } from '../spec/layers.ts';

export interface PreflightProblem {
  code: string;
  message: string;
  /** 1-based, in the fragment. */
  line?: number;
  severity: 'error' | 'warning';
}

export interface PreflightResult {
  ok: boolean;
  /** The cleaned fragment: fences removed, indentation normalised. */
  fragment: string;
  problems: PreflightProblem[];
}

const FENCE = /^\s*```[a-zA-Z]*\s*\n([\s\S]*?)\n\s*```\s*$/;

/** Declarations whose name is the token right after the keyword. */
const DECLARATION =
  /\b(?:part|port|item|action|state|flow|connection|interface|attribute|requirement|constraint|occurrence|use case|view|viewpoint|concern|enum|calc|analysis|verification|metadata|accept|send)\s+(?:def\s+)?([A-Za-z_][A-Za-z0-9_]*)\b/g;

/**
 * `#Tag` goes before the keyword. Measured: one `attribute #Variant x : Boolean {`
 * — the tag after the keyword — and the parser recovered by closing scopes, so
 * ten connections after it sat at the root with one endpoint each and the
 * layer's closing brace was "input not parsed". Forty-five findings from one
 * misplaced word, and a repair prompt that led with the forty-four
 * consequences. The placement is a fact about the grammar, not a decision, so
 * it is corrected here.
 */
const TAG_AFTER_KEYWORD =
  /^(\s*)((?:(?:in|out|inout|ref|abstract|readonly|derived|variation|variant|individual)\s+)*)((?:use case|item|attribute|port|part|action|state|connection|interface|requirement|flow|occurrence|enum|calc|constraint|concern|view|viewpoint|verification|analysis|metadata)\s+(?:def\s+)?)((?:#[\w']+\s+)+)/gm;

export function normaliseTagPlacement(text: string): { text: string; moved: number } {
  let moved = 0;
  const out = text.replace(TAG_AFTER_KEYWORD, (_m, indent: string, mods: string, keyword: string, tags: string) => {
    moved += 1;
    return `${indent}${tags.trim()} ${mods}${keyword}`;
  });
  return { text: out, moved };
}

/**
 * A doc is a comment, not a string. Measured: one answer wrote every one of
 * its 101 docs as `doc "…";` and produced 114 parse errors — the grammar
 * expects `doc /* … *​/`. The intent is unmistakable and the rewrite is
 * mechanical, so it is done here; a `*​/` inside the text is defused.
 */
const DOC_STRING = /\b(doc|comment)\s+(["'])((?:\\.|(?!\2)[^\\])*)\2\s*;?/g;

export function normaliseDocStrings(text: string): { text: string; rewritten: number } {
  let rewritten = 0;
  const out = text.replace(DOC_STRING, (_m, keyword: string, _q: string, body: string) => {
    rewritten += 1;
    const clean = body.replace(/\\(["'])/g, '$1').replace(/\*\//g, '* /');
    return `${keyword} /* ${clean} */`;
  });
  return { text: out, rewritten };
}

/**
 * The dialect has no entry pseudostate. `entry;` is read as a state behaviour
 * with no name and `transition entry -> S;` resolves to nothing. Measured: the
 * configuration-item layer of the third run opened sixteen state machines this
 * way, 32 of the model's 74 warnings. What the author meant is the initial
 * state, and the dialect's way to say it is `initial start;` — so this is a
 * rewrite, not a deletion. `entry action x;` is a real construct and untouched.
 */
const ENTRY_PAIR = /^([ \t]*)entry[ \t]*;[ \t]*\n([ \t]*)transition[ \t]+entry[ \t]*->[ \t]*([A-Za-z_][A-Za-z0-9_]*)[ \t]*;/gm;
const ENTRY_TRANSITION = /^([ \t]*)transition[ \t]+entry[ \t]*->[ \t]*([A-Za-z_][A-Za-z0-9_]*)[ \t]*;/gm;
const ENTRY_BARE = /^[ \t]*entry[ \t]*;[ \t]*\n/gm;

export function normaliseEntryPseudostates(text: string): { text: string; rewritten: number } {
  let rewritten = 0;
  let out = text.replace(ENTRY_PAIR, (_m, i1: string, i2: string, target: string) => {
    rewritten += 1;
    return `${i1}initial start;\n${i2}transition start -> ${target};`;
  });
  out = out.replace(ENTRY_TRANSITION, (_m, indent: string, target: string) => {
    rewritten += 1;
    return `${indent}initial start;\n${indent}transition start -> ${target};`;
  });
  out = out.replace(ENTRY_BARE, () => {
    rewritten += 1;
    return '';
  });
  return { text: out, rewritten };
}

export function preflight(text: string, layer: Layer, opts: { root?: string } = {}): PreflightResult {
  const problems: PreflightProblem[] = [];
  // Only the ends: the leading spaces of the first line are part of the
  // indentation `indent` is about to normalise.
  let body = text.replace(/\r\n/g, '\n').replace(/^[ \t]*\n+/, '').trimEnd();

  const fenced = FENCE.exec(body);
  if (fenced) {
    body = fenced[1];
    problems.push({
      code: 'preflight/markdown-fence',
      severity: 'warning',
      message: 'the fragment came wrapped in a markdown fence; it was stripped. Return the model text alone.',
    });
  }

  if (opts.root) {
    const rootDecl = new RegExp(`^\\s*package\\s+${escape(opts.root)}\\b`, 'm');
    if (rootDecl.test(body)) {
      problems.push({
        code: 'preflight/root-package',
        severity: 'error',
        message: `the fragment re-declares the root package \`${opts.root}\`. Write only \`package ${layer} { … }\` — the root is added when the layers are assembled.`,
        line: lineOf(body, rootDecl),
      });
    }
  }

  const opens = new RegExp(`^\\s*package\\s+${layer}\\s*\\{`, 'm');
  if (!opens.test(body)) {
    problems.push({
      code: 'preflight/wrong-package',
      severity: 'error',
      message: `the fragment must be exactly one \`package ${layer} { … }\`.`,
      line: 1,
    });
  }

  const importAt = /^\s*(?:private\s+|public\s+)?import\b/m;
  if (importAt.test(body)) {
    problems.push({
      code: 'preflight/import',
      severity: 'error',
      message: 'no imports: Sysprose is one file and layers reference each other by qualified name (CV-01).',
      line: lineOf(body, importAt),
    });
  }

  const docs = normaliseDocStrings(body);
  if (docs.rewritten > 0) {
    body = docs.text;
    problems.push({
      code: 'preflight/doc-string',
      severity: 'warning',
      message: `${docs.rewritten} doc(s) were written as a quoted string and rewritten as \`doc /* … */\`, which is what the grammar reads.`,
    });
  }

  const entry = normaliseEntryPseudostates(body);
  if (entry.rewritten > 0) {
    body = entry.text;
    problems.push({
      code: 'preflight/entry-pseudostate',
      severity: 'warning',
      message: `${entry.rewritten} \`entry;\` pseudostate(s) rewritten as \`initial start; transition start -> S;\` — this dialect has no entry pseudostate.`,
    });
  }

  const placed = normaliseTagPlacement(body);
  if (placed.moved > 0) {
    body = placed.text;
    problems.push({
      code: 'preflight/tag-after-keyword',
      severity: 'warning',
      message: `${placed.moved} tag(s) were written after the keyword (\`attribute #Tag x\`) and moved in front of it (\`#Tag attribute x\`), which is where the grammar reads them.`,
    });
  }

  const balance = braceBalance(body);
  if (balance !== 0) {
    problems.push({
      code: 'preflight/unbalanced-braces',
      severity: 'error',
      message:
        balance > 0
          ? `${balance} brace(s) are left open at the end of the fragment.`
          : `${-balance} closing brace(s) more than were opened.`,
    });
  }

  for (const [name, line] of reservedNames(body)) {
    problems.push({
      code: 'preflight/reserved-name',
      severity: 'error',
      line,
      message: `\`${name}\` is a keyword and cannot name a feature — the grammar reads it as the start of a clause. Rename it.`,
    });
  }

  return { ok: !problems.some((p) => p.severity === 'error'), fragment: `${indent(body)}\n`, problems };
}

/** Put a declaration in just before the fragment's closing brace. */
export function insertBeforeClose(fragment: string, declaration: string): string {
  const at = fragment.lastIndexOf('}');
  if (at < 0) throw new Error('fragment has no closing brace');
  const block = declaration
    .trimEnd()
    .split('\n')
    .map((l) => (l.trim() === '' ? l : `        ${l.replace(/^\s{0,8}/, '')}`))
    .join('\n');
  return `${fragment.slice(0, at).trimEnd()}\n${block}\n    }\n${fragment.slice(at + 1).trimStart()}`;
}

/* ─────────────────────────────── internals ──────────────────────────────── */

const escape = (s: string): string => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

function lineOf(text: string, re: RegExp): number | undefined {
  const at = text.search(re);
  return at < 0 ? undefined : text.slice(0, at).split('\n').length;
}

/**
 * Every layer package sits at one indent inside the root.
 *
 * Normalised rather than nudged: the body arrives trimmed, so "how far in is
 * this already" is not a question the first line can answer. The common
 * indentation is measured across every non-blank line, removed, and four spaces
 * put back — which leaves a fragment that was already right exactly as it was.
 */
function indent(body: string): string {
  const lines = body.split('\n');
  const lead = (l: string): number => /^(\s*)/.exec(l)?.[1].length ?? 0;
  const leads = lines.filter((l) => l.trim() !== '').map(lead);
  if (leads.length === 0) return body;
  const common = Math.min(...leads.slice(1).concat(leads[0] === 0 ? [] : [leads[0]]), ...(leads.length === 1 ? leads : []));
  const strip = Number.isFinite(common) ? common : 0;
  // Never past a line's own whitespace. Measured: the first line is excluded
  // from the measure when it is trimmed, and was then cut by the measure —
  // `package SA {` became `age SA {`, a parse error at the fragment's first
  // line that three repair rounds could not fix because the model's answer
  // was right every time.
  return lines.map((l) => (l.trim() === '' ? l : `    ${l.slice(Math.min(strip, lead(l)))}`)).join('\n');
}

/** Braces outside comments and strings. */
function braceBalance(text: string): number {
  let depth = 0;
  let i = 0;
  while (i < text.length) {
    const two = text.slice(i, i + 2);
    if (two === '/*') {
      const end = text.indexOf('*/', i + 2);
      i = end < 0 ? text.length : end + 2;
      continue;
    }
    if (two === '//') {
      const end = text.indexOf('\n', i);
      i = end < 0 ? text.length : end + 1;
      continue;
    }
    const c = text[i];
    if (c === '"' || c === "'") {
      i += 1;
      while (i < text.length && text[i] !== c) i += text[i] === '\\' ? 2 : 1;
      i += 1;
      continue;
    }
    if (c === '{') depth += 1;
    if (c === '}') depth -= 1;
    i += 1;
  }
  return depth;
}

function reservedNames(text: string): Array<[string, number]> {
  const stripped = text.replace(/\/\*[\s\S]*?\*\//g, (m) => m.replace(/[^\n]/g, ' '));
  const found: Array<[string, number]> = [];
  for (const m of stripped.matchAll(DECLARATION)) {
    const name = m[1];
    // `def` is consumed by the pattern; a bare `part def X` gives X, and the
    // keyword-shaped words that legitimately follow (`def`) never reach here.
    if (isReservedName(name)) {
      found.push([name, stripped.slice(0, m.index).split('\n').length]);
    }
  }
  return found;
}
