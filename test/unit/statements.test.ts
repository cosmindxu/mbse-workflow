/**
 * Knowing what a scope declares before writing into it.
 */
import { describe, expect, it } from 'vitest';
import { balanceBraces, dedupePackage, declaredName, mergeNestedPackages, packageBody, splitStatements, unwrapWholePackage, withoutDuplicates } from '../../src/model/statements.ts';

const head = [
  '    package LA {',
  '        #prompt part laGuidance { doc /* guidance */ }',
  '        action def Watch { doc /* w */ }',
  '        action watch : Watch { in area : Common::Area; }',
  '        trace watch to Swarm::SA::watch;',
  '        flow f1 of Common::Area from watch.area to report.area;',
  '        part def SwarmLogical;',
  '        part mainComponent : SwarmLogical;',
  '        allocate watch to mainComponent;',
  '    }',
].join('\n');

describe('statements', () => {
  it('splits a body into top-level statements, braces and comments respected', () => {
    const body = 'action a { doc /* has ; and } inside */ in x : T; }\n trace a to B::a;\n // note; with ; \n part p : P;';
    const parts = splitStatements(body).map((s) => s.trim());
    expect(parts).toHaveLength(3);
    expect(parts[0].startsWith('action a {')).toBe(true);
    expect(parts[1]).toBe('trace a to B::a;');
  });

  it('names what a statement declares, and nothing for a relationship', () => {
    expect(declaredName('#Actor part def Operator { }')).toBe('Operator');
    expect(declaredName('  in port cmd : P;')).toBe('cmd');
    expect(declaredName('trace a to b;')).toBeUndefined();
    expect(declaredName('flow f of X from a.p to b.q;')).toBe('f');
    expect(declaredName('flow from a to b;')).toBeUndefined();
    // A statement carries the comments above it, block comments included:
    // without this the dedupe guard cannot see what such a statement declares.
    expect(declaredName('/* why this exists */\npackage Hazards { }')).toBe('Hazards');
    expect(declaredName('// a line comment\n#Hazard requirement h1 { }')).toBe('h1');
  });

  it('keeps from a section only what the head does not already declare', () => {
    const wholeLayerAgain = [
      'package LA {',
      '    action def Watch { doc /* again */ }',
      '    action watch : Watch;',
      '    trace watch to Swarm::SA::watch;',
      '    part def Sentinel { doc /* new */ }',
      '    part sentinel : Sentinel;',
      '    allocate watch to sentinel;',
      '    allocate watch to sentinel;',
      '}',
    ].join('\n');
    const { kept, dropped } = withoutDuplicates(head, wholeLayerAgain);
    expect(dropped).toEqual(['Watch', 'watch', 'trace watch to Swarm::SA::watch;', 'allocate watch to sentinel;']);
    expect(kept).toContain('part def Sentinel');
    expect(kept).toContain('part sentinel : Sentinel;');
    expect(kept.match(/allocate watch to sentinel;/g)).toHaveLength(1);
    expect(kept).not.toContain('action def Watch');
  });

  it('keeps a nested package inside a section as a statement, and unwraps only a whole-section wrapper', () => {
    const withHazards = 'part def Sentinel { doc /* new */ }\npackage Hazards {\n    #Hazard requirement h1 { doc /* h */ }\n}';
    const { kept } = withoutDuplicates(head, withHazards);
    expect(kept).toContain('part def Sentinel');
    expect(kept).toContain('package Hazards {');
    expect(kept).toContain('#Hazard requirement h1');
    const wrapped = 'package LA {\n    part def Sentinel { doc /* new */ }\n}';
    expect(withoutDuplicates(head, wrapped).kept.trim()).toBe('part def Sentinel { doc /* new */ }');
  });

  it('extracts the body of a whole-fragment package even behind a leading comment', () => {
    const wrapped = '    // a comment first\n    package LA {\n        part def A;\n    }\n';
    expect(packageBody(wrapped, 'LA')?.body.trim()).toBe('part def A;');
  });

  it('dedupes against a head whose closing brace has been cut off', () => {
    const openHead = head.replace(/\s*\}\s*$/, '');
    const wholeLayerBody = [
      '        #prompt part laGuidance { doc /* guidance */ }',
      '        action def Watch { doc /* w */ }',
      '        action watch : Watch { in area : Common::Area; }',
      '        trace watch to Swarm::SA::watch;',
      '        part def Sentinel { doc /* new */ }',
      '        part sentinel : Sentinel;',
    ].join('\n');
    const { kept, dropped } = withoutDuplicates(openHead, wholeLayerBody);
    expect(dropped).toEqual(['laGuidance', 'Watch', 'watch', 'trace watch to Swarm::SA::watch;']);
    expect(kept).toContain('part def Sentinel');
    expect(kept).not.toContain('laGuidance');
  });

  it('merges a nested package the head already has instead of repeating it', () => {
    const headWithHazards = [
      '    package LA {',
      '        action watch : Watch;',
      '        package Hazards {',
      '            #Hazard requirement h1 { doc /* from the function layer */ }',
      '        }',
    ].join('\n');
    const section = [
      'part def Sentinel { doc /* new */ }',
      'package Hazards {',
      '    #Hazard requirement h2 { doc /* specific to this architecture */ }',
      '}',
    ].join('\n');
    const { head, section: rest, merged } = mergeNestedPackages(headWithHazards, section);
    expect(merged).toEqual(['Hazards']);
    expect(head.match(/package Hazards/g)).toHaveLength(1);
    expect(head).toContain('#Hazard requirement h1');
    expect(head).toContain('#Hazard requirement h2');
    expect(rest).toContain('part def Sentinel');
    expect(rest).not.toContain('package Hazards');
    // The head's package still closes exactly once after the merge.
    expect(balanceBraces(head).appended).toBe(1);
  });

  it('merges a nested package the section headed with a block comment', () => {
    // Measured: an alternative wrote `/* ---- LA-level hazards ---- */` above
    // its `package Hazards`, the anchor missed because a statement carries the
    // comments written above it, and the answer added a second Hazards package
    // beside the head's.
    const headWithHazards = [
      '    package LA {',
      '        action watch : Watch;',
      '        package Hazards {',
      '            #Hazard requirement h1 { doc /* from the function layer */ }',
      '        }',
    ].join('\n');
    const section = [
      'part def Sentinel { doc /* new */ }',
      '',
      '/* ---------- hazards this particular split introduces ---------- */',
      '',
      'package Hazards {',
      '    #Hazard requirement h2 { doc /* specific to this architecture */ }',
      '}',
    ].join('\n');
    const { head, section: rest, merged } = mergeNestedPackages(headWithHazards, section);
    expect(merged).toEqual(['Hazards']);
    expect(head.match(/package Hazards/g)).toHaveLength(1);
    expect(head).toContain('#Hazard requirement h1');
    expect(head).toContain('#Hazard requirement h2');
    // The rationale the author wrote above the package comes with it.
    expect(head).toContain('hazards this particular split introduces');
    expect(rest).not.toContain('package Hazards');
    expect(balanceBraces(head).appended).toBe(1);
  });

  it('unwraps a package that wraps the whole section, never one written inside it', () => {
    expect(unwrapWholePackage('package LA {\n    part def A;\n}')).toContain('part def A');
    // Measured: an alternative renamed its hazards package to escape a
    // duplicate, and the nested `package Alt2Hazards` hijacked the unwrap —
    // 18,116 characters came back as 2,163, its five component definitions
    // gone and its hazards left naming types that no longer existed.
    const section = [
      'part def MissionCoordinator { doc /* coordination */ }',
      'part def DetectionProcessor { doc /* perception */ }',
      '',
      'package Alt2Hazards {',
      '    #Hazard requirement h { doc /* this split introduces it */ }',
      '}',
    ].join('\n');
    expect(unwrapWholePackage(section)).toBeUndefined();
    const { kept } = withoutDuplicates('    package LA {\n        action watch : Watch;', section);
    expect(kept).toContain('part def MissionCoordinator');
    expect(kept).toContain('part def DetectionProcessor');
  });

  it('drops a stray closing brace and closes what was left open', () => {
    const stray = 'part def A { doc /* } in a comment */ }\n}\nconnection c connect a.p to b.q;\npart def B {';
    const { text, dropped, appended } = balanceBraces(stray);
    expect(dropped).toBe(1);
    expect(appended).toBe(1);
    expect(text).toContain('doc /* } in a comment */');
    expect(text).toContain('connection c connect a.p to b.q;');
    expect(text.trimEnd().endsWith('}')).toBe(true);
    expect(balanceBraces(text)).toMatchObject({ dropped: 0, appended: 0 });
  });

  it('leaves one declaration per name in a package, the first', () => {
    const common = '    package Common {\n        item def A { doc /* first */ }\n        item def B;\n        item def A;\n        item def B { doc /* later */ }\n    }\n';
    const { text, dropped } = dedupePackage(common, 'Common');
    expect(dropped).toEqual(['A', 'B']);
    expect(text).toContain('doc /* first */');
    expect(text).not.toContain('doc /* later */');
    expect(text.match(/item def A/g)).toHaveLength(1);
  });
});
