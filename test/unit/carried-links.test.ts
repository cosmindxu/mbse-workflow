/**
 * The realization links a skeleton carried survive the author's rewrite.
 */
import { describe, expect, it } from 'vitest';
import { restoreCarriedLinks } from '../../src/agents/author.ts';

const skeleton = [
  '    package LA {',
  '        action watch : Watch;',
  '        allocate watch to mainComponent;',
  '        trace watch to Swarm::SA::watch;',
  '        action report : Report;',
  '        allocate report to mainComponent;',
  '        trace report to Swarm::SA::report;',
  '        part operator : Operator;',
  '        trace operator to Swarm::SA::operator;',
  '    }',
].join('\n');

describe('restoring carried links', () => {
  it('puts back the traces and allocations the answer dropped, for functions it kept', () => {
    const answer = [
      '    package LA {',
      '        action watch : Watch { doc /* kept */ }',
      '        allocate watch to mainComponent;',
      '        action report : Report { doc /* kept, links dropped */ }',
      '    }',
    ].join('\n');
    const { text, restored } = restoreCarriedLinks(skeleton, answer);
    expect(restored.sort()).toEqual([
      'allocate report to mainComponent;',
      'trace report to Swarm::SA::report;',
      'trace watch to Swarm::SA::watch;',
    ]);
    expect(text).toContain('trace report to Swarm::SA::report;');
    expect(text.match(/allocate watch to mainComponent;/g)).toHaveLength(1);
    expect(text.trimEnd().endsWith('}')).toBe(true);
  });

  it('adds nothing for a function the author removed, and nothing for parts', () => {
    const answer = '    package LA {\n        action watch : Watch;\n        trace watch to Swarm::SA::watch;\n    }';
    const { text, restored } = restoreCarriedLinks(skeleton, answer);
    expect(restored).toEqual(['allocate watch to mainComponent;']);
    expect(text).not.toContain('report');
    expect(text).not.toContain('operator');
  });

  it('is idempotent', () => {
    const once = restoreCarriedLinks(skeleton, '    package LA {\n        action watch : Watch;\n    }').text;
    const twice = restoreCarriedLinks(skeleton, once);
    expect(twice.restored).toEqual([]);
    expect(twice.text).toBe(once);
  });

  it('keeps both traces of a function T-01 merged from two members', () => {
    const merged = [
      '    package SA {',
      '        #Coordination action handOverSector : HandOverSector;',
      '        allocate handOverSector to system;',
      '        trace handOverSector to Swarm::OA::alphaHandOverSector;',
      '        trace handOverSector to Swarm::OA::bravoHandOverSector;',
      '    }',
    ].join('\n');
    const answer = ['    package SA {', '        #Coordination action handOverSector : HandOverSector { doc /* kept */ }', '        allocate handOverSector to system;', '    }'].join('\n');
    expect(restoreCarriedLinks(merged, answer).restored.sort()).toEqual([
      'trace handOverSector to Swarm::OA::alphaHandOverSector;',
      'trace handOverSector to Swarm::OA::bravoHandOverSector;',
    ]);
  });
});
