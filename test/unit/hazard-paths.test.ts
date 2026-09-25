import { describe, expect, it } from 'vitest';
import { hazardPaths } from '../../src/agents/alternatives.ts';

describe('hazardPaths', () => {
  it('names each hazard by its package path, skips accepted ones, ignores braces in docs', () => {
    const text = `package LA {
      part def Drone { doc /* { not a block */ }
      package Hazards {
        #Hazard requirement CoverageGapHazard { doc /* } */ }
        #Hazard #Accepted requirement NoiseHazard;
        #Hazard requirement def GenericHazard;
      }
    }`;
    expect(hazardPaths(text)).toEqual(['LA::Hazards::CoverageGapHazard', 'LA::Hazards::GenericHazard']);
  });
});
