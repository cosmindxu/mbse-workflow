/**
 * A repair that deletes a hazard is sent back, naming it.
 */
import { describe, expect, it } from 'vitest';
import { hazardNamesIn, withDroppedHazards } from '../../src/agents/author.ts';
import type { Verdict } from '../../src/check/checker.ts';

const verdict: Verdict = { step: 'S32', prefixPath: '', prefixHash: '', blocking: false, checks: [], items: [], durationMs: 0, loaded: true, elementCount: 0 };

describe('hazards kept under repair', () => {
  it('reads hazard names whatever else they are tagged', () => {
    const text = ['#Hazard requirement flyaway { doc /* a */ }', '#Hazard #Accepted requirement supply { doc /* b */ }', '#Accepted #Hazard requirement crowd;', 'requirement budget;'].join('\n');
    expect([...hazardNamesIn(text)].sort()).toEqual(['crowd', 'flyaway', 'supply']);
  });

  it('blocks a verdict whose fragment lost a hazard, and leaves an intact one alone', () => {
    const lost = withDroppedHazards(verdict, new Set(['flyaway', 'linkGap']), new Set(['flyaway']));
    expect(lost.blocking).toBe(true);
    expect(lost.items.map((i) => i.code)).toEqual(['hazards.kept']);
    expect(lost.items[0].message).toContain('`linkGap`');
    expect(withDroppedHazards(verdict, new Set(['flyaway']), new Set(['flyaway', 'new']))).toBe(verdict);
  });
});
