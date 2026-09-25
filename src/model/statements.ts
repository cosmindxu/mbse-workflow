/**
 * A fragment as a list of declarations, and what each one declares.
 *
 * Two guards need this and both were written the hard way first. An
 * alternative asked for its components alone came back with the whole layer,
 * and gluing that onto the head produced 188 duplicate names in one answer.
 * Two alternatives adding to Common at the same moment each re-declared what
 * the other had just declared. Sysprose's answer to both is the same
 * diagnostic — a duplicate name in a scope — and its fix is the same: know
 * what a scope already declares before writing into it.
 */

/**
 * The index of the brace that closes the one at `open`, or -1 — comments and
 * strings skipped. Every brace walk in this project goes through here.
 * Measured: a placeholder definition whose doc mentioned `{mode, health}` was
 * cut at the brace inside the comment; its body and real closing brace were
 * left behind in the head, the layer closed there, and every alternative
 * built on that head put its connections at the root.
 */
export function matchingBrace(text: string, open: number): number {
  let depth = 0;
  let i = open;
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
    else if (c === '}' && (depth -= 1) === 0) return i;
    i += 1;
  }
  return -1;
}

/** Top-level statements of a body: `…;` and `… { … }`, comments and strings respected. */
export function splitStatements(body: string): string[] {
  const out: string[] = [];
  let depth = 0;
  let start = 0;
  let i = 0;
  const push = (end: number): void => {
    const text = body.slice(start, end);
    if (text.trim() !== '') out.push(text);
    start = end;
  };
  while (i < body.length) {
    const two = body.slice(i, i + 2);
    if (two === '/*') {
      const end = body.indexOf('*/', i + 2);
      i = end < 0 ? body.length : end + 2;
      continue;
    }
    if (two === '//') {
      const end = body.indexOf('\n', i);
      i = end < 0 ? body.length : end + 1;
      continue;
    }
    const c = body[i];
    if (c === '"' || c === "'") {
      i += 1;
      while (i < body.length && body[i] !== c) i += body[i] === '\\' ? 2 : 1;
      i += 1;
      continue;
    }
    if (c === '{') depth += 1;
    else if (c === '}') {
      depth -= 1;
      if (depth === 0) {
        i += 1;
        push(i);
        continue;
      }
    } else if (c === ';' && depth === 0) {
      i += 1;
      push(i);
      continue;
    }
    i += 1;
  }
  push(body.length);
  return out;
}

const NAMED =
  /^\s*(?:(?:\/\/[^\n]*\n|\/\*[\s\S]*?\*\/)\s*)*(?:#[\w']+\s+)*(?:(?:abstract|ref|readonly|derived|in|out|inout|variation|variant|individual)\s+)*(?:item|attribute|port|interface|enum|part|action|connection|metadata|occurrence|requirement|state|calc|constraint|use case|view|viewpoint|concern|verification|analysis|package|flow)\s+(?:def\s+)?([A-Za-z_][A-Za-z0-9_]*)\b/;

/** The name a statement declares in its scope, or undefined for a relationship. */
export function declaredName(statement: string): string | undefined {
  const m = NAMED.exec(statement);
  if (!m) return undefined;
  // `flow of Item from …` and `flow from …` declare nothing.
  if (/^\s*flow\s+(?:of|from)\b/.test(statement.trimStart().replace(/^(?:\/\/[^\n]*\n\s*)*/, ''))) return undefined;
  return m[1];
}

/** What identifies a statement: its name when it has one, its text when it does not. */
export const statementKey = (statement: string): string =>
  declaredName(statement) ?? statement.replace(/\/\*[\s\S]*?\*\//g, '').replace(/\s+/g, ' ').trim();

/** The body between a package's braces, and the text around it. */
export function packageBody(text: string, name?: string): { head: string; body: string; tail: string } | undefined {
  const open = new RegExp(`package\\s+${name ?? '[A-Za-z_][A-Za-z0-9_]*'}\\s*\\{`).exec(text);
  if (!open) return undefined;
  const close = matchingBrace(text, open.index + open[0].length - 1);
  if (close < 0) return undefined;
  return {
    head: text.slice(0, open.index + open[0].length),
    body: text.slice(open.index + open[0].length, close),
    tail: text.slice(close),
  };
}

/**
 * The body of a package that wraps the WHOLE text, or undefined.
 *
 * `packageBody` matches the first `package X {` anywhere in the text, so a
 * section that merely *contains* one unwraps to that package's body and
 * everything written around it is thrown away. Measured: an alternative hit a
 * duplicate `package Hazards`, renamed its own to `Alt2Hazards` to escape it,
 * and the next composition returned 2,163 characters of an 18,116-character
 * answer — five component definitions gone, and the hazards that survived
 * naming types that no longer existed. One helper, so the two call sites
 * cannot drift apart again.
 */
export function unwrapWholePackage(text: string): string | undefined {
  const whole = packageBody(text);
  if (whole === undefined) return undefined;
  const isWrapper = whole.head.trimStart().startsWith('package') && whole.tail.replace(/^\}/, '').trim() === '';
  return isWrapper ? whole.body : undefined;
}

/**
 * Drop from `section` every statement the head already declares, by name —
 * and, for the relationships that have no name, by text. If the section is a
 * whole package, its body is what is compared.
 */
export function withoutDuplicates(head: string, section: string): { kept: string; dropped: string[] } {
  // Unwrap only when the whole section is one package the model put around
  // its answer. A `package Hazards { … }` inside the section is a statement,
  // and unwrapping it would keep the hazards and throw the components away.
  const inner = unwrapWholePackage(section) ?? section;
  // The head arrives with its closing brace already cut off, so it is not a
  // package `packageBody` can close: read past `package X {` and take the rest
  // as the body. Measured: with the head read as one unclosed statement, its
  // only key was "LA", nothing matched, and a repair that returned the whole
  // layer was glued on in full — 184 duplicate names.
  const headBody = packageBody(head)?.body ?? head.replace(/^\s*(?:\/\/[^\n]*\n\s*)*package\s+[A-Za-z_][A-Za-z0-9_]*\s*\{/, '');
  const headKeys = new Set(splitStatements(headBody).map(statementKey));
  const kept: string[] = [];
  const dropped: string[] = [];
  const seen = new Set<string>();
  for (const statement of splitStatements(inner)) {
    const key = statementKey(statement);
    if (headKeys.has(key) || seen.has(key)) dropped.push(key);
    else {
      seen.add(key);
      kept.push(statement.replace(/^\s*\n/, '').replace(/\s+$/, ''));
    }
  }
  return { kept: kept.join('\n'), dropped };
}

/** One declaration per name inside a package: the first stays, later ones go. */
export function dedupePackage(text: string, name?: string): { text: string; dropped: string[] } {
  const parts = packageBody(text, name);
  if (!parts) return { text, dropped: [] };
  const seen = new Set<string>();
  const kept: string[] = [];
  const dropped: string[] = [];
  for (const statement of splitStatements(parts.body)) {
    const n = declaredName(statement);
    if (n !== undefined && seen.has(n)) {
      dropped.push(n);
      continue;
    }
    if (n !== undefined) seen.add(n);
    kept.push(statement);
  }
  return { text: `${parts.head}${kept.join('')}${parts.tail}`, dropped };
}

/**
 * Braces as the model meant them, not as it typed them.
 *
 * Measured: a components section came back with one closing brace too many,
 * in the middle. The layer package closed there, every connection after it
 * landed at the root with one resolvable end, and the orchestrator's own
 * closing brace was "input not parsed" — three error classes from one
 * character. A closing brace with nothing open is dropped; an opening brace
 * with nothing closing it is closed at the end. Comments and strings are not
 * counted.
 */
export function balanceBraces(text: string): { text: string; dropped: number; appended: number } {
  let depth = 0;
  let dropped = 0;
  let out = '';
  let i = 0;
  while (i < text.length) {
    const two = text.slice(i, i + 2);
    if (two === '/*') {
      const end = text.indexOf('*/', i + 2);
      const stop = end < 0 ? text.length : end + 2;
      out += text.slice(i, stop);
      i = stop;
      continue;
    }
    if (two === '//') {
      const end = text.indexOf('\n', i);
      const stop = end < 0 ? text.length : end + 1;
      out += text.slice(i, stop);
      i = stop;
      continue;
    }
    const c = text[i];
    if (c === '"' || c === "'") {
      let j = i + 1;
      while (j < text.length && text[j] !== c) j += text[j] === '\\' ? 2 : 1;
      j += 1;
      out += text.slice(i, j);
      i = j;
      continue;
    }
    if (c === '{') depth += 1;
    else if (c === '}') {
      if (depth === 0) {
        dropped += 1;
        i += 1;
        continue;
      }
      depth -= 1;
    }
    out += c;
    i += 1;
  }
  const appended = depth;
  return { text: depth > 0 ? `${out.replace(/\s*$/, '')}\n${'}\n'.repeat(depth)}` : out, dropped, appended };
}

/**
 * A nested package the head already has is merged, not repeated.
 *
 * Measured: the function layer holds `package Hazards { … }` (every layer
 * states its hazards), and an alternative — asked for its components — put
 * its own hazards in a second `package Hazards`. Dropping the section's copy
 * as a duplicate name loses the hazards that are specific to the
 * architecture; keeping it is a duplicate-name error no repair can remove.
 * The section's body goes inside the head's package instead.
 */
/** Comments and blank space a statement carries in front of what it declares. */
const LEADING_TRIVIA = /^(?:\s*(?:\/\/[^\n]*\n|\/\*[\s\S]*?\*\/))*\s*/;

export function mergeNestedPackages(head: string, section: string): { head: string; section: string; merged: string[] } {
  const merged: string[] = [];
  let newHead = head;
  const rest: string[] = [];
  for (const statement of splitStatements(section)) {
    // A statement carries the comments written above it: `splitStatements`
    // slices from the end of the previous one. Measured: an alternative headed
    // its hazards with `/* ---------- LA-level hazards ---------- */`, the
    // anchor never matched, and the answer added a second `package Hazards`
    // beside the head's — a duplicate name that cost a repair round, after
    // which the model flattened its hazards to the layer root and lost the
    // convention.
    const lead = LEADING_TRIVIA.exec(statement)?.[0] ?? '';
    const bare = statement.slice(lead.length);
    const m = /^package\s+([A-Za-z_][A-Za-z0-9_]*)\s*\{/.exec(bare);
    if (!m) {
      rest.push(statement);
      continue;
    }
    const target = new RegExp(`^[ \\t]*package\\s+${m[1]}\\s*\\{`, 'm').exec(newHead);
    if (!target) {
      rest.push(statement);
      continue;
    }
    const inner = packageBody(bare, m[1]);
    const close = matchingBrace(newHead, newHead.indexOf('{', target.index));
    if (!inner || close < 0) {
      rest.push(statement);
      continue;
    }
    // The comment above the section's package explains what it adds; it moves
    // into the head with the declarations it introduced rather than being lost.
    // What the head's package already declares is not declared twice. Measured
    // in v6 at S32: an alternative restated the layer's hazards beside its
    // satisfy lines, and the merge put ten duplicate names in LA::Hazards.
    const headInner = packageBody(newHead.slice(target.index, close + 1), m[1]);
    const fresh = headInner ? withoutDuplicates(`package ${m[1]} {${headInner.body}}`, inner.body).kept : inner.body;
    const body = `${lead.trim() ? `${lead.trim()}\n` : ''}${fresh.replace(/\s+$/, '')}`;
    newHead = `${newHead.slice(0, close).replace(/\s+$/, '')}\n${body}\n${newHead.slice(newHead.lastIndexOf('\n', close) + 1)}`;
    merged.push(m[1]);
  }
  return { head: newHead, section: rest.join('\n'), merged };
}

/**
 * What a repaired fragment adds inside the packages the head already has,
 * rewrapped as `package X { … }` so `mergeNestedPackages` can put it back.
 *
 * `build` merges a section's `package Hazards` INTO the head's, above the
 * section marker; a repair returns the whole fragment and the section is read
 * from the marker on, so without this every hazard and `satisfy` the
 * alternative wrote was discarded on its first repair. Measured in v6 at S32:
 * the repair "removed" a hazard it had kept, and each `satisfy … by <part>;`
 * vanished with it.
 */
export function nestedAdditions(head: string, fragment: string, layerPackage: string): string {
  const out: string[] = [];
  const names = new Set([...head.matchAll(/^[ \t]+package\s+([A-Za-z_][A-Za-z0-9_]*)\s*\{/gm)].map((m) => m[1]));
  names.delete(layerPackage);
  for (const name of names) {
    const inHead = packageBody(head, name);
    const inFragment = packageBody(fragment, name);
    if (!inHead || !inFragment) continue;
    const { kept } = withoutDuplicates(`package ${name} {${inHead.body}}`, inFragment.body);
    if (kept.trim()) out.push(`package ${name} {\n${kept}\n}`);
  }
  return out.join('\n');
}
