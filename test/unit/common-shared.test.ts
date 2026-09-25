/**
 * Shared declarations land in one place, however many times they are asked for.
 */
import { describe, expect, it } from 'vitest';
import { mergeIntoShared } from '../../src/agents/author.ts';
import { preflight } from '../../src/model/fragments.ts';

const common = '    package Common {\n        item def Detection;\n    }\n';

describe('merging additions into package <Layer>Shared', () => {
  it('puts the declaration in Common itself, where `Common::X` resolves', () => {
    const out = mergeIntoShared(common, 'LA', ['item def AreaActivity;']);
    expect(out).not.toContain('package LAShared');
    expect(out).toContain('item def AreaActivity;');
    expect(out).toContain('asked for by LA');
    expect(preflight(out, 'Common').problems.filter((p) => p.severity === 'error')).toEqual([]);
  });

  it('adds again without disturbing what is there', () => {
    const once = mergeIntoShared(common, 'LA', ['item def AreaActivity;']);
    const twice = mergeIntoShared(once, 'LA', ['item def ChargeAvailable;']);
    expect(twice).toContain('item def AreaActivity;');
    expect(twice).toContain('item def ChargeAvailable;');
    expect(twice).toContain('item def Detection;');
    expect(preflight(twice, 'Common').problems.filter((p) => p.severity === 'error')).toEqual([]);
  });

  it('does not re-declare a name Common already has, wherever it sits', () => {
    const out = mergeIntoShared(common, 'LA', ['item def Detection { doc /* again */ }', 'item def New;']);
    expect(out.match(/item def Detection/g)).toHaveLength(1);
    expect(out).toContain('item def New;');
  });

  it('does not write a declaration that is already there', () => {
    const once = mergeIntoShared(common, 'LA', ['item def AreaActivity;']);
    const again = mergeIntoShared(once, 'LA', ['item def AreaActivity;', ' item def AreaActivity; ']);
    expect(again.match(/item def AreaActivity;/g)).toHaveLength(1);
  });

  it('treats two spellings of one declaration as one, by name', () => {
    const once = mergeIntoShared(common, 'LA', ['item def AreaActivity;']);
    const again = mergeIntoShared(once, 'LA', ['item def AreaActivity { doc /* an activity in the area */ }', 'item def Other;']);
    expect(again.match(/item def AreaActivity/g)).toHaveLength(1);
    expect(again).toContain('item def Other;');
  });

  it('hoists what an earlier version nested, so Common::X resolves', () => {
    const nested = [
      '    package Common {',
      '        item def Detection;',
      '        package SAShared {',
      '            item def AreaActivity {',
      '                doc /* from SA */',
      '            }',
      '        }',
      '    }',
      '',
    ].join('\n');
    const out = mergeIntoShared(nested, 'LA', ['item def AreaActivity { doc /* stub */ }', 'item def New;']);
    expect(out).not.toContain('package SAShared');
    expect(out).toContain('hoisted');
    // The hoisted declaration is now at Common::AreaActivity, and the stub for
    // the same name is not written on top of it.
    expect(out.match(/item def AreaActivity/g)).toHaveLength(1);
    expect(out).toContain('doc /* from SA */');
    expect(out).toContain('item def New;');
    expect(preflight(out, 'Common').problems.filter((p) => p.severity === 'error')).toEqual([]);
  });

  it('records which layer asked, per addition', () => {
    const la = mergeIntoShared(common, 'LA', ['item def A;']);
    const pa = mergeIntoShared(la, 'PA', ['item def B;']);
    expect(pa).toContain('asked for by LA');
    expect(pa).toContain('asked for by PA');
  });
});
