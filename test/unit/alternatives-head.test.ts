/**
 * The head an alternative is built on has every function unallocated.
 */
import { describe, expect, it } from 'vitest';
import { stripPlaceholder } from '../../src/agents/alternatives.ts';
import { withoutTradeOff } from '../../src/agents/evaluate.ts';
import { withoutDuplicates } from '../../src/model/statements.ts';

const head = [
  '    package LA {',
  '        part def SwarmLogical {',
  '            in port cmd : Common::CommandPort;',
  '            doc /* TODO: decompose */',
  '        }',
  '        part mainComponent : SwarmLogical;',
  '        trace mainComponent to Swarm::SA::system;',
  '        #Actor part def Operator { doc /* a person */ }',
  '        part operator : Operator;',
  '        action def Watch { doc /* watch */ }',
  '        action watch : Watch;',
  '        allocate watch to mainComponent;',
  '        trace watch to Swarm::SA::watch;',
  '        action alarm : Watch;',
  '        allocate alarm to operator;',
].join('\n');

describe('stripping the placeholder from the head', () => {
  const out = stripPlaceholder(head, 'LA', 'Swarm');

  it('removes the placeholder usage, its trace and its allocations, and keeps the definition', () => {
    expect(out).toContain('part def SwarmLogical {');
    expect(out).not.toContain('mainComponent');
  });

  it('keeps the functions, their realization links, the actors and their allocations', () => {
    expect(out).toContain('action watch : Watch;');
    expect(out).toContain('trace watch to Swarm::SA::watch;');
    expect(out).toContain('part operator : Operator;');
    expect(out).toContain('allocate alarm to operator;');
  });

  it('strips a placeholder line that is the last line and has no newline', () => {
    const tail = `${head}\n        allocate watch to mainComponent;`;
    const out = stripPlaceholder(tail, 'LA', 'Swarm');
    expect(out).not.toContain('to mainComponent');
    expect(out).toContain('allocate alarm to operator;');
  });

  it('keeps a definition whose doc mentions braces intact', () => {
    const tricky = [
      '    package LA {',
      '        part def SwarmLogical {',
      "            doc /* Mirrors SA's system::{mode, health} until the split. */",
      '            state mode : LogicalMode { doc /* m */ }',
      '        }',
      '        part mainComponent : SwarmLogical;',
      '        action watch : Watch;',
      '        allocate watch to mainComponent;',
    ].join('\n');
    const out = stripPlaceholder(tricky, 'LA', 'Swarm');
    expect(out).toContain('part def SwarmLogical {');
    expect(out).toContain('state mode');
    expect(out).not.toContain('mainComponent');
    expect(out).toContain('action watch : Watch;');
    // Nothing left unbalanced beyond the open layer package the head always is.
    expect((out.match(/\{/g) ?? []).length).toBe((out.match(/\}/g) ?? []).length + 1);
  });

  it('removes a placeholder usage that has a body, whole', () => {
    const withBody = [
      '    package LA {',
      '        part def SwarmLogical { doc /* d */ }',
      '        part mainComponent : SwarmLogical {',
      "            doc /* the system's placeholder; it carries the modes until the split. */",
      '            state mode : LogicalMode { doc /* m */ }',
      '        }',
      '        trace mainComponent to Swarm::SA::system;',
      '        action watch : Watch;',
      '        allocate watch to mainComponent;',
    ].join('\n');
    const out = stripPlaceholder(withBody, 'LA', 'Swarm');
    expect(out).not.toContain('mainComponent');
    expect(out).not.toContain('state mode');
    expect(out).toContain('part def SwarmLogical { doc /* d */ }');
    expect(out).toContain('action watch : Watch;');
    expect((out.match(/\{/g) ?? []).length).toBe((out.match(/\}/g) ?? []).length + 1);
  });

  it('removes every statement that names the placeholder, however it is used', () => {
    const hung = [
      '    package LA {',
      '        part def SwarmLogical;',
      '        part mainComponent : SwarmLogical;',
      '        trace mainComponent to Swarm::SA::system;',
      '        satisfy Swarm::SA::Hazards::h1 by mainComponent;',
      '        connection c1 connect mainComponent.taskingIn',
      '            to opsCentre.taskingOut;',
      '        action watch : Watch;',
      '        allocate watch to mainComponent;',
      '        part operator : Operator { doc /* not the mainComponent, just mentions it in a doc */ }',
    ].join('\n');
    const out = stripPlaceholder(hung, 'LA', 'Swarm');
    expect(out.replace(/\/\*[\s\S]*?\*\//g, '')).not.toMatch(/\bmainComponent\b/);
    expect(out).toContain('action watch : Watch;');
    expect(out).toContain('part operator : Operator');
  });

  it('removes an earlier trade-off record from a layer, whole', () => {
    const evaluated = [
      '    package LA {',
      '        action watch : Watch;',
      '        #prose part laTradeOff {',
      '            doc /* Architecture trade-off for LA. Alternative 1 was taken. { braces in prose } */',
      '        }',
      '    }',
      '',
    ].join('\n');
    const out = withoutTradeOff(evaluated, 'LA');
    expect(out).not.toContain('laTradeOff');
    expect(out).toContain('action watch : Watch;');
    expect(out.trimEnd().endsWith('}')).toBe(true);
    expect(withoutTradeOff(out, 'LA')).toBe(out);
  });

  it('removes the carried member stub, so a section that declares the member with more ports is kept', () => {
    const withStub = [
      head,
      '        // the population: 12 identical members (CV-16)',
      '        #Member part def SwarmMember {',
      '            out port meshOut : Common::MeshPort;',
      '            in port meshIn : ~Common::MeshPort;',
      '            doc /* TODO: one member at LA. { braces } */',
      '        }',
      '        #prose part fleetFact {',
      '            doc /* Population: 12 members */',
      '        }',
    ].join('\n');
    const stripped = stripPlaceholder(withStub, 'LA', 'Swarm');
    expect(stripped).not.toContain('part def SwarmMember');
    expect(stripped).toContain('#prose part fleetFact');
    const section = [
      '#Member part def SwarmMember {',
      '    out port meshOut : Common::MeshPort;',
      '    in port meshIn : ~Common::MeshPort;',
      '    in port taskingIn : Common::TaskingPort;',
      '    doc /* one drone */',
      '}',
      'part fleet : SwarmMember [12];',
    ].join('\n');
    const { kept, dropped } = withoutDuplicates(stripped, section);
    expect(dropped).toEqual([]);
    expect(kept).toContain('in port taskingIn : Common::TaskingPort;');
  });

  it('leaves a layer with no placeholder alone', () => {
    expect(stripPlaceholder(head, 'SA', 'Swarm')).toBe(head);
  });
});
