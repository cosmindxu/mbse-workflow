/**
 * The four things a model does to a fragment, caught before Sysprose is asked.
 */
import { describe, expect, it } from 'vitest';
import { insertBeforeClose, normaliseDocStrings, normaliseEntryPseudostates, normaliseTagPlacement, preflight } from '../../src/model/fragments.ts';

const ok = '    package OA {\n        part def Authority;\n    }\n';

describe('preflight', () => {
  it('accepts a well-formed fragment unchanged', () => {
    const result = preflight(ok, 'OA', { root: 'LevelCrossing' });
    expect(result.ok).toBe(true);
    expect(result.problems).toEqual([]);
    expect(result.fragment).toBe(ok);
  });

  it('strips a markdown fence and says so', () => {
    const result = preflight('```sysml\npackage OA {\n    part def A;\n}\n```', 'OA');
    expect(result.ok).toBe(true);
    expect(result.fragment).toContain('package OA {');
    expect(result.fragment).not.toContain('```');
    expect(result.problems.map((p) => p.code)).toEqual(['preflight/markdown-fence']);
  });

  it('indents a fragment written at the left margin', () => {
    const result = preflight('package OA {\n    part def A;\n}', 'OA');
    expect(result.fragment.startsWith('    package OA {')).toBe(true);
    expect(result.fragment).toContain('\n        part def A;');
  });

  it('never cuts into a first line that is less indented than the body', () => {
    // Measured: a trimmed first line with an indented body and closing brace
    // lost four characters — `package SA {` came out `age SA {`.
    const result = preflight('package SA {\n    doc /* x */\n    part def A;\n    }', 'SA');
    expect(result.fragment.startsWith('    package SA {')).toBe(true);
    expect(result.fragment).not.toMatch(/^\s*age SA/m);
    expect(result.fragment).toContain('part def A;');
  });

  it('rewrites an entry pseudostate as the initial state it meant', () => {
    // Measured: sixteen machines in one EPBS layer opened this way, 32 warnings.
    const machine = ['state def M {', '    entry;', '    transition entry -> idle;', '    state idle;', '}'].join('\n');
    const out = normaliseEntryPseudostates(machine);
    expect(out.rewritten).toBe(1);
    expect(out.text).toContain('    initial start;\n    transition start -> idle;');
    expect(out.text).not.toMatch(/\bentry\b/);
  });

  it('rewrites a lone transition from entry and drops a bare entry', () => {
    const lone = normaliseEntryPseudostates('state def M {\n    transition entry -> idle;\n    state idle;\n}');
    expect(lone.text).toContain('initial start;');
    expect(lone.text).toContain('transition start -> idle;');
    const bare = normaliseEntryPseudostates('state def M {\n    entry;\n    state idle;\n}');
    expect(bare.text).not.toMatch(/\bentry\b/);
  });

  it('leaves an entry action alone — it is a real construct', () => {
    const text = 'state def M {\n    state idle {\n        entry action warmUp;\n    }\n}';
    expect(normaliseEntryPseudostates(text)).toEqual({ text, rewritten: 0 });
  });

  it('refuses a fragment that re-declares the root package', () => {
    const result = preflight('package LevelCrossing {\n  package OA { }\n}', 'OA', { root: 'LevelCrossing' });
    expect(result.ok).toBe(false);
    expect(result.problems.map((p) => p.code)).toContain('preflight/root-package');
  });

  it('refuses the wrong layer, an import, and unbalanced braces', () => {
    expect(preflight('package SA { }', 'OA').problems.map((p) => p.code)).toContain('preflight/wrong-package');
    expect(preflight('package OA {\n import X::*;\n}', 'OA').problems.map((p) => p.code)).toContain('preflight/import');
    expect(preflight('package OA {\n  part def A {\n}', 'OA').problems.map((p) => p.code)).toContain(
      'preflight/unbalanced-braces',
    );
  });

  it('counts braces in code, not in comments or strings', () => {
    const tricky = '    package OA {\n        doc /* a { brace } in a comment */\n        attribute s = "a { string";\n    }\n';
    expect(preflight(tricky, 'OA').problems.map((p) => p.code)).not.toContain('preflight/unbalanced-braces');
  });

  it('refuses a feature named after a keyword', () => {
    const result = preflight('    package SA {\n        attribute objective : ScalarValues::Real;\n    }\n', 'SA');
    expect(result.ok).toBe(false);
    const reserved = result.problems.filter((p) => p.code === 'preflight/reserved-name');
    expect(reserved).toHaveLength(1);
    expect(reserved[0].message).toContain('`objective`');
    expect(reserved[0].line).toBe(2);
  });

  it('moves a tag written after the keyword in front of it', () => {
    const wrong = [
      '    package LA {',
      '        attribute #Variant hosted : Boolean { doc /* option */ }',
      '        part def #Node #Behaviour Box;',
      '        in port #Imposed cmd : P;',
      '        #Actor part def Operator;',
      '    }',
    ].join('\n');
    const { text, moved } = normaliseTagPlacement(wrong);
    expect(moved).toBe(3);
    expect(text).toContain('#Variant attribute hosted : Boolean');
    expect(text).toContain('#Node #Behaviour part def Box;');
    expect(text).toContain('#Imposed in port cmd : P;');
    expect(text).toContain('#Actor part def Operator;');
    const result = preflight(wrong, 'LA');
    expect(result.ok).toBe(true);
    expect(result.problems.map((p) => p.code)).toContain('preflight/tag-after-keyword');
    expect(result.fragment).toContain('#Variant attribute hosted');
  });

  it('refuses a trigger payload named after a keyword', () => {
    const result = preflight('    package LA {\n        state def M { transition t first a accept assign : X then b; }\n    }\n', 'LA');
    expect(result.problems.some((p) => p.code === 'preflight/reserved-name' && p.message.includes('`assign`'))).toBe(true);
  });

  it('rewrites a doc written as a string into a doc comment', () => {
    const wrong = [
      '    package PA {',
      '        part def Radio {',
      '            doc "Long-haul link; says \\"hello\\" and ends a comment */ early";',
      '        }',
      "        part radio : Radio { doc 'single quotes'; }",
      '        part fine : Radio { doc /* already right */ }',
      '    }',
    ].join('\n');
    const { text, rewritten } = normaliseDocStrings(wrong);
    expect(rewritten).toBe(2);
    expect(text).toContain('doc /* Long-haul link; says "hello" and ends a comment * / early */');
    expect(text).toContain('doc /* single quotes */');
    expect(text).toContain('doc /* already right */');
    const result = preflight(wrong, 'PA');
    expect(result.ok).toBe(true);
    expect(result.problems.map((p) => p.code)).toContain('preflight/doc-string');
  });

  it('inserts a declaration before the closing brace', () => {
    const out = insertBeforeClose(ok, '#prose part note {\n    doc /* hello */\n}');
    expect(out).toContain('part def Authority;');
    expect(out).toContain('#prose part note {');
    expect(out.trimEnd().endsWith('}')).toBe(true);
    // Still one package, still balanced.
    expect(preflight(out, 'OA').problems.filter((p) => p.severity === 'error')).toEqual([]);
  });
});
