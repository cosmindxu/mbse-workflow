/**
 * A missing shared type is a determined fix: the orchestrator writes the stub.
 */
import { describe, expect, it } from 'vitest';
import { stubMissingCommonTypes } from '../../src/agents/author.ts';
import type { RepairItem } from '../../src/check/classify.ts';

const item = (code: string, message: string, blocking = true): RepairItem => ({
  source: 'diagnostic',
  code,
  severity: 'error',
  message,
  blocking,
});

describe('stubbing missing Common types', () => {
  it('names each unresolved Common type once, and only those', () => {
    const { names, declarations } = stubMissingCommonTypes('Swarm', 'LA', [
      item('validation/unresolved-type-ref', 'Unresolved type reference "Swarm::Common::AreaActivity" on Swarm::LA::watch'),
      item('validation/unresolved-type-ref', 'Unresolved type reference "Swarm::Common::AreaActivity" on Swarm::LA::report'),
      item('validation/unresolved-type-ref', 'Unresolved type reference "Swarm::Common::LinkStatus" on Swarm::LA::report'),
      item('validation/unresolved-type-ref', 'Unresolved type reference "Swarm::LA::LocalThing" on Swarm::LA::report'),
      item('ref/unresolved-reference', 'Unresolved reference "Swarm::Common::NotAType"'),
      item('validation/unresolved-type-ref', 'Unresolved type reference "Swarm::Common::Reported" on x', false),
    ]);
    expect(names).toEqual(['AreaActivity', 'LinkStatus']);
    expect(declarations[0]).toMatch(/^item def AreaActivity \{ doc \/\* TODO: introduced by LA/);
  });

  it('returns nothing when nothing is missing', () => {
    expect(stubMissingCommonTypes('Swarm', 'LA', [item('parse/mismatched-token', 'x')]).names).toEqual([]);
  });
});
