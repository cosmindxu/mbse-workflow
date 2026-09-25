import { describe, expect, it } from 'vitest';
import { mergeNestedPackages, nestedAdditions } from '../../src/model/statements.ts';

describe('nestedAdditions', () => {
  const head = `    package LA {
        part def Worker;
        package Hazards {
            #Hazard requirement fallHazard;
        }`;

  it('recovers what an alternative merged into a head package, so a repair keeps it', () => {
    const composed = mergeNestedPackages(head, `package Hazards {\n#Hazard requirement gapHazard;\nsatisfy Hazards::fallHazard by worker;\n}`);
    const additions = nestedAdditions(head, composed.head, 'LA');
    expect(additions).toContain('gapHazard');
    expect(additions).toContain('satisfy Hazards::fallHazard by worker;');
    expect(additions).not.toContain('fallHazard;\n');
    expect(additions).not.toContain('part def Worker');
  });

  it('adds nothing when the repaired fragment added nothing there', () => {
    expect(nestedAdditions(head, `${head}\n    }`, 'LA')).toBe('');
  });
});

describe('mergeNestedPackages', () => {
  it('does not repeat what the head package already declares', () => {
    const head = `    package LA {
        package Hazards {
            #Hazard requirement fallHazard;
        }`;
    const joined = mergeNestedPackages(head, `package Hazards {\n#Hazard requirement fallHazard { doc /* again */ }\nsatisfy Hazards::fallHazard by worker;\n}`);
    expect(joined.head.match(/requirement fallHazard/g)).toHaveLength(1);
    expect(joined.head).toContain('satisfy Hazards::fallHazard by worker;');
  });
});
