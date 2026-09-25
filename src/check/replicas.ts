/**
 * What a layer says about its population, counted one way for every reader.
 *
 * The gates that demand a fleet and the evaluation that scores where command
 * and control lives both need the same facts — which usages are the fleet and
 * which its representatives, which connections join two members, and which
 * tagged functions sit on board. Counted twice, they would drift; a gate would
 * pass an alternative the score then misreads.
 */
import type { LayerView } from '../transition/view.ts';
import type { ElementRow } from '../sysprose/types.ts';
import type { BriefFacts } from './predicates.ts';

export type Population = NonNullable<BriefFacts['population']>;

export interface ReplicaFacts {
  /** The member definition is declared in this layer. */
  memberDef: boolean;
  /** Usages of the member definition with no multiplicity above one. */
  representatives: string[];
  /** The usage carrying the population, with its multiplicity as written. */
  fleet?: { name: string; multiplicity: string; lower: number };
  /** Connections or interfaces whose ends are two different representatives. */
  peerLinks: Array<{ name?: string; type?: string; from: string; to: string }>;
  /** Tagged functions of this layer. */
  coordination: string[];
  c2: string[];
  /** Tagged function → the usage path it is allocated to. */
  placement: Map<string, string>;
  /** Tagged functions allocated to a representative or to the fleet. */
  onBoard: string[];
  /**
   * The tagged functions by DEFINITION — what the brief names and what the
   * architecture decision moves. Counted by usage, v4's two alternatives read
   * 12/20 and 15/20 on board where they differed by three definitions: each
   * member's half of an activity is on the member in either design.
   */
  types: FunctionType[];
}

/**
 * One coordination or command-and-control function, by definition.
 *
 * `place` reads every allocation of every usage, actors aside:
 * - `on board` — something is allocated to a member or the fleet, and nothing to anything else;
 * - `ground` — some usage sits on a part that is neither;
 * - `actor` — only the environment performs it, so it is neither on board nor on the ground;
 * - `unallocated` — nothing is allocated.
 * An `x/n on board` therefore does not add up with `ground` when actors perform some.
 */
export interface FunctionType {
  def: string;
  tag: 'Coordination' | 'C2';
  usages: Array<{ name: string; targets: string[] }>;
  place: 'on board' | 'ground' | 'actor' | 'unallocated';
}

const MULTIPLICITY = /^(\d+)(?:\.\.(\d+|\*))?$/;
const first = (path: string | undefined): string | undefined => path?.split('::')[0]?.split('.')[0];

export function replicaFacts(view: LayerView, elements: ElementRow[], population: Population): ReplicaFacts {
  const at = `${view.root}::${view.layer}::`;
  const direct = (qn: string): boolean => qn.startsWith(at) && !qn.slice(at.length).includes('::');
  const usages = elements.filter(
    (e) => e.metaclass === 'PartUsage' && direct(e.qualifiedName) && e.type.split('::').pop() === population.memberDef,
  );
  const lowerOf = (m: string): number => {
    const match = MULTIPLICITY.exec(m.trim());
    return match ? Number(match[1]) : 1;
  };
  const representatives = usages.filter((u) => lowerOf(u.multiplicity) <= 1).map((u) => u.name);
  const fleetRow = usages.find((u) => lowerOf(u.multiplicity) >= 2);
  const reps = new Set(representatives);
  const peerLinks = view.connections
    .map((c) => ({ c, a: first(c.from), b: first(c.to) }))
    .filter(({ a, b }) => a !== undefined && b !== undefined && a !== b && reps.has(a) && reps.has(b))
    .map(({ c }) => ({ name: c.name, type: c.type, from: c.from!, to: c.to! }));
  const tagged = (tag: string): string[] => view.actions.filter((a) => a.keywords.includes(tag)).map((a) => a.name);
  const coordination = tagged('Coordination');
  const c2 = tagged('C2');
  const taggedSet = new Set([...coordination, ...c2]);
  const placement = new Map<string, string>();
  for (const a of view.allocations) if (taggedSet.has(a.actionName)) placement.set(a.actionName, a.partName);
  const aboard = new Set([...representatives, ...(fleetRow ? [fleetRow.name] : [])]);
  const onBoard = [...placement.entries()].filter(([, part]) => aboard.has(first(part) ?? '')).map(([fn]) => fn);
  const actors = new Set(view.parts.filter((pt) => pt.isActor).map((pt) => pt.name));
  const byDef = new Map<string, FunctionType>();
  for (const a of view.actions) {
    const words = new Set([...a.keywords, ...(a.defKeywords ?? [])]);
    const tag = words.has('Coordination') ? 'Coordination' : words.has('C2') ? 'C2' : undefined;
    if (!tag) continue;
    const def = a.defName ?? a.name;
    const entry = byDef.get(def) ?? { def, tag, usages: [], place: 'unallocated' as FunctionType['place'] };
    entry.usages.push({ name: a.name, targets: view.allocations.filter((x) => x.actionName === a.name).map((x) => x.partName) });
    byDef.set(def, entry);
  }
  for (const t of byDef.values()) {
    const all = t.usages.flatMap((u) => u.targets);
    const solution = all.filter((part) => !actors.has(first(part) ?? ''));
    t.place =
      all.length === 0 ? 'unallocated' : solution.length === 0 ? 'actor' : solution.every((part) => aboard.has(first(part) ?? '')) ? 'on board' : 'ground';
  }
  return {
    types: [...byDef.values()],
    memberDef: view.partDefs.some((d) => d.name === population.memberDef),
    representatives,
    fleet: fleetRow ? { name: fleetRow.name, multiplicity: fleetRow.multiplicity, lower: lowerOf(fleetRow.multiplicity) } : undefined,
    peerLinks,
    coordination,
    c2,
    placement,
    onBoard,
  };
}
