import { describe, expect, it } from 'vitest';
import { identifierOf } from '../../src/spec/names.ts';

describe('identifierOf', () => {
  it('turns a prose name into the identifier a model declares', () => {
    expect(identifierOf('Mesh radio')).toBe('MeshRadio');
    expect(identifierOf('MeshRadio')).toBe('MeshRadio');
    expect(identifierOf(undefined)).toBeUndefined();
  });
});
