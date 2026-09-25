/**
 * Every measure has the architecture's estimate (CV-17).
 */
import { describe, expect, it } from 'vitest';
import { PREDICATES, type PredicateInput } from '../../src/check/predicates.ts';
import { step as stepById } from '../../src/spec/steps.ts';
import type { TagIndex } from '../../src/sysprose/backend.ts';

const ROOT = 'Swarm';
const qn = (n: string) => `${ROOT}::LA::${n}`;
const attr = (name: string, value: string) => ({ id: name, qualifiedName: qn(name), name, metaclass: 'AttributeUsage', type: '', multiplicity: '', value, redefines: '', doc: 'basis' });
const tagged = (...names: string[]): TagIndex => ({
  byElement: new Map(),
  byKeyword: new Map(),
  has: (q, k) => k === 'Estimate' && names.map(qn).includes(q),
  taggedWith: (k) => (k === 'Estimate' ? names.map(qn) : []),
});
const input = (moes: string[], elements: ReturnType<typeof attr>[], tags: TagIndex): PredicateInput => ({
  step: stepById('S32'),
  layer: 'LA',
  root: ROOT,
  knobs: { modes_states: true, interfaces: true, variability: true, safety: false, views: false, verification: true, requirements_intake: false, infrastructure_intake: false },
  brief: { systemName: ROOT, aliases: [], moes, capabilities: [] },
  payloads: { elements },
  tags,
  blocking: true,
  alternative: 1,
});
const messages = (i: PredicateInput) => PREDICATES['moe.estimated'](i).map((x) => x.message).join('\n');

describe('moe.estimated', () => {
  it('clears a layer that states every measure, tagged and valued', () => {
    expect(PREDICATES['moe.estimated'](input(['coverage', 'latency'], [attr('coverage', '0.97'), attr('latency', '8')], tagged('coverage', 'latency')))).toEqual([]);
  });

  it('names each missing piece and quotes the line to write', () => {
    expect(messages(input(['coverage'], [], tagged()))).toContain('#Estimate attribute coverage :> Common::coverage = <worst-case value>');
    expect(messages(input(['coverage'], [attr('coverage', '')], tagged('coverage')))).toContain('has no value and nothing fixes it');
    expect(messages(input(['coverage'], [attr('coverage', '0.97')], tagged()))).toContain('is not tagged');
  });

  it('accepts a valueless estimate the solver fixed to one value, and not a range', () => {
    const derived = input(['coverage'], [attr('coverage', '')], tagged('coverage'));
    derived.payloads.estimates = { coverage: { min: 0.96, max: 0.96 } };
    expect(PREDICATES['moe.estimated'](derived)).toEqual([]);
    derived.payloads.estimates = { coverage: { min: 0.9, max: 0.96 } };
    expect(messages(derived)).toContain('nothing fixes it to one. Derive it');
  });

  it('asks for a literal when Sysprose refused the derived point, and leaves a literal alone', () => {
    const refused = input(['coverage'], [attr('coverage', '')], tagged('coverage'));
    refused.payloads.estimates = { coverage: { refused: 'the optimiser answered and this tool’s own evaluator would not confirm the point it stopped at: this tool’s own evaluator makes `coverage == (1.0 / n) * (1.0 + m)` false at the point the solver chose, not true.' } };
    expect(messages(refused)).toContain('`coverage == (1.0 / n) * (1.0 + m)` does not hold exactly in floating point');
    expect(messages(refused)).toContain('state the worst case as a literal');
    const literal = input(['coverage'], [attr('coverage', '0.9')], tagged('coverage'));
    literal.payloads.estimates = refused.payloads.estimates;
    expect(PREDICATES['moe.estimated'](literal)).toEqual([]);
  });

  it('blocks, and is silent for a brief without measures', () => {
    expect(PREDICATES['moe.estimated'](input(['coverage'], [], tagged()))[0].blocking).toBe(true);
    expect(PREDICATES['moe.estimated'](input([], [], tagged()))).toEqual([]);
  });

  it('is wired into both alternatives steps', () => {
    for (const id of ['S32', 'S41'] as const) {
      expect(stepById(id).checks.flatMap((c) => c.predicates ?? [])).toContain('moe.estimated');
    }
  });
});
