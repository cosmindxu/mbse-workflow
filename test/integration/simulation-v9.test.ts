/**
 * The v9 run's estimates, as the simulation carries them.
 *
 * v9's PA fixes its coverage estimates by equation (CV-17) rather than stating
 * them. The report's claimed-against-simulated column needs the number, and it
 * must be the one Sysprose fixes — the same the final audit and the clip quote
 * — not a literal kept beside the equation, and not null. Loads Sysprose; no
 * model calls.
 */
import { describe, expect, it, beforeAll } from 'vitest';
import { resolve } from 'node:path';
import { InProcessBackend } from '../../src/sysprose/inprocess.ts';
import { simulationInputOf } from '../../src/realization/adapter.ts';
import type { SimulationInput } from '../../src/realization/simulation.ts';

const backend = new InProcessBackend({
  dir: process.env.SYSPROSE_DIR ?? resolve(process.env.HOME ?? '', 'sysprose'),
  expectedCommit: 'any',
});

describe('the v9 run, read into a simulation', () => {
  let input: SimulationInput;

  beforeAll(async () => {
    input = await simulationInputOf('examples/drone-swarm-v9', backend, { timeScale: 1 });
  }, 300_000);

  it('carries the estimate PA derives, labelled as derived', () => {
    const watch = input.measures.find((m) => m.name === 'areaUnderWatchFraction');
    expect(watch?.estimateKind).toBe('derived');
    // 12 × (40 − 7.41) / 60 × 0.12, as PA's equation states it.
    expect(watch?.estimate).toBeCloseTo(0.78216, 5);
    const loss = input.measures.find((m) => m.name === 'coverageLossAfterMemberLossFraction');
    expect(loss?.estimateKind).toBe('derived');
    expect(loss?.estimate).toBeCloseTo(0.12 / 0.78216, 5);
  });

  it('still carries a stated estimate as stated', () => {
    const stated = input.measures.filter((m) => m.estimateKind === 'stated');
    expect(stated.length).toBeGreaterThan(0);
    for (const m of stated) expect(typeof m.estimate).toBe('number');
  });
});
