/**
 * An unallocated function, and when the message may blame a path.
 */
import { describe, expect, it } from 'vitest';
import { PREDICATES, type PredicateInput } from '../../src/check/predicates.ts';
import { step as stepById } from '../../src/spec/steps.ts';
import type { TagIndex } from '../../src/sysprose/backend.ts';
import type { TracePayload } from '../../src/sysprose/types.ts';

const ROOT = 'Swarm';
const el = (qn: string, metaclass: string) => ({ id: qn, qualifiedName: `${ROOT}::${qn}`, name: qn.split('::').pop()!, metaclass, type: '', multiplicity: '', value: '', redefines: '', doc: 'd' });
const noTags: TagIndex = { byElement: new Map(), byKeyword: new Map(), has: () => false, taggedWith: () => [] };
const link = (from: string, to: string) => ({ fromName: `${ROOT}::${from}`, toName: `${ROOT}::${to}` });
const input = (links: ReturnType<typeof link>[]): PredicateInput => ({
  step: stepById('S41'),
  layer: 'PA',
  root: ROOT,
  knobs: { modes_states: true, interfaces: true, variability: true, safety: true, views: false, verification: true, requirements_intake: false, infrastructure_intake: false },
  payloads: { elements: [el('PA::handOverSector', 'ActionUsage'), el('PA::recordDecision', 'ActionUsage')], 'trace-allocate': { links } as unknown as TracePayload },
  tags: noTags,
  blocking: true,
});
const messages = (links: ReturnType<typeof link>[]) => PREDICATES['allocate.functionsAllocated'](input(links)).map((x) => x.message);

describe('allocate.functionsAllocated', () => {
  it("blames a path only when this layer's part received the other layer's function, definitions included", () => {
    const msgs = messages([link('LA::HandOverSector', 'PA::fleet'), link('LA::recordDecision', 'LA::memberA')]);
    expect(msgs[0]).toContain('names the `handOverSector` of another layer by its path');
    // The layer above allocating its own function is not this layer's mistake.
    expect(msgs[1]).toContain('`recordDecision` is a function nothing performs. Add');
  });
});
