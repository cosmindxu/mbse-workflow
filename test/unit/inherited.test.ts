/**
 * A diagnostic anchored in a layer above is reported, never repaired here.
 */
import { describe, expect, it } from 'vitest';
import { inherit } from '../../src/check/checker.ts';
import type { RepairItem } from '../../src/check/classify.ts';

const diag = (over: Partial<RepairItem>): RepairItem => ({
  source: 'diagnostic',
  code: 'validation/requirement-subject',
  severity: 'warning',
  message: 'Requirement "X::OA::OperationalBudgets" has no subject.',
  blocking: true,
  layer: 'OA',
  ...over,
});

describe('inherit', () => {
  it('unblocks a diagnostic in the layer above and says which layer owns it', () => {
    const out = inherit(diag({}), 'SA');
    expect(out.blocking).toBe(false);
    expect(out.inherited).toBe('OA');
    expect(out.message).toContain('above this layer');
  });

  it('leaves a diagnostic in the layer being written blocking', () => {
    expect(inherit(diag({ layer: 'SA' }), 'SA').blocking).toBe(true);
  });

  it('leaves Common alone: this step may have written there', () => {
    expect(inherit(diag({ layer: 'Common' }), 'SA').blocking).toBe(true);
  });

  it('never touches a predicate item: a hazard above is a demand on this layer', () => {
    const out = inherit(diag({ source: 'predicate', code: 'requirements.hazardsMitigated' }), 'SA');
    expect(out.blocking).toBe(true);
    expect(out.inherited).toBeUndefined();
  });
});
