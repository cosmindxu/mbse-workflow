/**
 * Below LA, the author is asked to account for an estimate that moved from the
 * layer above, and the evaluator sees the layer above's chosen estimate — both
 * worded so the layer above can be the one that is wrong.
 */
import { describe, expect, it } from 'vitest';
import { estimateGuidance } from '../../src/agents/alternatives.ts';
import { measureClaimsLines, type AlternativeMetrics } from '../../src/agents/evaluate.ts';
import type { Moe } from '../../src/llm/schemas.ts';

const jam: Moe = { name: 'coverageUnderMeshJammingFraction', unit: '', sense: 'max', target: 0.75, doc: 'with half the links jammed', placeholder: true };

const alt = (k: number, value: number, basis: string): AlternativeMetrics => ({
  k,
  elements: 0,
  connections: 0,
  unconnectedPorts: 0,
  orphanDefinitions: 0,
  functionsRealised: 0,
  functionsAbove: 0,
  repairIterations: 0,
  warnings: 0,
  moes: [{ name: jam.name, outcome: 'optimum', value, sense: 'max', target: 0.75, unit: '', basis }],
});

describe('the author below LA', () => {
  it('is asked to say why a value differs from the layer above, without being told the layer above is right', () => {
    const text = estimateGuidance([jam], 'PA').join(' ');
    expect(text).toContain("Where your value differs from LA's, say in your basis why: whether LA's estimate was wrong, or which element modelled at this layer changes it.");
    expect(text).not.toMatch(/must name/i);
  });

  it('is not asked at LA, whose layer above states no estimates', () => {
    expect(estimateGuidance([jam], 'LA').join(' ')).not.toContain('differs from');
    expect(estimateGuidance([jam]).join(' ')).not.toContain('differs from');
  });
});

describe('the evaluator below LA', () => {
  it("lists the layer above's chosen estimate and basis first, under each measure", () => {
    const lines = measureClaimsLines([jam], [alt(1, 0.665, 'loss share 0.15'), alt(2, 0.68, 'two neighbours')], {
      layer: 'LA',
      moes: [{ name: jam.name, value: 0.58, outcome: 'optimum', basis: 'half of the hand-overs fail' }],
    });
    const text = lines.join('\n');
    const at = lines.indexOf('### `coverageUnderMeshJammingFraction` (target ≥ 0.75)');
    expect(lines[at + 2]).toBe('- LA (the layer above, chosen): 0.58 — half of the hand-overs fail');
    expect(lines[at + 3]).toBe('- alternative 1: 0.665 — loss share 0.15');
    expect(text).toContain('either the layer above was wrong, or something modelled at this layer changes the number');
  });

  it('shows a derived estimate as derived, and an absent one as absent', () => {
    const text = measureClaimsLines([jam], [alt(1, 0.68, 'b')], {
      layer: 'LA',
      moes: [{ name: jam.name, value: 0.58662, outcome: 'derived', basis: 'correlated' }],
    }).join('\n');
    expect(text).toContain('- LA (the layer above, chosen): 0.58662 (derived) — correlated');
    expect(measureClaimsLines([jam], [alt(1, 0.68, 'b')], { layer: 'LA', moes: [{ name: 'other', outcome: 'optimum', value: 1 }] }).join('\n')).toContain(
      '- LA (the layer above, chosen): no estimate',
    );
  });

  it('is unchanged at LA, with nothing above to show', () => {
    const text = measureClaimsLines([jam], [alt(1, 0.58, 'a')]).join('\n');
    expect(text).not.toContain('the layer above');
    expect(text).toContain('- alternative 1: 0.58 — a');
  });
});
