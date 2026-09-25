/**
 * The reference model passes every gate.
 *
 * This is the calibration the predicates exist under: a validated layered reference model
 * — hand-written, exit 0, 100 % requirement coverage — must clear every
 * authoring step's post-conditions. A predicate that fails here is a predicate
 * that would send a correct model back to an agent for repair, forever.
 *
 * The safety and intake knobs are off, and the documentation gate is at 0:
 * hazards, a requirement lane and a doc on every element are demands this
 * workflow adds, and the reference model — validated for its structure —
 * predates all three.
 */
import { describe, expect, it } from 'vitest';
import { resolve } from 'node:path';
import { makeLayout } from '../../src/model/layout.ts';
import { InProcessBackend } from '../../src/sysprose/inprocess.ts';
import { runStepChecks } from '../../src/check/checker.ts';
import { STEPS, step as stepById, type StepId } from '../../src/spec/steps.ts';
import { hasCorpus } from '../../src/config/corpus.ts';
import type { Knobs } from '../../src/check/classify.ts';

const FIXTURE = resolve(import.meta.dirname, '../fixtures/levelcrossing');
const layout = makeLayout(FIXTURE, 'LevelCrossing');
const backend = new InProcessBackend({
  dir: process.env.SYSPROSE_DIR ?? resolve(process.env.HOME ?? '', 'sysprose'),
  expectedCommit: 'a66ba1f',
});

const KNOBS: Knobs = {
  modes_states: true,
  interfaces: true,
  variability: true,
  safety: false,
  views: false,
  verification: true,
  requirements_intake: false,
  infrastructure_intake: false,
};

const brief = {
  systemName: 'LevelCrossing',
  aliases: ['Level Crossing', 'crossing controller'],
  moes: [],
  // The reference model declares two operational use cases; naming them here is
  // what makes the capability post-condition a real assertion on it.
  capabilities: ['PreventCollision', 'ForbidSimultaneousAccess'],
  // The reference OA declares `part authority` untagged: the entity gate is a real assertion.
  systemEntity: 'authority',
};

/**
 * The steps that check an authored layer — the ones a run is gated on.
 *
 * S41 is held separately below: it demands that every logical function be
 * realised physically, which a workflow run gets for free (the LA→PA transition
 * copies them) and which the hand-written reference model — a thin thread
 * through one function — does not meet.
 */
const AUTHORING_STEPS: StepId[] = ['S10', 'S21', 'S32', 'S50', 'S70'];

describe.skipIf(!hasCorpus())('predicates, calibrated on the reference model', () => {
  it.each(AUTHORING_STEPS)('%s passes on the reference model', async (id) => {
    const verdict = await runStepChecks(stepById(id), { backend, layout, knobs: KNOBS, brief, docCoverageMin: 0 });
    const blocking = verdict.items.filter((i) => i.blocking);
    expect(
      blocking.map((i) => `${i.code} ${i.qualifiedName ?? ''} — ${i.message}`),
      `${id} should not block on a validated model`,
    ).toEqual([]);
    expect(verdict.blocking).toBe(false);
  });

  it('still reports what the model leaves open, rather than staying silent', async () => {
    const verdict = await runStepChecks(stepById('S21'), { backend, layout, knobs: KNOBS, brief, docCoverageMin: 0 });
    const codes = new Set(verdict.items.map((i) => i.code));
    // Five ports are deliberately left free, and three transitions are decided
    // by declaration order. Both are notes, not gates.
    expect(codes.has('connectivity.layerPorts')).toBe(true);
    expect(codes.has('verification/nondeterministic-choice')).toBe(true);
    expect(verdict.items.filter((i) => i.code === 'connectivity.layerPorts').every((i) => !i.blocking)).toBe(true);
  });

  it('S31 clears the reference model except for the components it already decides', async () => {
    // The reference LA was written as one layer, components included. S31 now
    // writes functions only, so its one complaint about the reference model is
    // exactly that — the three logical components — and nothing else.
    const verdict = await runStepChecks(stepById('S31'), { backend, layout, knobs: KNOBS, brief, docCoverageMin: 0 });
    const blocking = verdict.items.filter((i) => i.blocking);
    expect(new Set(blocking.map((i) => i.code))).toEqual(new Set(['layer.functionsOnly']));
    expect(blocking.map((i) => i.qualifiedName).filter(Boolean).sort()).toEqual([
      'LevelCrossing::LA::ManagementSystem',
      'LevelCrossing::LA::RailFacilities',
      'LevelCrossing::LA::RoadFacilities',
      'LevelCrossing::LA::mgmt',
      'LevelCrossing::LA::rail',
      'LevelCrossing::LA::road',
    ]);
  });

  it('S41 blocks on exactly the thin thread the reference model leaves physical', async () => {
    const verdict = await runStepChecks(stepById('S41'), { backend, layout, knobs: KNOBS, brief, docCoverageMin: 0 });
    const blocking = verdict.items.filter((i) => i.blocking);
    // Two logical functions this model never implements. Everything else clears:
    // the actor-allocated emergency function is exempt, and every PA function
    // realises a logical one.
    expect(blocking.map((i) => i.qualifiedName).sort()).toEqual([
      'LevelCrossing::LA::launchDeparture',
      'LevelCrossing::LA::switchOnSignal',
    ]);
    expect(blocking.every((i) => i.code === 'trace.previousRealised')).toBe(true);
  });

  it('records, without blocking, the operational activities the system does not take over', async () => {
    const verdict = await runStepChecks(stepById('S21'), { backend, layout, knobs: KNOBS, brief, docCoverageMin: 0 });
    const notRealised = verdict.items.filter((i) => i.code === 'trace.previousRealised');
    expect(notRealised.length).toBeGreaterThan(0);
    expect(notRealised.every((i) => !i.blocking)).toBe(true);
  });

  it('the documentation gate reports the reference model, which was never written to it', async () => {
    const verdict = await runStepChecks(stepById('S21'), { backend, layout, knobs: KNOBS, brief, docCoverageMin: 0.8 });
    const docs = verdict.items.filter((i) => i.code === 'docs.coverage');
    expect(docs).toHaveLength(1);
    expect(docs[0].blocking).toBe(true);
    expect(docs[0].message).toMatch(/% of this layer's elements carry a doc/);
  });

  it('does not ask for a configuration item for an actor carried into PA', async () => {
    // The reference PA has no actors; a synthetic one is put beside it and the
    // EPBS gate must not name it.
    const { readFileSync, writeFileSync } = await import('node:fs');
    const paPath = layout.fragmentPath('PA');
    const original = readFileSync(paPath, 'utf8');
    writeFileSync(paPath, original.replace(/\n    \}\s*$/, '\n        #Actor part def Inspector;\n        part inspector : Inspector;\n    }\n'));
    try {
      const verdict = await runStepChecks(stepById('S50'), { backend, layout, knobs: KNOBS, brief, docCoverageMin: 0 });
      expect(verdict.items.filter((i) => i.code === 'epbs.paPartsRealised').map((i) => i.qualifiedName)).not.toContain('LevelCrossing::PA::inspector');
      expect(verdict.blocking).toBe(false);
    } finally {
      writeFileSync(paPath, original);
    }
  });

  it('every step in the table is either an agent step or an audit step', () => {
    for (const s of STEPS) {
      const isAudit = s.agent === 'AUDIT';
      expect(isAudit || s.checks.length > 0 || s.agent === 'TRANSITION').toBe(true);
    }
  });
});
