/**
 * The post-conditions, scoped to the layer being authored.
 *
 * A command is only half a check: `trace --relation allocate` exits 0 on a
 * layer where nothing is allocated, and `connectivity` exits 0 with five ports
 * hanging. These are the other half, and they are calibrated against the
 * validated reference model — every one of them passes on it, so a finding here
 * is a finding about the model under construction rather than about this
 * project's idea of a correct model.
 *
 * Two orientations are measured, not assumed, and getting either backwards
 * silently inverts a gate:
 *
 *   `allocate <action> to <part>` links  action -> part   (as written)
 *   `trace <lower> to <upper>`    links  upper  -> lower  (reversed)
 *
 * So "X realises Y" reads as a link FROM Y (the upper element) TO X.
 */
import { estimateLine } from '../spec/measures.ts';
import { identifierOf } from '../spec/names.ts';
import { RULE_PATTERN, isUnreadable, ruleReading, ruleTemplate, type RuleRow } from '../spec/rules.ts';
import type { TagIndex } from '../sysprose/backend.ts';
import type { ConnectivityReport, ElementRow, OrphanReport, ReachReport, RequirementsPayload, TracePayload } from '../sysprose/types.ts';
import type { CheckReport } from '../sysprose/types.ts';
import { layerIndex, previousAuthoredLayer, type Layer } from '../spec/layers.ts';
import type { PredicateId, StepSpec } from '../spec/steps.ts';
import { noteFor } from '../spec/codes.ts';
import { isReservedName } from '../spec/keywords.ts';
import type { ActionView, LayerView } from '../transition/view.ts';
import { replicaFacts, type FunctionType } from './replicas.ts';
import { PLACEHOLDER } from '../transition/skeleton.ts';
import type { Knobs, RepairItem } from './classify.ts';

/** What SEED settled, as the predicates need it. */
export interface BriefFacts {
  systemName: string;
  /** Other spellings of the system's name an OA element must not use. */
  aliases: string[];
  moes: string[];
  /** The measures with what the brief said about each, for checks that need the numbers. */
  measures?: { name: string; sense?: string; target?: number | null; unit?: string; doc?: string }[];
  /** The numbers the brief fixes, by name — `fleetSize`, the duty cycle, the area. */
  budgets?: Record<string, number>;
  /** The capabilities the brief named, which the operational analysis has to carry. */
  capabilities: string[];
  /** The OA entity the system takes over; its part must exist under this exact name. */
  systemEntity?: string;
  /** The members, when the system is a population of identical ones. */
  population?: {
    memberDef: string;
    fleetPart: string;
    size: number;
    meshPort: string;
    meshInterface: string;
    coordinationCapability: string;
    bearer?: string;
  };
  /** Functions members perform between themselves, named by the brief. */
  coordinationFunctions?: string[];
  /** Command-and-control functions, named by the brief. */
  c2Functions?: string[];
  /** Hazards the brief names: each is stated at SA under this name. */
  hazards?: string[];
  /** Rules the system never breaks, each carried as a checked property. */
  rules?: Array<{ name: string; kind: 'winsUntil' | 'precededBy' | 'canAlwaysReturn'; of: 'member' | 'fleet' | 'ground' | 'system' }>;
  /** Operating modes the brief names, each a state of the right owner. */
  modes?: Array<{ name: string; of: 'member' | 'fleet' | 'ground' | 'system' }>;
  /** Items whose fields the brief lists, each an item def in Common. */
  items?: Array<{ name: string; fields: string[] }>;
}

export type PayloadBag = Record<string, unknown>;

export interface PredicateInput {
  step: StepSpec;
  layer?: Layer;
  root: string;
  knobs: Knobs;
  brief?: BriefFacts;
  /** Every payload this step collected, by check name. `elements` is always present. */
  payloads: PayloadBag;
  tags: TagIndex;
  /** The blocking status of the check that owns this predicate. */
  blocking: boolean;
  /** The alternative under test, when there is one. */
  alternative?: number;
  /** Below this share of documented elements the layer blocks. 0 turns the gate off. */
  docCoverageMin?: number;
}

export type Predicate = (input: PredicateInput) => RepairItem[];

/* ────────────────────────────── small helpers ───────────────────────────── */

const prefixOf = (root: string, layer: Layer): string => `${root}::${layer}::`;
const inLayer = (qn: string, root: string, layer: Layer): boolean => qn.startsWith(prefixOf(root, layer));
/** A direct child of the layer package: `Root::Layer::name`. */
const isDirect = (qn: string, root: string, layer: Layer): boolean =>
  inLayer(qn, root, layer) && qn.slice(prefixOf(root, layer).length).includes('::') === false;

const simpleName = (qn: string): string => qn.split('::').pop() ?? qn;

const isGuidance = (qn: string, tags: TagIndex): boolean =>
  tags.has(qn, 'prompt') || tags.has(qn, 'prose') || tags.has(qn, "'requirement'");

const elementsOf = (input: PredicateInput): ElementRow[] => (input.payloads.elements as ElementRow[]) ?? [];

const trace = (input: PredicateInput, name = 'trace-trace'): TracePayload | undefined =>
  input.payloads[name] as TracePayload | undefined;

/** Usages whose type is a definition tagged `#Actor` — the elements a layer does not own. */
function actorUsages(input: PredicateInput): Set<string> {
  const actorDefs = new Set(input.tags.taggedWith('Actor').map(simpleName));
  const out = new Set<string>();
  for (const el of elementsOf(input)) {
    const type = simpleName(el.type ?? '');
    if (type && actorDefs.has(type)) out.add(el.qualifiedName);
    if (input.tags.has(el.qualifiedName, 'Actor')) out.add(el.qualifiedName);
  }
  return out;
}

/** Functions allocated to a part this layer does not own. */
function actorAllocatedFunctions(input: PredicateInput): Set<string> {
  const allocate = trace(input, 'trace-allocate');
  if (!allocate) return new Set();
  const actors = actorUsages(input);
  return new Set(allocate.links.filter((l) => actors.has(l.toName)).map((l) => l.fromName));
}

function item(partial: Omit<RepairItem, 'source' | 'blocking'> & { blocking: boolean }): RepairItem {
  return { source: 'predicate', ...partial };
}

/* ──────────────────────────────  predicates  ────────────────────────────── */

const oaNoSystemName: Predicate = (input) => {
  const brief = input.brief;
  if (!brief || !input.layer) return [];
  const needles = [brief.systemName, ...brief.aliases]
    .map((n) => n.replace(/[^A-Za-z0-9]/g, '').toLowerCase())
    .filter((n) => n.length >= 4);
  if (needles.length === 0) return [];
  return elementsOf(input)
    .filter((el) => inLayer(el.qualifiedName, input.root, input.layer!) && el.name)
    .filter((el) => {
      const name = el.name.replace(/[^A-Za-z0-9]/g, '').toLowerCase();
      return needles.some((n) => name.includes(n));
    })
    .map((el) =>
      item({
        code: 'oa.noSystemName',
        severity: 'error',
        blocking: input.blocking,
        cv: 'CV-01',
        qualifiedName: el.qualifiedName,
        message: `\`${el.name}\` names the system inside the operational analysis. OA describes the operation without the system (A1-R-06) — name the activity or the entity by what it does, not by the solution.`,
      }),
    );
};

/**
 * The capabilities the brief named are in the model.
 *
 * Measured on a live run: an operational analysis came back with 21 activities,
 * 12 exchanges — and no use case at all, so the transition carried nothing for
 * the system to be asked for. A capability that exists only in the brief is a
 * capability the architecture is never held to.
 */
const oaCapabilities: Predicate = (input) => {
  const wanted = input.brief?.capabilities ?? [];
  if (wanted.length === 0 || !input.layer) return [];
  const declared = new Set(
    elementsOf(input)
      .filter((e) => e.metaclass === 'UseCaseDefinition' && inLayer(e.qualifiedName, input.root, input.layer!))
      .map((e) => e.name),
  );
  const missing = wanted.filter((name) => !declared.has(name));
  if (missing.length === 0) return [];
  return [
    item({
      code: 'oa.capabilities',
      severity: 'error',
      blocking: input.blocking,
      qualifiedName: undefined,
      message: `the brief names ${wanted.length} capability(ies) and this layer declares ${declared.size}. Missing: ${missing.join(', ')}. Each is a \`#Capability use case def <Name> { subject e : <Entity>; }\` — it is what the system will be asked for at the next layer.`,
    }),
  ];
};

/**
 * The entity the system takes over exists in OA under the brief's name.
 *
 * The transition allocates that entity's activities to the system by name.
 * Measured: the brief said `surveillanceAsset`, OA declared `#Actor part
 * watchAsset`, and ten allocations landed in SA naming a part that does not
 * exist there. Untagged, because an actor is by definition what the system is
 * not.
 */
const oaSystemEntity: Predicate = (input) => {
  const wanted = input.brief?.systemEntity;
  if (!wanted || !input.layer) return [];
  const parts = elementsOf(input).filter(
    (e) => e.metaclass === 'PartUsage' && isDirect(e.qualifiedName, input.root, input.layer!) && !isGuidance(e.qualifiedName, input.tags),
  );
  const actors = actorUsages(input);
  const found = parts.find((e) => e.name === wanted);
  if (found && !actors.has(found.qualifiedName)) return [];
  const others = parts.filter((e) => !actors.has(e.qualifiedName)).map((e) => e.name);
  return [
    item({
      code: 'oa.systemEntity',
      severity: 'error',
      blocking: input.blocking,
      qualifiedName: found?.qualifiedName,
      message: found
        ? `\`${wanted}\` is the entity the system takes over, and it is tagged as an actor. An actor is what the system is not: remove the #Actor tag from its definition.`
        : `the brief settled \`${wanted}\` as the entity the system takes over, and this layer declares no part of that name. Declare \`part ${wanted} : <Def>;\` untagged and allocate its activities to it — the next layer turns exactly those into system functions.${others.length > 0 ? ` Untagged parts here: ${others.join(', ')}.` : ''}`,
    }),
  ];
};

/**
 * Every type a usage carries, by simple name.
 *
 * `elements` reports a redefining usage's type as a list: an action written
 * `action alphaHandOverSector : HandOverSector :>> handOverSector` comes back
 * as `"HandOverSector, handOverSector"`, the type and the feature it redefines.
 * Comparing that whole string against a definition name finds nothing, and the
 * run that hit it spent three repair rounds being told to write the usage it
 * had already written.
 */
const typesOf = (row: { type?: string }): string[] =>
  (row.type ?? '')
    .split(',')
    .map((part) => simpleName(part.trim()))
    .filter((part) => part !== '');


/**
 * The brief's coordination and C2 functions are named at OA, as definitions.
 *
 * Each member performs its own usage of an activity, and the transition merges
 * the members' usages into one system function named after the definition
 * they share. That name is the brief's only when the OA definition is — so it
 * is anchored here, where the author can still write it, rather than at SA,
 * where renaming an operational definition is out of the author's reach.
 */
const oaNamedFunctions: Predicate = (input) => {
  const brief = input.brief;
  if (!brief?.population || !input.layer) return [];
  const all = elementsOf(input);
  const direct = (e: ElementRow): boolean => isDirect(e.qualifiedName, input.root, input.layer!);
  const rows = all.filter((e) => e.metaclass === 'ActionDefinition' && direct(e));
  // The representatives, as oa.members finds them: parts typed like the entity.
  const parts = all.filter((e) => e.metaclass === 'PartUsage' && direct(e));
  const entityDef = simpleName(parts.find((e) => e.name === brief.systemEntity)?.type ?? '');
  const members = new Set(parts.filter((e) => entityDef !== '' && typesOf(e).includes(entityDef)).map((e) => e.qualifiedName));
  const allocate = trace(input, 'trace-allocate');
  const wanted = [
    ...(brief.coordinationFunctions ?? []).map((name) => ({ name, tag: 'Coordination' as const })),
    ...(brief.c2Functions ?? []).map((name) => ({ name, tag: 'C2' as const })),
  ];
  return wanted.flatMap(({ name, tag }) => {
    const def = name[0].toUpperCase() + name.slice(1);
    const label = tag === 'C2' ? 'command and control' : 'coordination between members';
    const row = rows.find((e) => e.name === def);
    const fail = (message: string): RepairItem[] => [
      item({ code: 'oa.namedFunctions', severity: 'error', blocking: input.blocking, cv: 'CV-16', qualifiedName: row?.qualifiedName, message }),
    ];
    if (!row)
      return fail(`the brief names \`${name}\` as ${label}, and this layer declares no \`action def ${def}\`. Declare \`#${tag} action def ${def} { doc /* … */ }\` and type the activity each member performs by it — \`action alpha${def} : ${def};\` — so the next layer merges the members\' activities into one function of that name.`);
    if (!input.tags.has(row.qualifiedName, tag)) return fail(`\`${def}\` is ${label} and its definition is not tagged: write \`#${tag} action def ${def}\`.`);
    const usages = all.filter((e) => e.metaclass === 'ActionUsage' && direct(e) && typesOf(e).includes(def));
    if (usages.length === 0)
      return fail(`\`${def}\` is declared and nothing is typed by it **at the level of this layer**. Write the usage directly in \`package ${input.layer}\` — \`action alpha${def} : ${def};\` — and \`allocate\` it to the member that performs it. An activity nested inside a member's part does not count and is not a matter of taste: CV-16 makes the allocation the architecture decision, and the transition to the next layer reads the allocations, so a layer that owns its activities instead carries no functions down at all.`);
    // Coordination is what members settle between themselves, so each of two
    // members performs its own usage; that is the shape T-01 merges. Command
    // and control is often the operator's today, so one usage anywhere will do.
    if (tag === 'Coordination' && allocate && members.size >= 2) {
      const on = new Set(
        allocate.links.filter((l) => usages.some((u) => u.qualifiedName === l.fromName) && members.has(l.toName)).map((l) => l.toName),
      );
      if (on.size < 2)
        return fail(`\`${def}\` is coordination between members, and ${on.size === 0 ? 'no member performs it' : 'only one member performs it'}. Give each representative its own usage typed by the same definition — \`action alpha${def} : ${def};\` allocated to one, \`action bravo${def} : ${def};\` to the other — with the flow between them. An activity typed by its own ad-hoc definition per member is not merged into one function.`);
    }
    return [];
  });
};

/**
 * A population at OA is at least two representatives, each doing something.
 *
 * Three runs modelled one `WatchAsset` that "stands in for the fleet", and
 * with one entity there is nowhere for an interaction between two members to
 * attach — so none was ever modelled, at any layer. Two usages of the entity's
 * definition, each an allocation target, is the smallest shape in which
 * drone-to-drone exchange can exist.
 */
const oaMembers: Predicate = (input) => {
  const brief = input.brief;
  const allocate = trace(input, 'trace-allocate');
  if (!brief?.population || !brief.systemEntity || !allocate || !input.layer) return [];
  const parts = elementsOf(input).filter(
    (e) => e.metaclass === 'PartUsage' && isDirect(e.qualifiedName, input.root, input.layer!) && !isGuidance(e.qualifiedName, input.tags),
  );
  const entity = parts.find((e) => e.name === brief.systemEntity);
  if (!entity) return []; // oa.systemEntity says so, once
  const def = simpleName(entity.type);
  const representatives = parts.filter((e) => typesOf(e).includes(def));
  const busy = new Set(allocate.links.map((l) => l.toName));
  const active = representatives.filter((e) => busy.has(e.qualifiedName));
  if (active.length >= 2) return [];
  const second = `${brief.systemEntity.replace(/[AB0-9]$/, '')}B`;
  return [
    item({
      code: 'oa.members',
      severity: 'error',
      blocking: input.blocking,
      qualifiedName: entity.qualifiedName,
      message: `the brief declares a population of ${brief.population.size}, and this layer has ${active.length} \`${def}\` with activities of its own. Model at least two representatives — \`part ${second} : ${def};\` beside \`${brief.systemEntity}\` — allocate each one the activities it performs, and write what they exchange with each other as flows between their activities (handing a sector over, relaying a report). One instance standing in for the fleet leaves nowhere for an interaction between members to exist.`,
    }),
  ];
};

/* ───────────────────────────── the population ───────────────────────────── */

const facts = (input: PredicateInput) => {
  const p = input.brief?.population;
  const view = input.payloads.layerView as LayerView | undefined;
  if (!p || !view || !input.layer) return undefined;
  return { p, view, f: replicaFacts(view, elementsOf(input), p) };
};

/** A fleet's multiplicity covers the brief's size: `[12]`, `[10..12]`, `[2..*]`. */
export function sizeCovers(multiplicity: string, size: number): boolean {
  const m = /^\s*(\d+)\s*(?:\.\.\s*(\d+|\*))?\s*$/.exec(multiplicity);
  if (!m) return false;
  const lower = Number(m[1]);
  const upper = m[2] === undefined ? lower : m[2] === '*' ? Infinity : Number(m[2]);
  return lower <= size && size <= upper;
}

/**
 * A population is a member definition, its fleet and a representative pair
 * that exchange (CV-16).
 *
 * Every sub-condition is its own item, quoting the line to write, because the
 * three runs before this gate existed show what an author does with a vague
 * demand: one `WatchAsset` "standing in for the fleet".
 */
const replicasMemberPair: Predicate = (input) => {
  const x = facts(input);
  if (!x) return [];
  const { p, f } = x;
  const out: RepairItem[] = [];
  const fail = (message: string): void =>
    void out.push(item({ code: 'replicas.memberPair', severity: 'error', blocking: input.blocking, cv: 'CV-16', message }));
  if (!f.memberDef)
    fail(`no member definition in this layer. Declare \`#Member part def ${p.memberDef} { out port meshOut : Common::${p.meshPort}; in port meshIn : ~Common::${p.meshPort}; }\` — the replicable element every drone of the fleet is.`);
  if (!f.fleet) fail(`nothing carries the population. Add \`part ${p.fleetPart} : ${p.memberDef} [${p.size}];\` — the brief sizes it at ${p.size}.`);
  else if (!sizeCovers(f.fleet.multiplicity, p.size))
    fail(`\`${f.fleet.name}\` is sized \`[${f.fleet.multiplicity}]\` and the brief sizes the population at ${p.size}. Write \`[${p.size}]\`, or a range that contains it.`);
  if (f.representatives.length < 2)
    fail(`${f.representatives.length} representative(s) of \`${p.memberDef}\`. Add \`part memberA : ${p.memberDef};\` and \`part memberB : ${p.memberDef};\` — an exchange between two members is written between two named usages; \`${p.fleetPart}[1]\` does not parse.`);
  if (f.peerLinks.length === 0) {
    const typeHint = input.layer === 'PA' ? 'a connection typed by the connection def of the medium that carries it' : `\`interface peerLink : Common::${p.meshInterface}\``;
    fail(`no link between two members. Write ${typeHint} \`connect memberA.meshOut to memberB.meshIn;\` — without it the swarm is ${p.size} drones that never talk to each other.`);
  } else if (input.layer === 'LA' && !f.peerLinks.some((l) => l.type === p.meshInterface)) {
    fail(`the link between members is typed \`${f.peerLinks[0].type ?? '(untyped)'}\`. At LA it is \`Common::${p.meshInterface}\`, the peer interface the brief settled.`);
  } else if (input.layer === 'PA' && !f.peerLinks.some((l) => !!l.type)) {
    fail('the link between members is untyped. At PA it is a connection typed by the connection def of the medium that carries it.');
  }
  return out;
};

/**
 * Alternative 1 keeps command and control on the ground; alternative 2 puts
 * coordination on the members.
 *
 * Left to themselves, both alternatives of the third run were ground-centric,
 * and the trade-off compared two stars. The decision the brief asks for is
 * only made if the two sides of it exist.
 */
const altC2Placement: Predicate = (input) => {
  const x = facts(input);
  const k = input.alternative;
  if (!x || (k !== 1 && k !== 2)) return [];
  // By definition, not by usage: each member's half of an activity sits on the
  // member in any design, and counting halves let both alternatives pass
  // while differing by three functions.
  const { f } = x;
  const where = (t: FunctionType): string =>
    t.usages.map((u) => `\`${u.name}\` on ${u.targets.length > 0 ? u.targets.map((p) => `\`${p}\``).join(', ') : 'nothing'}`).join('; ');
  const fail = (message: string): RepairItem =>
    item({ code: 'alt.c2Placement', severity: 'error', blocking: input.blocking, cv: 'CV-16', message });
  const coordination = f.types.filter((t) => t.tag === 'Coordination');
  const aboard = coordination.filter((t) => t.place === 'on board');
  if (k === 1) {
    const out: RepairItem[] = [];
    const c2Aboard = f.types.filter((t) => t.tag === 'C2' && t.place === 'on board');
    if (c2Aboard.length > 0)
      out.push(fail(`alternative 1 is the ground-centric design, and ${c2Aboard.length} command-and-control function(s) are on a member: ${c2Aboard.map(where).join('; ')}. Allocate them to a ground component.`));
    if (coordination.length > 0 && aboard.length * 2 >= coordination.length)
      out.push(fail(`alternative 1 is the ground-centric design, and ${aboard.length} of ${coordination.length} coordination function(s) are decided on the members alone: ${aboard.map((t) => `\`${t.def}\``).join(', ')}. The ground decides — who holds a sector, who recharges, how coverage is re-spread; members carry out what they are assigned; every usage of a deciding function goes on a ground component.`));
    return out;
  }
  const out: RepairItem[] = [];
  if (coordination.length > 0 && aboard.length * 2 < coordination.length) {
    const ground = coordination.filter((t) => t.place !== 'on board');
    out.push(fail(`alternative 2 is the distributed design, and ${aboard.length} of ${coordination.length} coordination function(s) are on the members alone. Move every usage of these to \`memberA\`, \`memberB\` or the fleet: ${ground.map((t) => `\`${t.def}\` (${where(t)})`).join('; ')}.`));
  }
  // What the distributed design distributes is coordination. Command and
  // control is what the operator exercises, and it enters from the ground in
  // both designs; a member may hold a copy (recall reaching every member), not
  // the only one. Measured: v5's distributed PA put tasking and the status
  // picture on "the active duty member" alone, and nothing said otherwise.
  const c2Aboard = f.types.filter((t) => t.tag === 'C2' && t.place === 'on board');
  if (c2Aboard.length > 0)
    out.push(fail(`alternative 2 distributes coordination, not command: ${c2Aboard.length} command-and-control function(s) have no ground usage — ${c2Aboard.map((t) => `\`${t.def}\` (${where(t)})`).join('; ')}. Allocate each to a ground component as well; a member may keep its own usage.`));
  return out;
};

/** Where the tagged functions sit, per alternative — the fact the trade-off is about. */
const replicasTopology: Predicate = (input) => {
  const x = facts(input);
  if (!x) return [];
  const { f } = x;
  if (f.types.length === 0) return [];
  const count = (place: FunctionType['place']): number => f.types.filter((t) => t.place === place).length;
  return [
    item({
      code: 'replicas.topology',
      severity: 'info',
      blocking: false,
      cv: 'CV-16',
      message: `${input.alternative ? `alternative ${input.alternative}: ` : ''}${count('on board')} of ${f.types.length} coordination and command-and-control function(s) on board, ${count('ground')} on the ground${count('actor') > 0 ? `, ${count('actor')} performed by actors` : ''}; ${f.peerLinks.length} link(s) between members; fleet ${f.fleet ? `[${f.fleet.multiplicity}]` : 'absent'}.`,
    }),
  ];
};

/**
 * A budget the brief fixes, found by what it means rather than by its spelling.
 *
 * SEED names the budgets; the brief is prose. v7 produced
 * `memberRechargeMinutes` and `areaOfInterestKm2`, v8 produced
 * `groundTurnaroundMinutes` and `areaOfInterestSquareKilometres` from the same
 * paragraph — and two gates keyed on the first spellings went silent on the
 * second run without anyone noticing, which is the worst way for a check to
 * fail. Patterns, and the first match wins.
 */
const budgetLike = (
  budgets: Readonly<Record<string, number>>,
  pattern: RegExp,
): number | undefined => {
  const key = Object.keys(budgets).find((name) => pattern.test(name));
  return key === undefined ? undefined : budgets[key];
};

const BUDGET = {
  endurance: /enduran/i,
  /** Time on the ground between sorties, however the brief words it. */
  turnaround: /recharge|turnaround|refuel|swap/i,
  area: /area/i,
  speed: /speed|cruise/i,
  fleet: /fleet.?size|size.?fleet|fleet.?count/i,
  /** What one member keeps under watch at once, when the brief fixes it. */
  footprint: /footprint|sensor.?(area|coverage)|coverage.?per/i,
} as const;


/**
 * A member has to be able to reach its station and come back.
 *
 * Flown at v7's own numbers, the fleet spent between 142 and 306 seconds on the
 * return leg alone against a flight budget of 240: a member could use more than
 * its whole endurance simply coming home, and the watch share measured 0.18
 * where the duty cycle alone would have allowed 0.40. The endurance in the
 * brief is stated as though it were all spent on station; at the area's scale
 * most of it is transit.
 *
 * The arithmetic is ordinary — `2 x distance / speed` against the endurance —
 * and the only reason it could not be checked before a flight is that v7 never
 * states a cruise speed. SEED now asks for one, and this fires the moment a
 * brief carries it. Where the brief is silent this says nothing at all: a check
 * that guessed a speed would be inventing the fact it exists to test.
 *
 * `distance` is the worst case a member can be sent to: T-05 lays one sector
 * per member over the area, so the furthest station is the far corner of the
 * furthest sector, which is what `sqrt(area)/2 * sqrt(2)` measures from a
 * centre. That is the same reading of the area the simulation flies.
 */
const moeTransitBudget: Predicate = (input) => {
  const budgets = input.brief?.budgets ?? {};
  const area = budgetLike(budgets, BUDGET.area);
  const endurance = budgetLike(budgets, BUDGET.endurance);
  const speed = budgetLike(budgets, BUDGET.speed);
  if (typeof area !== 'number' || typeof endurance !== 'number' || typeof speed !== 'number') return [];
  if (area <= 0 || endurance <= 0 || speed <= 0) return [];

  // Metres to the far corner of the area from a centre, and the seconds a
  // member spends going there and back at the stated speed.
  const halfDiagonal = (Math.sqrt(area) * 1000) / 2 * Math.SQRT2;
  const transitSeconds = (2 * halfDiagonal) / speed;
  const enduranceSeconds = endurance * 60;
  if (transitSeconds < enduranceSeconds) return [];

  return [
    item({
      code: 'moe.transitBudget',
      severity: 'error',
      blocking: input.blocking,
      cv: 'CV-17',
      message:
        `A member cannot reach its station and return inside the endurance the brief fixes. The area is ` +
        `${area} km\u00b2, so the furthest station is ${round2(halfDiagonal)} m from the centre; at ` +
        `${speed} m/s that is ${round2(transitSeconds)} s there and back, against ` +
        `${round2(enduranceSeconds)} s of endurance (${endurance} min). A member would spend its whole ` +
        `budget in transit and have none left on station. Either the brief\'s numbers need revisiting ` +
        `\u2014 a faster member, a longer endurance, a smaller area, or stations closer than the far ` +
        `corner \u2014 or the architecture has to say how it holds the watch anyway, and derive its ` +
        `coverage measure from that. Measured, not assumed: flown at a 240 s budget with stations up ` +
        `to 2.5 km out, v7's fleet used 142\u2013306 s on the return leg and held 0.18 of the area.`,
    }),
  ];
};

/**
 * A share claimed *at any moment* cannot beat the duty cycle the brief fixes.
 *
 * This is the gate the v7 run would have failed, and it exists because a
 * simulation later measured what it was too late to prevent. The brief fixed
 * twelve members, forty minutes of flight and sixty of recharge; a member is
 * therefore airborne for 40/100 of the time, so on average 4.8 of the twelve
 * are in the air. The architecture estimated `areaUnderWatchShare = 0.92` as a
 * bare literal, and when the model was finally flown it measured 0.39 — which
 * is 4.8/12, the duty cycle, exactly as the arithmetic says.
 *
 * The check is narrow on purpose, because a heuristic that blocks the wrong
 * thing is worse than no check. It fires only when all of these hold:
 *
 *  - the brief fixes both halves of a duty cycle, so there is a bound at all;
 *  - the measure is a dimensionless share the architecture wants **high**;
 *  - the brief's own doc claims it holds **at any moment** — the author's own
 *    words, not an inference, and it is that simultaneity that the duty cycle
 *    bounds;
 *  - and the estimate states a **literal** above the bound.
 *
 * The way out is not a bigger number, it is arithmetic: CV-17 already allows a
 * valueless `#Estimate` fixed by an `assert constraint` over this layer's own
 * values. An architecture where one member covers several sectors can say so
 * and derive the result; one that cannot, cannot. Its sibling
 * `coverageLossOnMemberLoss` was derived that way in v7 and the simulation
 * reproduced it to four figures — the measure that showed its arithmetic is
 * the one that survived contact with a runtime.
 */
const SIMULTANEOUS = /at any moment|at any time|at all times|continuously|simultaneous/i;

const moeDutyCycleBound: Predicate = (input) => {
  const budgets = input.brief?.budgets ?? {};
  const flight = budgetLike(budgets, BUDGET.endurance);
  const recharge = budgetLike(budgets, BUDGET.turnaround);
  if (typeof flight !== 'number' || typeof recharge !== 'number' || flight + recharge <= 0) return [];
  if (!input.layer) return [];

  const airborne = flight / (flight + recharge);
  const fleet = budgetLike(budgets, BUDGET.fleet);
  const area = budgetLike(budgets, BUDGET.area);
  const footprint = budgetLike(budgets, BUDGET.footprint);
  // What the fleet can actually hold under watch at once, when the brief says
  // how much one member sees: airborne members times their footprint, over the
  // area. Without a footprint the bound is the airborne share itself — one
  // member, one share — which is the case this gate was built for. With one,
  // a larger claim is arithmetic rather than optimism, and blocking it would
  // be the check refusing to read the brief.
  const reach =
    typeof fleet === 'number' && typeof area === 'number' && typeof footprint === 'number' && area > 0
      ? Math.min(1, (fleet * airborne * footprint) / area)
      : airborne;
  const rows = elementsOf(input);

  return (input.brief?.measures ?? []).flatMap((measure) => {
    if (measure.sense !== 'max') return [];
    if (measure.unit) return [];
    if (typeof measure.target !== 'number' || measure.target > 1) return [];
    if (!SIMULTANEOUS.test(measure.doc ?? '')) return [];

    const qn = `${input.root}::${input.layer}::${measure.name}`;
    const row = rows.find((e) => e.qualifiedName === qn && e.metaclass === 'AttributeUsage');
    // A missing estimate is `moe.estimated`'s business, and a valueless one is
    // already derived — which is what this asks for.
    if (!row) return [];
    const value = Number.parseFloat(row.value);
    if (!Number.isFinite(value) || value <= reach + 1e-9) return [];

    const airborneCount = typeof fleet === 'number' ? ` — ${round2(fleet * airborne)} of ${fleet}` : '';
    const cover = round2(value / reach);
    const withFootprint =
      reach !== airborne
        ? ` Even allowing the ${footprint} each member is said to keep under watch, this fleet reaches ${round2(reach)}.`
        : '';
    return [
      item({
        code: 'moe.dutyCycleBound',
        severity: 'error',
        blocking: input.blocking,
        cv: 'CV-17',
        qualifiedName: qn,
        message:
          `\`${measure.name}\` is estimated at ${value} and its own definition says it holds at any moment, ` +
          `but the brief fixes ${flight} min of flight against ${recharge} min of recharge, so a member is airborne ` +
          `${round2(airborne * 100)}% of the time${airborneCount}. Holding ${value} at any moment needs each airborne member to ` +
          `cover ${cover}\u00d7 what it can.${withFootprint} ` +
          `Either state that — a valued attribute for the per-member coverage — and derive this measure from it ` +
          `(CV-17: \`#Estimate attribute ${measure.name} :> Common::${measure.name};\` with an ` +
          `\`assert constraint\` over this layer's own values), or state an estimate the duty cycle allows. ` +
          `A literal above the bound is a claim the brief's own numbers contradict.`,
      }),
    ];
  });
};

const round2 = (n: number): number => Number(n.toFixed(2));

/**
 * Every measure has this architecture's estimate (CV-17).
 *
 * Until this gate the measures weight of every trade-off was a constant: no
 * alternative stated a value, so there was nothing for `bounds` to read. The
 * estimate is an attribute of the layer, tagged, valued, and documented — the
 * doc is where its basis goes, and doc coverage already demands one.
 */
const moeEstimated: Predicate = (input) => {
  const moes = input.brief?.moes ?? [];
  if (moes.length === 0 || !input.layer) return [];
  const rows = elementsOf(input);
  return moes.flatMap((name) => {
    const qn = `${input.root}::${input.layer}::${name}`;
    const row = rows.find((e) => e.qualifiedName === qn && e.metaclass === 'AttributeUsage');
    const line = `\`${estimateLine(name)}\``;
    const fail = (message: string): RepairItem[] => [
      item({ code: 'moe.estimated', severity: 'error', blocking: input.blocking, cv: 'CV-17', qualifiedName: row ? qn : undefined, message }),
    ];
    if (!row) {
      // Grouping them in a part def is the near miss worth naming: it looks
      // tidy, it parses, and every estimate in it is invisible. One run lost a
      // whole alternative that way — twelve estimates written, twelve reported
      // missing — and the alternative it lost was the one deriving them
      // properly instead of stating literals.
      const grouped = rows.find(
        (e) =>
          e.metaclass === 'AttributeUsage' &&
          e.name === name &&
          e.qualifiedName.startsWith(`${input.root}::${input.layer}::`) &&
          e.qualifiedName !== qn,
      );
      const where = grouped
        ? ` \`${name}\` exists at \`${grouped.qualifiedName}\`, inside something else: move it out. `
        : ' ';
      return fail(`no estimate for the measure \`${name}\` **directly in \`package ${input.layer}\`**.${where}Write ${line} beside the parts, not inside a part or a part def that collects the estimates together: the trade-off reads each estimate by its name at the level of the layer, so one nested a level deeper is not scored at all, and a measure with no estimate scores as undecided.`);
    }
    // Valueless is fine when constraints over this layer's own values fix it
    // to one number: the solver answered the same both ways.
    const derived = (input.payloads.estimates as Record<string, { min?: number; max?: number; refused?: string }> | undefined)?.[name];
    const isPoint = derived?.min !== undefined && derived.max !== undefined && Math.abs(derived.min - derived.max) <= 1e-9 * Math.max(1, Math.abs(derived.min));
    // Measured in v6 at S41: Sysprose re-evaluates the solver's point in
    // floating point and withholds the bound when an equation like
    // `r == (1.0 / n) * (1.0 + m)` is not exactly true there. Deriving again
    // cannot fix that; a literal worst case can.
    const why = derived?.refused?.match(/evaluator makes (`[^`]*`) false/)?.[1];
    if (!isPoint && derived?.refused && !/^-?\d+(\.\d+)?(e-?\d+)?$/.test(row.value.trim()))
      return fail(`\`${name}\` is derived, but the solver's value for it could not be confirmed: ${why ? `${why} does not hold exactly in floating point at the solver's point` : 'the evaluator would not reproduce the solver\'s point'}, and every measure that equation reaches gets no bound. Keep the inputs, drop that \`assert constraint\`, and state the worst case as a literal with its arithmetic in the doc: ${line}.`);
    if (row.value.trim() === '' && !isPoint)
      return fail(`\`${name}\` has no value and nothing fixes it to one. Derive it — restate the numbers the brief fixes as attributes of this layer and write \`assert constraint { ${name} == <expression over them> }\` — or give it the worst case this architecture delivers: ${line}.`);
    if (!input.tags.has(qn, 'Estimate')) return fail(`\`${name}\` is not tagged. Write \`#Estimate attribute ${name}\` — the tag is how the trade-off and the audit find it.`);
    return [];
  });
};

/**
 * The coordination and C2 functions the brief names exist, tagged.
 *
 * At SA by name — they are what the system takes over, and the brief named
 * them. From LA down by count: a solution layer may redesign a function
 * (A1-R-07), but it may not lose one. A tagged function nothing flows into or
 * out of is reported, not blocked: some C2 decisions are internal.
 */
const taggedFunctions =
  (tag: 'Coordination' | 'C2', code: 'functions.coordination' | 'functions.c2', label: string): Predicate =>
  (input) => {
    const wanted = (tag === 'Coordination' ? input.brief?.coordinationFunctions : input.brief?.c2Functions) ?? [];
    const view = input.payloads.layerView as LayerView | undefined;
    if (wanted.length === 0 || !view || !input.layer) return [];
    // Tags on the usage or on its definition, exactly as replicaFacts counts
    // them: a gate and a score that read tags differently drift apart.
    const hasTag = (a: ActionView): boolean => a.keywords.includes(tag) || (a.defKeywords ?? []).includes(tag);
    const tagged = view.actions.filter(hasTag);
    const out: RepairItem[] = [];
    if (input.layer === 'SA') {
      for (const name of wanted) {
        const action = view.actions.find((a) => a.name === name);
        if (!action)
          out.push(item({ code, severity: 'error', blocking: input.blocking, message: `the brief names \`${name}\` as ${label}, and this layer has no function of that name. Add \`#${tag} action ${name} : <Def>;\` with its parameters, allocate it to \`system\`, and trace it to the operational activity it takes over.` }));
        else if (!hasTag(action))
          out.push(item({ code, severity: 'error', blocking: input.blocking, qualifiedName: action.qualifiedName, message: `\`${name}\` is ${label} and is not tagged: write \`#${tag} action ${name}\`. The tag is how every later layer, gate and score finds it.` }));
      }
    } else if (tagged.length < wanted.length) {
      out.push(item({ code, severity: 'error', blocking: input.blocking, message: `the brief names ${wanted.length} ${label} function(s) and this layer tags ${tagged.length} with \`#${tag}\`. A solution layer may rename or split them; it may not drop one. Named by the brief: ${wanted.join(', ')}.` }));
    }
    const flowing = new Set(view.flows.flatMap((fl) => [fl.from, fl.to]).map((e) => e?.split('::')[0]?.split('.')[0]));
    for (const action of tagged.filter((a) => !flowing.has(a.name))) {
      out.push(item({ code, severity: 'info', blocking: false, qualifiedName: action.qualifiedName, message: `\`${action.name}\` is ${label} and nothing flows into or out of it. What does it receive, and what does it decide for whom?` }));
    }
    return out;
  };

/**
 * The member definition the transition carried into SA is still there.
 *
 * SA is one black box, so the population is only a definition at this layer —
 * which makes it exactly the kind of line an author tidies away as unused. The
 * next transition carries it down from here, so losing it at SA loses the
 * fleet at every layer below.
 */
const saFleetCarried: Predicate = (input) => {
  const p = input.brief?.population;
  if (!p || input.layer !== 'SA') return [];
  const kept = elementsOf(input).some(
    (e) => e.metaclass === 'PartDefinition' && isDirect(e.qualifiedName, input.root, 'SA') && e.name === p.memberDef,
  );
  return kept
    ? []
    : [item({ code: 'sa.fleetCarried', severity: 'error', blocking: input.blocking, cv: 'CV-16', message: `the carried \`#Member part def ${p.memberDef}\` is gone. At SA it has no usage on purpose — the system is still one box — and it is what LA and PA instantiate as the fleet. Put it back with its \`meshOut\`/\`meshIn\` ports.` })];
};

/**
 * One functional chain per capability (A1-C-14).
 *
 * The brief's latency budgets — how fast a detection reaches the operations
 * centre, how fast coverage is restored — attach to chains, and three runs
 * declared the budgets with no chain for them to attach to. Reported until a
 * run shows authors write them unprompted.
 */
const saChains: Predicate = (input) => {
  const wanted = input.brief?.capabilities ?? [];
  if (wanted.length === 0 || input.layer !== 'SA') return [];
  const chains = elementsOf(input).filter(
    (e) => e.metaclass === 'OccurrenceDefinition' && isDirect(e.qualifiedName, input.root, 'SA') && input.tags.has(e.qualifiedName, 'Chain'),
  );
  const covered = (cap: string): boolean => chains.some((c) => c.name.includes(cap) || c.doc.includes(cap));
  const missing = wanted.filter((cap) => !covered(cap));
  return missing.length === 0
    ? []
    : [item({ code: 'sa.chains', severity: 'info', blocking: false, message: `no functional chain for ${missing.join(', ')}. A chain is \`#Chain occurrence def <Capability>Chain { doc /* the functions, in order */ }\` with \`succession\` lines between its functions; it is what a latency budget and an integration test attach to.` })];
};

/** Report-only until a run shows authors meet them unprompted. */
const fleetScenario: Predicate = (input) => {
  const p = input.brief?.population;
  if (!p || !input.layer) return [];
  const rows = elementsOf(input);
  const scenarios = rows.filter((e) => e.metaclass === 'OccurrenceDefinition' && isDirect(e.qualifiedName, input.root, input.layer!));
  const withTwo = scenarios.some(
    (s) => rows.filter((e) => e.qualifiedName.startsWith(`${s.qualifiedName}::`) && typesOf(e).includes(p.memberDef)).length >= 2,
  );
  return withTwo
    ? []
    : [item({ code: 'fleet.scenario', severity: 'info', blocking: false, cv: 'CV-08', message: `no exchange scenario between two members: an \`occurrence def\` with \`ref part a : ${p.memberDef}; ref part b : ${p.memberDef};\` and the messages of a sector handover is what shows the peer protocol (A1-C-15).` })];
};

const fleetConfiguration: Predicate = (input) => {
  if (!input.brief?.population || !input.layer) return [];
  const found = elementsOf(input).some(
    (e) => e.metaclass === 'StateDefinition' && inLayer(e.qualifiedName, input.root, input.layer!) && input.tags.has(e.qualifiedName, 'Configuration'),
  );
  return found
    ? []
    : [item({ code: 'fleet.configuration', severity: 'info', blocking: false, cv: 'CV-16', message: 'no fleet-level configuration: a `#Configuration state def` (full coverage, degraded, ground link lost, regrouping) says what the swarm is in as a whole, which no single member\'s mode does (A1-C-31).' })];
};

const paBearer: Predicate = (input) => {
  // The brief records the bearer as prose ("Mesh radio"); a name in a message
  // the model copies has to be an identifier (v6).
  const bearer = identifierOf(input.brief?.population?.bearer);
  if (!bearer || input.layer !== 'PA') return [];
  const rows = elementsOf(input).filter((e) => inLayer(e.qualifiedName, input.root, 'PA'));
  const asActor = rows.some((e) => e.metaclass === 'PartDefinition' && e.name.toLowerCase().includes(bearer.toLowerCase()) && input.tags.has(e.qualifiedName, 'Actor'));
  const medium = rows.some((e) => e.metaclass === 'ConnectionDefinition');
  const out: RepairItem[] = [];
  // Blocking since T-03 writes the bearer as a #Node: the author is asked to
  // keep what the transition wrote, and to type the links by their medium.
  const severity = input.blocking ? 'error' : 'info';
  if (asActor) out.push(item({ code: 'pa.bearer', severity, blocking: input.blocking, cv: 'CV-05', message: `\`${bearer}\` is an actor at PA. The radio that carries member-to-member traffic is built or bought: keep it a \`#Node part def ${bearer}\` with its own ports (A1-R-11), as the transition wrote it.` }));
  if (!medium) out.push(item({ code: 'pa.bearer', severity, blocking: input.blocking, cv: 'CV-05', message: `no connection def at PA. Type the link between members by the medium that carries it — \`connection def ${bearer}Link { end a : Common::<PeerPort>; end b : ~Common::<PeerPort>; }\` and \`connection peerLink : ${bearer}Link connect memberA.meshOut to memberB.meshIn;\` — so the model can say which link is the intermittent radio.` }));
  return out;
};

const allocateFunctionsAllocated: Predicate = (input) => {
  const allocate = trace(input, 'trace-allocate');
  if (!allocate || !input.layer) return [];
  const allocated = new Set(allocate.links.map((l) => l.fromName));
  // An allocation of the SAME name in another layer is almost always this
  // layer's function written by path: v6's PA alternative allocated
  // `Root::LA::handOverSector`, and all 13 of its functions read unallocated.
  // Only allocations INTO this layer's parts count: the prefix carries the layer
  // above's own allocations of the same names, and reading those made every
  // unallocated PA function look like a path mistake.
  const elsewhere = new Set(
    allocate.links
      .filter((l) => !inLayer(l.fromName, input.root, input.layer!) && inLayer(l.toName, input.root, input.layer!))
      .map((l) => simpleName(l.fromName).replace(/^[A-Z]/, (c) => c.toLowerCase())),
  );
  return elementsOf(input)
    .filter(
      (el) =>
        el.metaclass === 'ActionUsage' &&
        isDirect(el.qualifiedName, input.root, input.layer!) &&
        !isGuidance(el.qualifiedName, input.tags) &&
        !allocated.has(el.qualifiedName),
    )
    .map((el) =>
      item({
        code: 'allocate.functionsAllocated',
        severity: 'error',
        blocking: input.blocking,
        cv: 'CV-04',
        qualifiedName: el.qualifiedName,
        message: elsewhere.has(el.name)
          ? `\`${el.name}\` is a function nothing performs: an \`allocate\` names the \`${el.name}\` of another layer by its path, which allocates that one. Write \`allocate ${el.name} to <part>;\` with the bare name.`
          : `\`${el.name}\` is a function nothing performs. Add \`allocate ${el.name} to <part>;\` naming the component or actor that carries it.`,
      }),
    );
};

/** Every function in this layer realises one in the layer above. */
const traceRowsRealiseUp: Predicate = (input) => {
  const tr = trace(input);
  const layer = input.layer;
  if (!tr || !layer) return [];
  const above = previousAuthoredLayer(layer);
  if (!above) return [];
  const realised = new Set(
    tr.links.filter((l) => inLayer(l.fromName, input.root, above)).map((l) => l.toName),
  );
  const exempt = actorAllocatedFunctions(input);
  return elementsOf(input)
    .filter(
      (el) =>
        el.metaclass === 'ActionUsage' &&
        isDirect(el.qualifiedName, input.root, layer) &&
        !isGuidance(el.qualifiedName, input.tags) &&
        !exempt.has(el.qualifiedName) &&
        !realised.has(el.qualifiedName),
    )
    .map((el) =>
      item({
        code: 'trace.rowsRealiseUp',
        severity: 'error',
        blocking: input.blocking,
        cv: 'CV-03',
        qualifiedName: el.qualifiedName,
        message: `\`${el.name}\` realises nothing in ${above}. Add \`trace ${el.name} to ${input.root}::${above}::<function>;\` — a function that appears from nowhere is a function nobody asked for.`,
      }),
    );
};

/** Nothing the layer above asked for is left behind. */
const tracePreviousRealised: Predicate = (input) => {
  const tr = trace(input);
  const layer = input.layer;
  if (!tr || !layer) return [];
  const above = previousAuthoredLayer(layer);
  if (!above) return [];
  const realises = new Set(
    tr.links.filter((l) => inLayer(l.toName, input.root, layer)).map((l) => l.fromName),
  );
  const exempt = actorAllocatedFunctions(input);
  // Operational analysis describes the whole operation; the system takes over a
  // subset of it, so an OA activity with no system function is a fact about the
  // scope, not a gap. From SA down the layers decompose one system, and a
  // function that survives into the next layer is the whole point.
  const blocking = input.blocking && above !== 'OA';
  return elementsOf(input)
    .filter(
      (el) =>
        el.metaclass === 'ActionUsage' &&
        isDirect(el.qualifiedName, input.root, above) &&
        !isGuidance(el.qualifiedName, input.tags) &&
        !exempt.has(el.qualifiedName) &&
        !realises.has(el.qualifiedName),
    )
    .map((el) =>
      item({
        code: 'trace.previousRealised',
        severity: blocking ? 'error' : 'info',
        blocking,
        cv: 'CV-03',
        qualifiedName: el.qualifiedName,
        message: blocking
          ? `\`${el.name}\` (${above}) is not realised in ${layer}. Add the ${layer} function that carries it, with \`trace <fn> to ${el.qualifiedName};\`.`
          : `\`${el.name}\` (${above}) has no counterpart in ${layer} — recorded: the system does not take this activity over.`,
      }),
    );
};

/**
 * The chain, layer pair by layer pair — the audit table, not a gate.
 *
 * Completeness is demanded where it can be acted on: at the step that authors
 * the layer, by `trace.previousRealised`. Here it is published, so the packet
 * carries the whole chain in one place and a reader can see what the gates
 * decided rather than take their word for it.
 */
const traceClosure: Predicate = (input) => {
  const tr = trace(input);
  if (!tr) return [];
  const items: RepairItem[] = [];
  const exempt = actorAllocatedFunctions(input);
  const els = elementsOf(input);
  for (const [lower, upper] of [
    ['SA', 'OA'],
    ['LA', 'SA'],
    ['PA', 'LA'],
    ['EPBS', 'PA'],
  ] as Array<[Layer, Layer]>) {
    const hasLower = els.some((e) => inLayer(e.qualifiedName, input.root, lower));
    if (!hasLower) continue;
    const realised = new Set(
      tr.links.filter((l) => inLayer(l.toName, input.root, lower)).map((l) => l.fromName),
    );
    // PA → EPBS is the procurement question, and `paPartsWithoutItems` is the
    // one place that answers it; the other rows are about functions.
    const missing =
      lower === 'EPBS'
        ? paPartsWithoutItems(input, realised)
        : els.filter(
            (el) =>
              el.metaclass === 'ActionUsage' &&
              isDirect(el.qualifiedName, input.root, upper) &&
              !isGuidance(el.qualifiedName, input.tags) &&
              !exempt.has(el.qualifiedName) &&
              !realised.has(el.qualifiedName),
          );
    for (const el of missing) {
      items.push(
        item({
          code: 'trace.closure',
          severity: 'info',
          blocking: false,
          cv: 'CV-03',
          qualifiedName: el.qualifiedName,
          message: `${upper} → ${lower}: \`${el.name}\` is not realised.`,
        }),
      );
    }
  }
  return items;
};

const reachCodes: Predicate = (input) => {
  const reach = input.payloads.reach as ReachReport | undefined;
  if (!reach || !input.layer) return [];
  return (reach.diagnostics ?? [])
    .filter((d) => !d.elementName || inLayer(d.elementName, input.root, input.layer!))
    .map((d) => {
      const note = noteFor(d.code ?? '');
      // The knob decides these, not the layer: `classifyCode` owns that call.
      return item({
        code: d.code ?? 'verification/unknown',
        severity: (d.severity as RepairItem['severity']) ?? 'warning',
        blocking: false,
        cv: note?.cv,
        hint: note?.note ?? d.hint,
        qualifiedName: d.elementName,
        message: d.message,
      });
    });
};

const connectivityLayerPorts: Predicate = (input) => {
  const conn = input.payloads.connectivity as ConnectivityReport | undefined;
  if (!conn || !input.layer) return [];
  // Never blocking on its own: the reference model leaves five ports open by
  // design (a parameter is a port here, and an actor's edge is deliberately
  // free). What blocks is a dangling END, which is a `check` diagnostic.
  return conn.unconnectedPorts
    .filter((p) => inLayer(p.qualifiedName, input.root, input.layer!))
    .map((p) =>
      item({
        code: 'connectivity.layerPorts',
        severity: 'info',
        blocking: false,
        cv: 'CV-05',
        qualifiedName: p.qualifiedName,
        message: `port \`${p.declaredName ?? simpleName(p.qualifiedName)}\` is not connected to anything.`,
      }),
    );
};

const orphansLayerPartDefs: Predicate = (input) => {
  const orphans = input.payloads.orphans as OrphanReport | undefined;
  if (!orphans || !input.layer) return [];
  // The placeholder definition is the type of the system as a whole; the
  // alternatives strip its usage and may leave the definition unused. It is
  // the one definition a layer is allowed not to instantiate.
  const ph = PLACEHOLDER[input.layer];
  const placeholderDef = ph && input.brief ? ph.def(input.brief.systemName) : undefined;
  return orphans.orphans
    .filter(
      (o) =>
        o.eClass === 'PartDefinition' &&
        inLayer(o.qualifiedName, input.root, input.layer!) &&
        !isGuidance(o.qualifiedName, input.tags) &&
        (o.declaredName ?? simpleName(o.qualifiedName)) !== placeholderDef,
    )
    .map((o) =>
      item({
        code: 'orphans.layerPartDefs',
        severity: 'error',
        blocking: input.blocking,
        qualifiedName: o.qualifiedName,
        message: `\`${o.declaredName ?? simpleName(o.qualifiedName)}\` is a component definition nothing uses. Declare a part of it, or delete it.`,
      }),
    );
};

const orphansImposedUsed: Predicate = (input) => {
  if (!input.knobs.infrastructure_intake) return [];
  const orphans = input.payloads.orphans as OrphanReport | undefined;
  if (!orphans) return [];
  const imposed = new Set(input.tags.taggedWith('Imposed'));
  return orphans.orphans
    .filter((o) => imposed.has(o.qualifiedName))
    .map((o) =>
      item({
        code: 'orphans.imposedUsed',
        severity: 'error',
        blocking: input.blocking,
        qualifiedName: o.qualifiedName,
        message: `\`${o.declaredName ?? simpleName(o.qualifiedName)}\` is imposed infrastructure the architecture does not use. Every #Imposed element has to appear in the design, or the design is not the one the customer can build.`,
      }),
    );
};

const requirementsCoverage: Predicate = (input) => {
  const reqs = input.payloads.requirements as RequirementsPayload | undefined;
  if (!reqs) return [];
  // A hazard accepted with its reason is not a gap: the hazard gate exempts it,
  // and the final audit lists it under its own heading. Reported here as well,
  // v4's audit said "accepted" and "satisfied by nothing" about the same element.
  const byId = new Map(elementsOf(input).map((e) => [e.id, e.qualifiedName]));
  const accepted = new Set(input.tags.taggedWith('Accepted'));
  return reqs.rows
    .filter((r) => r.satisfied === false && !accepted.has(byId.get(r.id) ?? ''))
    .map((r) =>
      item({
        code: 'requirements.coverage',
        severity: input.blocking ? 'error' : 'info',
        blocking: input.blocking,
        cv: 'CV-09',
        qualifiedName: r.name,
        message: `requirement \`${r.name}\` is satisfied by nothing. Add \`satisfy ${r.name} by <part-or-function>;\` — a requirement def and its usage are counted separately, so satisfy the one that is uncovered.`,
      }),
    );
};

const requirementsHazards: Predicate = (input) => {
  if (!input.knobs.safety || !input.layer) return [];
  const hazards = input.tags.taggedWith('Hazard').filter((qn) => qn.startsWith(`${input.root}::`));
  const forLayer = hazards.filter((qn) => qn.includes(`::${input.layer}`) || qn.includes(`::Hazards::${input.layer}`));
  if (forLayer.length > 0) return [];
  return [
    item({
      code: 'requirements.hazards',
      severity: input.blocking ? 'error' : 'info',
      blocking: input.blocking,
      cv: 'CV-09',
      message: `no #Hazard requirement names ${input.layer}. The safety knob is on and every layer adds hazards of its own: state at least one this layer introduces as a #Hazard requirement usage naming the ${input.layer} element it is about${input.layer === 'EPBS' ? ' — a supplier that stops shipping, a version that drifts across the fleet, a part that becomes obsolete' : ''}.`,
    }),
  ];
};

/**
 * A hazard that is stated is a hazard something mitigates.
 *
 * Cumulative from SA down, by what the model did unprompted: the system
 * analysis satisfied its own eleven hazards and the operational analysis's
 * five (`satisfy OA::Hazards::hazFlyaway by selfRecoverToPoint`) — operational
 * hazards are what the system takes over, and a function is a legitimate
 * mitigator. Every later layer then left its hazards unsatisfied: 23 of the
 * 29 unsatisfied requirements in the first run. The prefix at a layer holds
 * every earlier `satisfy`, so this only ever bites on what the layer added.
 * A hazard tagged #Accepted, with its reason in its doc, is the honest way
 * out — without it a repair loop satisfies a hazard with whatever is nearest.
 */
const requirementsHazardsMitigated: Predicate = (input) => {
  if (!input.knobs.safety) return [];
  const reqs = (input.payloads['requirements-hazards'] ?? input.payloads.requirements) as RequirementsPayload | undefined;
  if (!reqs) return [];
  // Rows to tags by id: `hazFlyaway` exists in OA and in SA.
  const byId = new Map(elementsOf(input).map((e) => [e.id, e.qualifiedName]));
  const hazards = new Set(input.tags.taggedWith('Hazard'));
  const accepted = new Set(input.tags.taggedWith('Accepted'));
  return reqs.rows
    .filter((r) => r.satisfied === false)
    .map((r) => byId.get(r.id))
    .filter((qn): qn is string => qn !== undefined && hazards.has(qn) && !accepted.has(qn))
    .map((qn) =>
      item({
        code: 'requirements.hazardsMitigated',
        severity: input.blocking ? 'error' : 'info',
        blocking: input.blocking,
        cv: 'CV-09',
        qualifiedName: qn,
        message: `hazard \`${simpleName(qn)}\` is stated and nothing mitigates it. Add \`satisfy ${simpleName(qn)} by <the function or component that mitigates it>;\` in this layer — or tag the hazard \`#Accepted\` with the reason in its doc.`,
      }),
    );
};

/**
 * Whether the fault tree had anything to cut. It reads component contracts
 * that refine a top requirement, and no layer of this workflow writes those:
 * v6 and v7 both reported "0 cut sets" over 29 and 32 "contracts", a sentence
 * that reads like an all-clear and was not one.
 */
const faultTreeApplicable: Predicate = (input) => {
  const tree = input.payloads['fault-tree'] as { groups?: unknown[] } | undefined;
  if (!tree || (tree.groups ?? []).length > 0) return [];
  return [
    item({
      code: 'faultTree.applicable',
      severity: 'info',
      blocking: false,
      message: 'fault tree not applicable: no component contract refines a top requirement, so no cut set was computed and nothing is claimed about single points of failure.',
    }),
  ];
};

/* ─────────────────────  what the brief fixed by name  ───────────────────── */

type Owner = NonNullable<BriefFacts['modes']>[number]['of'];

/**
 * Whether the element that owns a state machine is the owner a brief mode or
 * rule names. At SA the system is one black box, and without a population
 * there are no members, so any part that is not an actor fits; from LA down a
 * member's machine is on the `#Member` definition (or a representative), the
 * fleet's on the fleet usage or a `#Configuration` machine, the ground's on
 * anything else the architecture owns.
 */
function ownerFits(input: PredicateInput, machineQn: string, of: Owner): boolean {
  // A machine is its owner's by definition inside it, or by a state usage in
  // it typed by the definition: v7's LA alternative declared `state def
  // MemberMode` in the package and `state mode : MemberMode` in the member,
  // which is the same machine and was read as the package's.
  const rows = elementsOf(input);
  const machineName = simpleName(machineQn);
  const layer = input.layer;
  const typedIn = rows
    .filter((e) => e.metaclass === 'StateUsage' && typesOf(e).includes(machineName) && (!layer || inLayer(e.qualifiedName, input.root, layer)))
    .map((e) => `${e.qualifiedName.split('::').slice(0, -1).join('::')}::${machineName}`);
  return [machineQn, ...typedIn].some((qn) => definedIn(input, qn, of));
}

function definedIn(input: PredicateInput, machineQn: string, of: Owner): boolean {
  const ownerQn = machineQn.split('::').slice(0, -1).join('::');
  const owner = elementsOf(input).find((e) => e.qualifiedName === ownerQn);
  if (!owner || actorUsages(input).has(ownerQn)) return false;
  const p = input.brief?.population;
  if (!p || input.layer === 'SA' || of === 'system') return true;
  const isMember =
    input.tags.has(ownerQn, 'Member') || typesOf(owner).includes(p.memberDef) || owner.name === p.memberDef || ['memberA', 'memberB'].includes(owner.name);
  const isFleet = owner.name === p.fleetPart || input.tags.has(machineQn, 'Configuration');
  if (of === 'member') return isMember;
  if (of === 'fleet') return isFleet;
  return !isMember && !isFleet;
}

const ownerWords = (of: Owner, input: PredicateInput): string => {
  const p = input.brief?.population;
  if (input.layer === 'SA' || !p || of === 'system') return 'the system';
  return of === 'member' ? `\`${p.memberDef}\`` : of === 'fleet' ? `\`${p.fleetPart}\` (or a \`#Configuration\` machine)` : 'a ground component';
};

/** Every hazard the brief names is stated at SA under that name (CV-19). */
const hazardsFromBrief: Predicate = (input) => {
  const wanted = input.brief?.hazards ?? [];
  if (wanted.length === 0 || input.layer !== 'SA') return [];
  const stated = new Set(input.tags.taggedWith('Hazard').filter((qn) => inLayer(qn, input.root, 'SA')).map(simpleName));
  return wanted
    .filter((name) => !stated.has(name))
    .map((name) =>
      item({
        code: 'hazards.fromBrief',
        severity: 'error',
        blocking: input.blocking,
        cv: 'CV-19',
        message: `the brief names the hazard \`${name}\` and SA does not state it. Write \`#Hazard requirement ${name} { subject … ; doc /* … */ }\` in \`package Hazards\` under exactly that name, and satisfy it with what mitigates it.`,
      }),
    );
};

/**
 * A lower layer refines a hazard stated above; it does not restate it.
 *
 * v6's LA and PA restated SA's hazards under the same names, so every
 * alternative wrote a `satisfy` per hazard per layer — the same hazard three
 * times, and a name a `satisfy` resolved to the nearest copy of.
 */
const hazardsNotRestated: Predicate = (input) => {
  const layer = input.layer;
  if (!layer || !['LA', 'PA'].includes(layer)) return [];
  const hazards = input.tags.taggedWith('Hazard');
  const above = new Map<string, string>();
  for (const qn of hazards)
    for (const l of ['SA', 'LA'] as Layer[])
      if (layerIndex(l) < layerIndex(layer) && inLayer(qn, input.root, l) && !above.has(simpleName(qn))) above.set(simpleName(qn), qn.slice(input.root.length + 2));
  return hazards
    .filter((qn) => inLayer(qn, input.root, layer) && above.has(simpleName(qn)))
    .map((qn) =>
      item({
        code: 'hazards.notRestated',
        severity: 'error',
        blocking: input.blocking,
        cv: 'CV-09',
        qualifiedName: qn,
        message: `\`${simpleName(qn)}\` is already stated as \`${above.get(simpleName(qn))}\`. Remove it here and satisfy that one by path — \`satisfy ${above.get(simpleName(qn))} by <${input.step.id === 'S31' ? 'the function that mitigates it' : 'part'}>;\` — never by its bare name, which named the copy you remove — and state at this layer only the hazards it adds, under new names.`,
      }),
    );
};

/** Every mode the brief names is a state of the owner it names. */
const modesFromBrief: Predicate = (input) => {
  const wanted = input.brief?.modes ?? [];
  const layer = input.layer;
  if (wanted.length === 0 || !layer || layer === 'OA') return [];
  const rows = elementsOf(input);
  const machines = new Set(rows.filter((e) => e.metaclass === 'StateDefinition' && inLayer(e.qualifiedName, input.root, layer)).map((e) => e.qualifiedName));
  return wanted.flatMap((mode) => {
    const states = rows.filter((e) => e.metaclass === 'StateUsage' && e.name === mode.name && machines.has(e.qualifiedName.split('::').slice(0, -1).join('::')));
    if (states.some((st) => ownerFits(input, st.qualifiedName.split('::').slice(0, -1).join('::'), mode.of))) return [];
    const where = states.length > 0 ? ` It is a state of ${states.map((st) => `\`${st.qualifiedName.split('::').slice(-3, -1).join('::')}\``).join(', ')}, which is not ${ownerWords(mode.of, input)}.` : '';
    return [
      item({
        code: 'modes.fromBrief',
        severity: 'error',
        blocking: input.blocking,
        cv: 'CV-19',
        message: `the brief names the mode \`${mode.name}\` of the ${mode.of}, and no state machine of ${ownerWords(mode.of, input)} at this layer has \`state ${mode.name};\`.${where} Add the state under exactly that name, with a transition into it and one out.`,
      }),
    ];
  });
};

const rulesOf = (input: PredicateInput): RuleRow[] | undefined => input.payloads.rules as RuleRow[] | undefined;

/**
 * Every rule the brief says the system never breaks is carried, as a checked
 * property, by the machine of the owner it names (CV-18) — and at SA is also a
 * `#Rule requirement` of that name.
 */
const rulesCarried: Predicate = (input) => {
  const wanted = input.brief?.rules ?? [];
  const layer = input.layer;
  const rows = rulesOf(input);
  if (wanted.length === 0 || !layer || rows === undefined) return [];
  const out: RepairItem[] = [];
  const fail = (message: string): void => {
    out.push(item({ code: 'rules.carried', severity: 'error', blocking: input.blocking, cv: 'CV-18', message }));
  };
  const requirements = new Set(input.tags.taggedWith('Rule').filter((qn) => inLayer(qn, input.root, 'SA')).map(simpleName));
  for (const rule of wanted) {
    if (layer === 'SA' && !requirements.has(rule.name))
      fail(`the brief's rule \`${rule.name}\` is not stated. Write \`#Rule requirement ${rule.name} { subject … ; doc /* the rule in words */ }\` at SA, satisfied by the part whose state machine carries it.`);
    const spec = RULE_PATTERN[rule.kind];
    const unreadable = rows.filter((r) => r.rule === rule.name && isUnreadable(r));
    const named = rows.filter((r) => r.rule === rule.name && !isUnreadable(r));
    const right = named.filter((r) => r.fields.pattern === spec.pattern && r.fields.scope === spec.scope);
    const template = ruleTemplate(rule.name, rule.kind);
    if (named.length === 0 && unreadable.length > 0) {
      fail(`the carrier of \`${rule.name}\` on \`${unreadable[0].machine.slice(input.root.length + 2)}\` could not be read: ${(unreadable[0].detail ?? '').slice(0, 400)} Fill every field with a state that machine declares, and give the carrier no attribute but pattern, scope, p, q, r, s.`);
    } else if (named.length === 0) {
      fail(`no state machine at this layer carries the rule \`${rule.name}\` (${rule.kind}: ${ruleReading(rule.kind)}). Inside a state def of ${ownerWords(rule.of, input)}, write \`${template}\` with the states of that machine — the doc must start with \`${rule.name}:\`, which is how the rule is found.`);
    } else if (right.length === 0) {
      fail(`\`${rule.name}\` is carried as \`pattern=${named[0].fields.pattern}, scope=${named[0].fields.scope}\`, and a ${rule.kind} rule is \`pattern=${spec.pattern}, scope=${spec.scope}\`: \`${template}\`.`);
    } else if (!right.some((r) => ownerFits(input, r.machine, rule.of))) {
      fail(`\`${rule.name}\` is carried by \`${right[0].machine.slice(input.root.length + 2)}\`, and it is a rule of ${ownerWords(rule.of, input)}: carry it on that machine.`);
    }
  }
  return out;
};

/**
 * The carried rules hold. A `fail` comes with a run that breaks the rule and
 * blocks; a rule the walk could not decide is a note, never a pass (D2).
 */
const rulesHold: Predicate = (input) => {
  const wanted = new Set((input.brief?.rules ?? []).map((r) => r.name));
  const rows = rulesOf(input);
  if (wanted.size === 0 || rows === undefined) return [];
  return rows
    .filter((r) => r.rule !== undefined && wanted.has(r.rule) && r.claim !== 'pass' && !isUnreadable(r))
    .map((r) => {
      const failed = r.claim === 'fail';
      return item({
        code: 'rules.hold',
        severity: failed ? 'error' : 'info',
        blocking: failed && input.blocking,
        cv: 'CV-18',
        qualifiedName: r.machine,
        message: failed
          ? `the rule \`${r.rule}\` is broken by \`${r.machine.slice(input.root.length + 2)}\`: ${(r.detail ?? '').slice(0, 700)} Change the transitions so no run does this — not the property.`
          : `the rule \`${r.rule}\` could not be decided on \`${r.machine.slice(input.root.length + 2)}\` (${r.claim}): ${(r.detail ?? '').slice(0, 300)}`,
      });
    });
};

/** Every item whose fields the brief lists is an item def in Common with those attributes. */
const commonItemFields: Predicate = (input) => {
  const wanted = input.brief?.items ?? [];
  if (wanted.length === 0) return [];
  const names = new Set(elementsOf(input).map((e) => e.qualifiedName));
  const base = `${input.root}::Common::`;
  return wanted.flatMap((it) => {
    if (!names.has(`${base}${it.name}`))
      return [item({ code: 'common.itemFields', severity: 'error', blocking: input.blocking, cv: 'CV-19', message: `the brief lists what \`${it.name}\` carries and Common has no \`item def ${it.name}\`. Declare it with the attributes ${it.fields.map((f) => `\`${f}\``).join(', ')}, each with a doc.` })];
    const missing = it.fields.filter((f) => !names.has(`${base}${it.name}::${f}`));
    return missing.length === 0
      ? []
      : [item({ code: 'common.itemFields', severity: 'error', blocking: input.blocking, cv: 'CV-19', qualifiedName: `${base}${it.name}`, message: `\`item def ${it.name}\` lacks ${missing.map((f) => `\`${f}\``).join(', ')}, which the brief says it carries. Add each as \`attribute <name> : <type> { doc /* … */ }\`.` })];
  });
};

/**
 * An architecture mitigates the system's hazards with its own components.
 *
 * At the alternatives steps a hazard satisfied only by a function is mitigated
 * the same way in every alternative — the function layer is fixed and shared —
 * so safety could not tell two architectures apart (NEXT, open question 3).
 * Hazards stated at SA and below are the system's; OA's are about the
 * operation, and no component of the system mitigates them.
 *
 * `satisfiedBy` carries local names (checked on v5's S41 payload), so a name
 * counts when it is a non-actor part of this layer at any depth — a nested
 * `node.flightSafetyController` reports as `flightSafetyController`.
 */
const requirementsHazardsByComponent: Predicate = (input) => {
  if (!input.knobs.safety || !input.layer || input.alternative === undefined) return [];
  const reqs = (input.payloads['requirements-hazards'] ?? input.payloads.requirements) as RequirementsPayload | undefined;
  if (!reqs) return [];
  const rows = elementsOf(input);
  const byId = new Map(rows.map((e) => [e.id, e.qualifiedName]));
  const hazards = new Set(input.tags.taggedWith('Hazard'));
  const accepted = new Set(input.tags.taggedWith('Accepted'));
  const actorDefs = new Set(rows.filter((e) => e.metaclass === 'PartDefinition' && input.tags.has(e.qualifiedName, 'Actor')).map((e) => e.name));
  const components = new Set(
    rows
      .filter((e) => e.metaclass === 'PartUsage' && inLayer(e.qualifiedName, input.root, input.layer!) && !actorDefs.has(simpleName(e.type)) && !isGuidance(e.qualifiedName, input.tags))
      .map((e) => e.name),
  );
  const systemLayers = new Set(['SA', 'LA', 'PA']);
  const seen = new Set<string>();
  const out: RepairItem[] = [];
  for (const r of reqs.rows) {
    const qn = byId.get(r.id);
    if (!qn || seen.has(qn) || !hazards.has(qn) || accepted.has(qn)) continue;
    seen.add(qn);
    if (!systemLayers.has(qn.split('::')[1] ?? '')) continue;
    if ((r.satisfiedBy ?? []).some((name) => components.has(name.split(/::|\./).pop() ?? name))) continue;
    out.push(
      item({
        code: 'requirements.hazardsByComponent',
        severity: input.blocking ? 'error' : 'info',
        blocking: input.blocking,
        cv: 'CV-09',
        qualifiedName: qn,
        message: `hazard \`${simpleName(qn)}\` is mitigated by no component of this architecture${(r.satisfiedBy ?? []).length > 0 ? ` (only by ${r.satisfiedBy.map((n) => `\`${n}\``).join(', ')}, which every alternative shares)` : ''}. Add \`satisfy ${qn.split('::').slice(1).join('::')} by <one of your parts>;\` (that path: the same name at another layer is another hazard) naming the component that carries the mitigation — or tag the hazard \`#Accepted\` with the reason in its doc.`,
      }),
    );
  }
  return out;
};

/**
 * The PA parts that owe a configuration item, and are without one.
 *
 * One function, because two predicates ask it: `epbs.paPartsRealised` blocks
 * S50 on it, and `trace.closure` reports the same closure at S70. They
 * disagreed in v7 — the blocking one exempts actors and the reporting one did
 * not, so the final audit listed seven actors as "not realised" on a run S50
 * had passed. Two answers to one question is a defect whichever is right.
 *
 * An actor carried down to PA is the environment, not something procured or
 * built (eleven of the fourteen findings that once blocked the item layer were
 * actors). A population is procured once, by the item that carries its
 * multiplicity: the two representatives stand for any two of the fleet, not for
 * two more drones.
 */
function paPartsWithoutItems(input: PredicateInput, realised: ReadonlySet<string>): ElementRow[] {
  const actors = actorUsages(input);
  const p = input.brief?.population;
  const representativesCovered = (el: ElementRow): boolean => {
    if (!p || !typesOf(el).includes(p.memberDef)) return false;
    return elementsOf(input).some(
      (other) =>
        other.metaclass === 'PartUsage' &&
        isDirect(other.qualifiedName, input.root, 'PA') &&
        typesOf(other).includes(p.memberDef) &&
        /^([2-9]|\d{2,})/.test(other.multiplicity) &&
        realised.has(other.qualifiedName),
    );
  };
  return elementsOf(input).filter(
    (el) =>
      el.metaclass === 'PartUsage' &&
      isDirect(el.qualifiedName, input.root, 'PA') &&
      !isGuidance(el.qualifiedName, input.tags) &&
      !actors.has(el.qualifiedName) &&
      !realised.has(el.qualifiedName) &&
      !representativesCovered(el),
  );
}

const epbsPaPartsRealised: Predicate = (input) => {
  const tr = trace(input);
  if (!tr) return [];
  const realised = new Set(
    tr.links.filter((l) => inLayer(l.toName, input.root, 'EPBS')).map((l) => l.fromName),
  );
  return paPartsWithoutItems(input, realised)
    .map((el) =>
      item({
        code: 'epbs.paPartsRealised',
        severity: 'error',
        blocking: input.blocking,
        cv: 'CV-14',
        qualifiedName: el.qualifiedName,
        message: `\`${el.name}\` (PA) is realised by no configuration item. Add a #CI_* part in EPBS with \`trace <ci> to ${el.qualifiedName};\`.`,
      }),
    );
};

const skeletonParses: Predicate = (input) => {
  const report = input.payloads.check as CheckReport | undefined;
  if (!report) return [];
  // A skeleton is allowed to be incomplete — that is what the author step is
  // for — but it has to be a model, or the author is editing text nobody parsed.
  return report.summary.errors > 0
    ? [
        item({
          code: 'skeleton.parses',
          severity: 'error',
          blocking: true,
          message: `the generated skeleton does not load: ${report.summary.errors} error(s). The transition rule produced text this dialect does not accept.`,
        }),
      ]
    : [];
};

const seedBriefShape: Predicate = (input) => {
  const brief = input.brief;
  const items: RepairItem[] = [];
  if (!brief) return items;
  if (brief.moes.length === 0) {
    items.push(
      item({
        code: 'seed.briefShape',
        severity: 'error',
        blocking: input.blocking,
        message:
          'no measure of effectiveness. The architecture alternatives are scored against these (B-05): declare at least one #MoE attribute with a require constraint on the system.',
      }),
    );
  }
  const declared = new Set(elementsOf(input).map((e) => e.name));
  for (const moe of brief.moes) {
    if (!declared.has(moe)) {
      items.push(
        item({
          code: 'seed.briefShape',
          severity: 'error',
          blocking: input.blocking,
          message: `the brief names the measure \`${moe}\` but the model declares no attribute of that name.`,
        }),
      );
    }
  }
  items.push(...populationShape(input));
  return items;
};

/**
 * A population the brief declares is one every later layer can build on.
 *
 * Every name here is quoted verbatim into the authoring prompts and the gates
 * from LA down, so a port or interface Common does not declare, or a function
 * named by a keyword, would fail a layer that did nothing wrong.
 */
function populationShape(input: PredicateInput): RepairItem[] {
  const brief = input.brief;
  const p = brief?.population;
  if (!brief || !p) return [];
  const fail = (message: string): RepairItem =>
    item({ code: 'seed.briefShape', severity: 'error', blocking: input.blocking, message });
  const rows = elementsOf(input);
  const has = (metaclass: string, name: string): boolean => rows.some((e) => e.metaclass === metaclass && e.name === name);
  // SEED's repair rewrites package Common and nothing else, so only the two
  // Common declarations can block; the rest would stop a run no repair can
  // fix, and is reported for a person to correct in brief.json before resuming.
  const note = (message: string): RepairItem =>
    item({ code: 'seed.briefShape', severity: 'warning', blocking: false, message });
  const out: RepairItem[] = [];
  if (!has('PortDefinition', p.meshPort)) out.push(fail(`the population names the peer port \`${p.meshPort}\`, and package Common declares no \`port def ${p.meshPort}\`.`));
  if (!has('InterfaceDefinition', p.meshInterface))
    out.push(fail(`the population names the peer interface \`${p.meshInterface}\`, and package Common declares no \`interface def ${p.meshInterface}\` (two ends typed by \`${p.meshPort}\` and its conjugate).`));
  if (!brief.capabilities.includes(p.coordinationCapability))
    out.push(note(`the population's coordination capability \`${p.coordinationCapability}\` is not one of the capabilities: ${brief.capabilities.join(', ')}.`));
  const coordination = brief.coordinationFunctions ?? [];
  const c2 = brief.c2Functions ?? [];
  if (coordination.length === 0) out.push(note('a population with no coordination functions: name what the members settle between themselves.'));
  if (c2.length === 0) out.push(note('a population with no command-and-control functions: name what the operator exercises over the whole system.'));
  for (const name of [...coordination, ...c2]) {
    if (isReservedName(name)) out.push(note(`\`${name}\` is a keyword of the language and cannot name a function; choose another verb phrase.`));
  }
  return out;
}

const intakeRequirementShape: Predicate = (input) => {
  const reqs = input.payloads.requirements as RequirementsPayload | undefined;
  if (!reqs) return [];
  return reqs.rows
    .filter((r) => r.kind === 'requirement' && r.text.trim() === '')
    .map((r) =>
      item({
        code: 'intake.requirementShape',
        severity: 'error',
        blocking: input.blocking,
        cv: 'CV-09',
        qualifiedName: r.name,
        message: `\`${r.name}\` carries no text. Every intake item keeps the customer's own words in \`doc /* … */\`.`,
      }),
    );
};

const intakeImposedShape: Predicate = (input) => {
  const imposed = input.tags.taggedWith('Imposed');
  if (imposed.length > 0) return [];
  return [
    item({
      code: 'intake.imposedShape',
      severity: 'error',
      blocking: input.blocking,
      cv: 'CV-02',
      message:
        'the infrastructure lane is on but nothing is tagged #Imposed. Every existing component, interface and standard the customer imposes is declared here and tagged, or the later layers cannot be held to it.',
    }),
  ];
};

/**
 * A reviewer can read what each element is for.
 *
 * Measured on the first live run: the prompt asked for a doc on every element
 * and nothing checked it, so coverage fell from 38 % at OA to 24 % at LA —
 * decaying exactly where a reader needs prose most. What counts is the layer's
 * own direct elements; a tag definition, a parameter and a bookkeeping
 * element are not things a reviewer needs explained.
 */
const DOC_EXEMPT = new Set(['MetadataDefinition', 'Package', 'PortUsage', 'ReferenceUsage', 'AttributeUsage']);

/**
 * A usage typed by a documented definition is explained: `part opsCentre :
 * OperationsCentre` says what it is when OperationsCentre does. Counting it as
 * undocumented would demand the same sentence twice — and, measured on the
 * live run, the transition skeleton writes the doc on the definition, so the
 * gate was failing the workflow's own carry-over.
 */
export function isDocumented(el: ElementRow, all: ElementRow[]): boolean {
  if ((el.doc ?? '').trim() !== '') return true;
  const type = (el.type ?? '').split('::').pop();
  if (!type) return false;
  return all.some((d) => d.name === type && d.metaclass.endsWith('Definition') && (d.doc ?? '').trim() !== '');
}

const docsCoverage: Predicate = (input) => {
  const min = input.docCoverageMin ?? 0;
  if (min <= 0 || !input.layer) return [];
  const own = elementsOf(input).filter(
    (e) =>
      isDirect(e.qualifiedName, input.root, input.layer!) &&
      !DOC_EXEMPT.has(e.metaclass) &&
      !isGuidance(e.qualifiedName, input.tags),
  );
  if (own.length === 0) return [];
  const all = elementsOf(input);
  const missing = own.filter((e) => !isDocumented(e, all));
  const coverage = 1 - missing.length / own.length;
  if (coverage >= min) return [];
  const blocking = input.blocking;
  return [
    item({
      code: 'docs.coverage',
      severity: blocking ? 'error' : 'info',
      blocking,
      message: `${Math.round(coverage * 100)} % of this layer's elements carry a doc; the gate is ${Math.round(min * 100)} %. A reviewer cannot tell what an undocumented element is for. Missing: ${missing
        .slice(0, 25)
        .map((e) => e.name)
        .join(', ')}${missing.length > 25 ? `, and ${missing.length - 25} more` : ''}.`,
    }),
  ];
};

/**
 * A function layer is functions.
 *
 * Measured on the live run: told that the decomposition was the next step's
 * job and to leave every function on the placeholder, the author removed the
 * placeholder, invented two components and allocated everything to them — so
 * the alternatives would have compared architectures built on a decision
 * already taken, and "every function allocated" would have been met before
 * any alternative was written. What this layer may hold is the placeholder
 * and the actors it was handed; a part of its own is the decision it is not
 * allowed to make yet.
 */
const layerFunctionsOnly: Predicate = (input) => {
  const layer = input.layer;
  const ph = layer ? PLACEHOLDER[layer] : undefined;
  if (!layer || !ph || !input.brief) return [];
  const defName = ph.def(input.brief.systemName);
  const actors = actorUsages(input);
  const actorDefs = new Set(input.tags.taggedWith('Actor').map(simpleName));
  const stray = elementsOf(input).filter((e) => {
    if (!isDirect(e.qualifiedName, input.root, layer) || isGuidance(e.qualifiedName, input.tags)) return false;
    if (e.metaclass === 'PartUsage') return e.name !== ph.usage && !actors.has(e.qualifiedName);
    // The carried member definition is the population's, not a component the
    // function step invented: the alternatives instantiate it.
    if (e.metaclass === 'PartDefinition') return e.name !== defName && !actorDefs.has(e.name) && !input.tags.has(e.qualifiedName, 'Member');
    return false;
  });
  const placeholderGone = !elementsOf(input).some(
    (e) => e.metaclass === 'PartUsage' && e.name === ph.usage && isDirect(e.qualifiedName, input.root, layer),
  );
  const items: RepairItem[] = stray.map((e) =>
    item({
      code: 'layer.functionsOnly',
      severity: 'error',
      blocking: input.blocking,
      qualifiedName: e.qualifiedName,
      message: `\`${e.name}\` is a component. This step writes the functions only; the split into components is decided in the next step, several ways, and compared. Remove it and allocate its functions to \`${ph.usage}\`.`,
    }),
  );
  if (placeholderGone) {
    items.push(
      item({
        code: 'layer.functionsOnly',
        severity: 'error',
        blocking: input.blocking,
        message: `the placeholder \`part ${ph.usage} : ${defName}\` is gone. Keep it, and allocate every function of this layer to it — the next step replaces it with real components.`,
      }),
    );
  }
  return items;
};

const finalTodos: Predicate = (input) =>
  elementsOf(input)
    .filter((el) => /\bTODO\b/.test(el.doc ?? ''))
    .map((el) =>
      item({
        code: 'final.todos',
        severity: 'info',
        blocking: false,
        qualifiedName: el.qualifiedName,
        message: `\`${el.name}\` still carries a TODO from the transition skeleton.`,
      }),
    );

export const PREDICATES: Record<PredicateId, Predicate> = {
  'seed.briefShape': seedBriefShape,
  'intake.requirementShape': intakeRequirementShape,
  'intake.imposedShape': intakeImposedShape,
  'oa.noSystemName': oaNoSystemName,
  'oa.capabilities': oaCapabilities,
  'oa.systemEntity': oaSystemEntity,
  'oa.members': oaMembers,
  'oa.namedFunctions': oaNamedFunctions,
  'replicas.memberPair': replicasMemberPair,
  'replicas.topology': replicasTopology,
  'moe.estimated': moeEstimated,
  'moe.dutyCycleBound': moeDutyCycleBound,
  'moe.transitBudget': moeTransitBudget,
  'requirements.hazardsByComponent': requirementsHazardsByComponent,
  'hazards.fromBrief': hazardsFromBrief,
  'hazards.notRestated': hazardsNotRestated,
  'modes.fromBrief': modesFromBrief,
  'rules.carried': rulesCarried,
  'rules.hold': rulesHold,
  'common.itemFields': commonItemFields,
  'faultTree.applicable': faultTreeApplicable,
  'alt.c2Placement': altC2Placement,
  'functions.coordination': taggedFunctions('Coordination', 'functions.coordination', 'coordination between members'),
  'functions.c2': taggedFunctions('C2', 'functions.c2', 'command and control'),
  'fleet.scenario': fleetScenario,
  'fleet.configuration': fleetConfiguration,
  'pa.bearer': paBearer,
  'sa.fleetCarried': saFleetCarried,
  'sa.chains': saChains,
  'allocate.functionsAllocated': allocateFunctionsAllocated,
  'trace.rowsRealiseUp': traceRowsRealiseUp,
  'trace.previousRealised': tracePreviousRealised,
  'trace.closure': traceClosure,
  'reach.codes': reachCodes,
  'connectivity.layerPorts': connectivityLayerPorts,
  'orphans.layerPartDefs': orphansLayerPartDefs,
  'orphans.imposedUsed': orphansImposedUsed,
  'requirements.coverage': requirementsCoverage,
  'requirements.hazards': requirementsHazards,
  'requirements.hazardsMitigated': requirementsHazardsMitigated,
  'epbs.paPartsRealised': epbsPaPartsRealised,
  'skeleton.parses': skeletonParses,
  'final.todos': finalTodos,
  'docs.coverage': docsCoverage,
  'layer.functionsOnly': layerFunctionsOnly,
};

