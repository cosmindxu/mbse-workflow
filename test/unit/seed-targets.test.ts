/**
 * A target the brief states is marked as the customer's; one SEED set is marked as SEED's.
 */
import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { targetSource } from '../../src/agents/seed.ts';

describe('where a target came from', () => {
  const brief = readFileSync('briefs/drone-swarm.md', 'utf8');
  it('reads the numbers the drone-swarm brief states', () => {
    expect(targetSource(0.9, brief)).toBe('brief');
    expect(targetSource(0.25, brief)).toBe('brief');
    expect(targetSource(12, brief)).toBe('brief');
  });
  it('marks a number the brief never wrote', () => {
    expect(targetSource(0.95, brief)).toBe('set by SEED');
    expect(targetSource(0.1, 'at least 0.10 of the area')).toBe('brief');
  });
});

describe('a placeholder target', () => {
  it('is marked as a placeholder whatever the brief text says', () => {
    expect(targetSource(20, 'at most 20 alerts per hour', true)).toBe('placeholder in the brief');
  });
});
