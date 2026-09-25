import { describe, expect, it } from 'vitest';
import { bareAllocations } from '../../src/agents/alternatives.ts';

describe('bareAllocations', () => {
  it("rewrites a path to this layer's function, and leaves anything else as written", () => {
    const section = [
      'allocate Swarm::LA::handOverSector to fleet;',
      'allocate   Swarm::SA::recallAndLand   to groundStation;',
      'allocate Swarm::LA::notHere to fleet;',
      'allocate handOverSector to memberA;',
      'allocate Other::LA::handOverSector to fleet;',
      'allocate Swarm::LA::RecallAndLand to groundStation;',
    ].join('\n');
    const { text, count } = bareAllocations(section, 'Swarm', ['handOverSector', 'recallAndLand']);
    expect(count).toBe(3);
    expect(text.split('\n')).toEqual([
      'allocate handOverSector to fleet;',
      'allocate recallAndLand   to groundStation;',
      'allocate Swarm::LA::notHere to fleet;',
      'allocate handOverSector to memberA;',
      'allocate Other::LA::handOverSector to fleet;',
      'allocate recallAndLand to groundStation;',
    ]);
  });
});
