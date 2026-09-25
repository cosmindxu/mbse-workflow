/**
 * Layer n+1, generated from layer n.
 *
 * This is where "maximise automation" actually lands. The method's transitions are
 * mechanical — an activity becomes a function, an interaction becomes a flow,
 * an entity becomes an actor, and every one of them carries a realization link
 * back — so they are written by a script and not by a model. What the LLM step
 * that follows does is enrich: name what the skeleton could not name, split
 * what should be split, add what the next layer introduces.
 *
 * Everything generated carries `doc /* TODO … *​/` so the authoring step, the
 * final audit and a human reader can all see what has not been thought about
 * yet. Nothing here invents an element: if it is in the skeleton, it came from
 * the layer above.
 */
import { identifierOf } from '../spec/names.ts';
import { AUTHORED_LAYERS, type Layer } from '../spec/layers.ts';
import { isBookkeeping, type ActionView, type LayerView, type ParamView, type PartView } from './view.ts';

export type TransitionRule = 'T01' | 'T02' | 'T03' | 'T04';

export interface TransitionInput {
  rule: TransitionRule;
  /** The layer that has just been checked. */
  from: LayerView;
  root: string;
  /** The OA entity the system takes over (T-01 only). */
  systemEntity?: string;
  /** The member definition, when the system is a population (T-01 only). */
  memberDef?: string;
  /** The population, when the brief declares one: carried as a definition and a fact. */
  population?: { memberDef: string; fleetPart: string; size: number; meshPort: string; meshInterface: string; bearer?: string };
  /** The system's name, used for the definitions this rule creates. */
  systemName: string;
  /**
   * The coordination and command-and-control functions the brief names (T-01).
   * Two members' halves of one activity become one system function, named after
   * the brief function whose definition it shares.
   */
  namedFunctions?: string[];
}

export interface Skeleton {
  layer: Layer;
  text: string;
  /** What was carried over, for the packet and the authoring prompt. */
  carried: { functions: number; flows: number; actors: number; parts: number; capabilities: number; members?: number; peerFlows?: number };
}

const TARGET: Record<TransitionRule, Layer> = { T01: 'SA', T02: 'LA', T03: 'PA', T04: 'EPBS' };

/**
 * The one part a generated layer allocates every function to until an
 * architecture decides otherwise. The alternatives step strips it and its
 * allocations from the head it hands the model, so "allocate every function"
 * is a demand the section has to meet, not one the placeholder already met.
 */
export const PLACEHOLDER: Partial<Record<Layer, { usage: string; def: (system: string) => string }>> = {
  LA: { usage: 'mainComponent', def: (system) => `${system}Logical` },
  PA: { usage: 'mainAssembly', def: (system) => `${system}Physical` },
};

const GUIDANCE: Record<Layer, string> = {
  Kinds: '',
  Common: '',
  Needs: '',
  Imposed: '',
  OA: '',
  SA: 'SA: the system is one black-box part with ports. Every function is allocated to the system or to an actor, and traces to at least one operational activity. No design choices here.',
  LA: 'LA: decompose the system into logical components. Every logical function traces to a system function; components exchange through ports; nothing physical is decided yet.',
  PA: 'PA: the components that will be built. Behaviour parts are hosted in node parts by nesting, physical links are typed, item definitions carry units, and resource budgets are require constraints.',
  EPBS: 'EPBS: one configuration item per thing that is procured, built or delivered. Each realises a physical part and carries its contract.',
};

/** Generate the next layer from the one above it. */
export function generateSkeleton(input: TransitionInput): Skeleton {
  const layer = TARGET[input.rule];
  const w = new Writer();
  w.line(`package ${layer} {`);
  w.push();
  w.line(`#prompt part ${layer.toLowerCase()}Guidance {`);
  w.push();
  w.line(`doc /* ${GUIDANCE[layer]} */`);
  w.pop();
  w.line('}');
  w.blank();

  const carried =
    input.rule === 'T01'
      ? oaToSa(w, input)
      : input.rule === 'T04'
        ? paToEpbs(w, input)
        : copyDown(w, input, layer);

  w.pop();
  w.line('}');
  return { layer, text: w.text(), carried };
}

/* ─────────────────────────── T-01: OA → SA ──────────────────────────────── */

function oaToSa(w: Writer, input: TransitionInput): Skeleton['carried'] {
  const { from } = input;
  const above = 'OA';
  const systemDef = `${input.systemName}System`;
  const resolved = resolveSystemEntity(from, input.systemEntity, input.memberDef);
  const systemEntity = resolved.name;
  // Every part typed like the entity is the system too: a population is two or
  // more representatives of one definition, and all of them are taken over. At
  // OA that definition is the operation's own (`WatchAsset`), not the member
  // definition the solution layers will use, so both count.
  const entityDefs = new Set(
    [from.parts.find((p) => p.name === systemEntity)?.defName, input.memberDef].filter((d): d is string => !!d),
  );
  const isEntity = (name: string | undefined): boolean => {
    if (name === undefined) return false;
    if (name === systemEntity) return true;
    const part = from.parts.find((p) => p.name === name);
    return part?.defName !== undefined && entityDefs.has(part.defName);
  };

  // The system, and the entities it does not take over.
  w.comment('the system, black box');
  w.line(`part def ${systemDef} {`);
  w.push();
  w.line(`doc /* TODO: the system's attributes and its ports on the environment. */`);
  w.pop();
  w.line('}');
  w.line(`part system : ${systemDef};`);
  if (resolved.substituted) w.comment(`system entity: ${systemEntity} (the brief said ${input.systemEntity})`);
  if (systemEntity) w.line(`trace system to ${input.root}::${above}::${systemEntity};`);
  w.blank();
  const members = writePopulation(w, input, 'SA');

  const actors = from.parts.filter((p) => !isEntity(p.name) && !isBookkeeping(p.keywords));
  if (actors.length > 0) {
    w.comment('actors: every operational entity the system is not');
    for (const actor of actors) {
      const def = actorDefName(actor);
      w.line(`#Actor part def ${def} {`);
      w.push();
      w.line(`doc /* TODO: the ports this actor exchanges through. */`);
      w.pop();
      w.line('}');
      w.line(`part ${actor.name} : ${def};`);
      w.line(`trace ${actor.name} to ${actor.qualifiedName};`);
    }
    w.blank();
  }

  // Capabilities: the operational ones, now with the system as their subject.
  const capabilities = from.useCases.filter((uc) => !isBookkeeping(uc.keywords));
  if (capabilities.length > 0) {
    w.comment('capabilities, carried over with the system as subject');
    for (const uc of capabilities) {
      const keyword = uc.keywords.includes('Mission') ? '#Capability' : `#${uc.keywords[0] ?? 'Capability'}`;
      w.line(`${keyword} use case def ${uc.name} { subject s : ${systemDef}; }`);
      w.line(`trace ${uc.name} to ${uc.qualifiedName};`);
    }
    w.blank();
  }

  // Functions: one per operational activity, allocated where the activity was —
  // except that two representatives performing the same activity are one
  // system function. The system is one box at SA; `alphaHandOverSector` and
  // `bravoHandOverSector` were one function taken over twice, and v4 counted
  // them, plus the brief's `handOverSector`, as three.
  const allocationOf = new Map(from.allocations.map((a) => [a.actionName, a.partName]));
  const operational = from.actions.filter((a) => !isBookkeeping(a.keywords));
  const merged = input.population
    ? collapseMembers(operational, (a) => {
        const part = allocationOf.get(a.name);
        return part !== undefined && isEntity(part) ? part : undefined;
      }, input.namedFunctions ?? [])
    : { functions: operational, rename: new Map<string, string>(), halves: new Map<string, ActionView[]>() };
  const functions = merged.functions;
  if (functions.length > 0) {
    w.comment('functions: one per operational activity, to be split or merged by the author');
    writeActionDefs(w, functions, (names) => `TODO: what the system does for ${names}.`);
    for (const action of functions) {
      const halves = merged.halves.get(action.name);
      if (halves) w.comment(`one function for ${halves.map((h) => `\`${h.name}\``).join(', ')}: members performing one activity`);
      writeActionUsage(w, action);
      const entity = halves ? undefined : allocationOf.get(action.name);
      const target = entity === undefined || isEntity(entity) ? 'system' : entity;
      w.line(`allocate ${action.name} to ${target};`);
      for (const h of halves ?? [action]) w.line(`trace ${action.name} to ${h.qualifiedName};`);
    }
    w.blank();
  }

  const { count: flows, peer: peerFlows } = writeFlows(w, from, merged.rename);
  writeSuccessions(w, from, merged.rename);

  return {
    functions: functions.length,
    flows,
    actors: actors.length,
    parts: 1,
    capabilities: capabilities.length,
    members,
    ...(input.population ? { peerFlows } : {}),
  };
}

/**
 * The OA part the brief means by `systemEntity`.
 *
 * SEED names the entity before OA exists, and the OA author names it again.
 * Measured: the brief said `surveillanceAsset`, OA declared `watchAsset`, the
 * exact match never held, and the skeleton wrote ten `allocate … to
 * watchAsset;` into a layer where no `watchAsset` exists. Exact name first,
 * then the name or its definition case-insensitively (the member definition
 * too), then the non-actor part that carries the most activities — which is
 * what "the entity whose activities become system functions" means.
 */
export function resolveSystemEntity(
  from: LayerView,
  systemEntity: string | undefined,
  memberDef?: string,
): { name?: string; defName?: string; substituted: boolean } {
  const parts = from.parts.filter((p) => !isBookkeeping(p.keywords));
  const exact = parts.find((p) => p.name === systemEntity);
  if (exact) return { name: exact.name, defName: memberDef ?? exact.defName, substituted: false };
  const wanted = [systemEntity, memberDef].filter((n): n is string => !!n).map((n) => n.toLowerCase());
  const loose = parts.find(
    (p) => wanted.includes(p.name.toLowerCase()) || (p.defName !== undefined && wanted.includes(p.defName.toLowerCase())),
  );
  if (loose) return { name: loose.name, defName: memberDef ?? loose.defName, substituted: systemEntity !== undefined };
  const load = new Map<string, number>();
  for (const a of from.allocations) load.set(a.partName, (load.get(a.partName) ?? 0) + 1);
  // Actors included: the third run's OA tagged the entity it meant `#Actor`.
  const busiest = [...parts].sort(
    (a, b) => (load.get(b.name) ?? 0) - (load.get(a.name) ?? 0) || Number(a.isActor) - Number(b.isActor),
  )[0];
  if (busiest && (load.get(busiest.name) ?? 0) > 0)
    return { name: busiest.name, defName: memberDef ?? busiest.defName, substituted: systemEntity !== undefined };
  return { name: systemEntity, substituted: false };
}

/* ───────────────────── T-02 / T-03: SA → LA → PA ────────────────────────── */

function copyDown(w: Writer, input: TransitionInput, layer: Layer): Skeleton['carried'] {
  const { from } = input;
  const above = from.layer;

  // The system's own part becomes this layer's root component: what was one box
  // is about to become several, and the author is the one who decides how.
  const systemPart = from.parts.find((p) => !p.isActor && !isBookkeeping(p.keywords));
  let parts = 0;
  if (systemPart) {
    const def = (PLACEHOLDER[layer]?.def ?? ((n: string) => `${n}Component`))(input.systemName);
    w.comment(`the system, to be decomposed into ${layer === 'LA' ? 'logical' : 'physical'} components`);
    w.line(`part def ${def} {`);
    w.push();
    for (const port of systemPart.ports) w.line(portLine(port));
    w.line(`doc /* TODO: decompose into components and move the functions onto them. */`);
    w.pop();
    w.line('}');
    const usage = PLACEHOLDER[layer]?.usage ?? 'mainComponent';
    w.line(`part ${usage} : ${def};`);
    w.line(`trace ${usage} to ${systemPart.qualifiedName};`);
    parts = 1;
    w.blank();
  }
  const members = writePopulation(w, input, layer);

  // The resource that carries member-to-member traffic is the environment up
  // to LA and something built or bought at PA (CV-05, A1-R-11). Carried as an
  // actor, it stayed one in v5's PA, and no alternative could turn it into a
  // node: the head's actor definition wins over any redeclaration.
  const bearer = layer === 'PA' ? identifierOf(input.population?.bearer)?.toLowerCase() : undefined;
  const isBearer = (p: PartView): boolean =>
    bearer !== undefined && (p.name.toLowerCase() === bearer || (p.defName ?? '').toLowerCase() === bearer || actorDefName(p).toLowerCase() === bearer);
  const nodes = from.parts.filter((p) => p.isActor && !isBookkeeping(p.keywords) && isBearer(p));
  for (const node of nodes) {
    const def = actorDefName(node);
    w.comment('the bearer of member-to-member traffic: built or bought at PA, so a node, not the environment');
    w.line(`#Node part def ${def} {`);
    w.push();
    for (const port of node.ports) w.line(portLine(port));
    w.line(`doc /* TODO: the radio as a physical node — what it is, what hosts it, the medium its links are typed by. It was an actor at ${above}. */`);
    w.pop();
    w.line('}');
    w.line(`part ${node.name} : ${def};`);
    w.line(`trace ${node.name} to ${node.qualifiedName};`);
    w.blank();
  }
  const actors = from.parts.filter((p) => p.isActor && !isBookkeeping(p.keywords) && !isBearer(p));
  if (actors.length > 0) {
    w.comment('actors, carried over unchanged');
    for (const actor of actors) {
      const def = actorDefName(actor);
      w.line(`#Actor part def ${def} {`);
      w.push();
      for (const port of actor.ports) w.line(portLine(port));
      w.line(`doc /* TODO: check this actor's interface against ${above}. */`);
      w.pop();
      w.line('}');
      w.line(`part ${actor.name} : ${def};`);
      w.line(`trace ${actor.name} to ${actor.qualifiedName};`);
    }
    w.blank();
  }

  const allocationOf = new Map(from.allocations.map((a) => [a.actionName, a.partName]));
  const actorNames = new Set(actors.map((a) => a.name));
  const functions = from.actions.filter((a) => !isBookkeeping(a.keywords));
  if (functions.length > 0) {
    w.comment(`functions, carried over from ${above}: every one of them has to be realised here`);
    writeActionDefs(w, functions, (names, n) => `TODO: how ${names} ${n > 1 ? 'are' : 'is'} realised at ${layer}.`);
    for (const action of functions) {
      writeActionUsage(w, action);
      const entity = allocationOf.get(action.name);
      const target = entity !== undefined && actorNames.has(entity) ? entity : systemPart ? (PLACEHOLDER[layer]?.usage ?? 'mainComponent') : undefined;
      if (target) w.line(`allocate ${action.name} to ${target};`);
      w.line(`trace ${action.name} to ${action.qualifiedName};`);
    }
    w.blank();
  }

  const { count: flows } = writeFlows(w, from, new Map());
  writeSuccessions(w, from, new Map());

  return {
    functions: functions.length,
    flows,
    actors: actors.length,
    parts,
    capabilities: 0,
    members,
  };
}

/* ─────────────────────────── T-04: PA → EPBS ────────────────────────────── */

function paToEpbs(w: Writer, input: TransitionInput): Skeleton['carried'] {
  const { from } = input;
  // The method says this transition is not automatic, and it is right: what is one
  // configuration item is a procurement decision, not a modelling one. What a
  // script CAN do is put one candidate item under every physical part and make
  // the author say yes, no or merge — which is a smaller question than a blank
  // page.
  w.comment('one candidate configuration item per physical part — merge, split or retype them');
  let parts = 0;
  // A population is procured once: one item carrying the fleet's multiplicity.
  // Its representatives stand for any two members, not two more to buy.
  const fleetDefs = new Set(
    from.parts.filter((p) => p.multiplicity && /^([2-9]|\d{2,})/.test(p.multiplicity)).map((p) => p.defName).filter((d): d is string => !!d),
  );
  const candidates = from.parts.filter(
    (p) => !p.isActor && !isBookkeeping(p.keywords) && !(p.defName && fleetDefs.has(p.defName) && !p.multiplicity),
  );
  for (const part of candidates) {
    const def = `${capitalise(part.name)}Item`;
    w.line(`#CI_TBD part def ${def} {`);
    w.push();
    w.line(`doc /* TODO: is this a CSCI, an HWCI or a COTS item? Give it its contract. */`);
    w.pop();
    w.line('}');
    w.line(`part ${part.name}Ci : ${def}${part.multiplicity ? ` [${part.multiplicity}]` : ''};`);
    w.line(`trace ${part.name}Ci to ${part.qualifiedName};`);
    parts += 1;
  }
  return { functions: 0, flows: 0, actors: 0, parts, capabilities: 0 };
}

/* ────────────────────────────── shared bits ─────────────────────────────── */

/**
 * The population, as a definition and a fact, in every generated layer.
 *
 * Components never carry down — each architecture decomposes afresh — so a
 * fleet decided at LA was a fleet PA's author never saw. The member definition
 * is carried instead: at SA it is only a definition (the system is still one
 * box), and from LA down it is what the alternatives must instantiate, which
 * `orphans.layerPartDefs` and `replicas.memberPair` hold them to.
 */
function writePopulation(w: Writer, input: TransitionInput, layer: Layer): number {
  const p = input.population;
  if (!p) return 0;
  w.comment(`the population: ${p.size} identical members (CV-16)`);
  w.line(`#Member part def ${p.memberDef} {`);
  w.push();
  w.line(`out port meshOut : Common::${p.meshPort};`);
  w.line(`in port meshIn : ~Common::${p.meshPort};`);
  w.line(
    layer === 'SA'
      ? `doc /* TODO: one member of the system. At SA the system is still one black box: this definition is carried, not instantiated. */`
      : `doc /* TODO: one member at ${layer}. Instantiate it as \`part ${p.fleetPart} : ${p.memberDef} [${p.size}];\` plus two representatives joined by the peer interface. */`,
  );
  w.pop();
  w.line('}');
  w.line(`#prose part fleetFact {`);
  w.push();
  w.line(
    `doc /* Population: ${p.size} members of ${p.memberDef}, carried by ${p.fleetPart}, exchanging through Common::${p.meshInterface}. Carried from the brief; ${layer === 'SA' ? 'instantiated from LA down.' : 'the architecture instantiates it.'} */`,
  );
  w.pop();
  w.line('}');
  w.blank();
  return 1;
}

/** Tags a function keeps from layer to layer: what later gates and scores find it by. */
const CARRIED_TAGS = new Set(['Coordination', 'C2']);
const carriedTags = (action: ActionView): string =>
  [...new Set([...action.keywords, ...(action.defKeywords ?? [])])]
    .filter((k) => CARRIED_TAGS.has(k))
    .map((k) => `#${k} `)
    .join('');

/**
 * One definition per distinct type. Two members performing the same activity
 * are two usages of one definition, and writing the definition per usage
 * declares it twice — which is what the first population run did at T-01.
 */
function writeActionDefs(w: Writer, actions: ActionView[], todo: (names: string, count: number) => string): void {
  const byDef = new Map<string, ActionView[]>();
  for (const action of actions) {
    const def = action.defName ?? `${capitalise(action.name)}Definition`;
    byDef.set(def, [...(byDef.get(def) ?? []), action]);
  }
  for (const [def, users] of byDef) {
    w.line(`action def ${def} {`);
    w.push();
    w.line(`doc /* ${todo(users.map((a) => `\`${a.name}\``).join(', '), users.length)} */`);
    // The definition's own parameters come with it: a flow names them through
    // every usage, and a definition carried without them leaves those ends dangling.
    const seen = new Set<string>();
    for (const p of users.flatMap((a) => a.defParams ?? [])) {
      if (seen.has(p.name)) continue;
      seen.add(p.name);
      w.line(parameterLine(p));
    }
    w.pop();
    w.line('}');
  }
}

function writeActionUsage(w: Writer, action: ActionView): void {
  const def = action.defName ?? `${capitalise(action.name)}Definition`;
  const tags = carriedTags(action);
  // A parameter the definition already declares is inherited, not restated.
  const inherited = new Set((action.defParams ?? []).map((p) => p.name));
  const params = action.params.filter((p) => !inherited.has(p.name));
  if (params.length === 0) {
    w.line(`${tags}action ${action.name} : ${def};`);
    return;
  }
  w.line(`${tags}action ${action.name} : ${def} {`);
  w.push();
  // A parameter, not a port: `in x : T;` inside an action. The mapper turns it
  // into a PortUsage, which is why it comes back looking like one.
  for (const p of params) w.line(parameterLine(p));
  w.pop();
  w.line('}');
}

/** `alphaHandOverSector::meshOut` with its action renamed, when it was merged. */
const renameEnd = (end: string, rename: ReadonlyMap<string, string>): string => {
  const m = /^([A-Za-z_][A-Za-z0-9_]*)(.*)$/s.exec(end);
  return m && rename.has(m[1]) ? `${rename.get(m[1])}${m[2]}` : end;
};

function writeFlows(w: Writer, from: LayerView, rename: ReadonlyMap<string, string>): { count: number; peer: number } {
  const flows = from.flows.filter((f) => f.from && f.to);
  if (flows.length === 0) return { count: 0, peer: 0 };
  w.comment('interactions, carried over as functional exchanges');
  const seen = new Set<string>();
  let count = 0;
  let peer = 0;
  for (const [i, flow] of flows.entries()) {
    const name = flow.name ?? `exchange${i + 1}`;
    const payload = flow.payload ? ` of ${flow.payload}` : '';
    const src = renameEnd(flow.from!, rename);
    const dst = renameEnd(flow.to!, rename);
    // Two members' copies of one exchange with the environment are one exchange.
    const key = `${flow.payload ?? ''}|${src}|${dst}`;
    if (seen.has(key)) continue;
    seen.add(key);
    const same = (a: string, b: string): boolean => a.split(/::|\./)[0] === b.split(/::|\./)[0];
    if (src !== flow.from && dst !== flow.to && same(src, dst)) {
      // An exchange between two members is internal to the one system
      // function they merged into; it stays a flow so the exchange is not lost.
      w.comment(`between members at OA: ${flow.from} to ${flow.to}`);
      peer += 1;
    }
    w.line(`flow ${name}${payload} from ${src} to ${dst};`);
    count += 1;
  }
  w.blank();
  return { count, peer };
}

function writeSuccessions(w: Writer, from: LayerView, rename: ReadonlyMap<string, string>): void {
  const seen = new Set<string>();
  const lines: string[] = [];
  for (const s of from.successions.filter((x) => x.from && x.to)) {
    const a = renameEnd(s.from!, rename);
    const b = renameEnd(s.to!, rename);
    const key = `${a}|${b}`;
    if (a === b || seen.has(key)) continue;
    seen.add(key);
    lines.push(`succession first ${a} then ${b};`);
  }
  if (lines.length === 0) return;
  w.comment('order of the operational process, carried over');
  for (const l of lines) w.line(l);
  w.blank();
}

/**
 * Two or more representatives performing one activity become one function.
 *
 * Grouped by the definition the activities share, over activities allocated to
 * DIFFERENT members of the population. The merged function takes the name of
 * the brief function that definition is named after, else the definition's
 * name with a lower-case first letter, and the union of the halves'
 * parameters and tags. Pure: the caller writes it.
 */
export function collapseMembers(
  actions: ActionView[],
  memberOf: (a: ActionView) => string | undefined,
  named: readonly string[],
): { functions: ActionView[]; rename: Map<string, string>; halves: Map<string, ActionView[]> } {
  const groups = new Map<string, ActionView[]>();
  for (const a of actions) {
    if (!a.defName || memberOf(a) === undefined) continue;
    groups.set(a.defName, [...(groups.get(a.defName) ?? []), a]);
  }
  const rename = new Map<string, string>();
  const halves = new Map<string, ActionView[]>();
  const merged = new Map<string, ActionView>();
  const taken = new Set(actions.map((a) => a.name));
  for (const [def, group] of groups) {
    if (group.length < 2 || new Set(group.map(memberOf)).size < 2) continue;
    let name = named.find((n) => capitalise(n) === def) ?? def[0].toLowerCase() + def.slice(1);
    if (taken.has(name) && !group.some((g) => g.name === name)) name = `${name}ByMembers`;
    taken.add(name);
    const params = new Map<string, ParamView>();
    for (const g of group) for (const p of g.params) if (!params.has(p.name)) params.set(p.name, p);
    const keywords = [...new Set(group.flatMap((g) => [...g.keywords, ...(g.defKeywords ?? [])]))];
    merged.set(group[0].name, { ...group[0], name, params: [...params.values()], keywords });
    for (const g of group) rename.set(g.name, name);
    halves.set(name, group);
  }
  const functions: ActionView[] = [];
  for (const a of actions) {
    if (!rename.has(a.name)) functions.push(a);
    else if (merged.has(a.name)) functions.push(merged.get(a.name)!);
  }
  return { functions, rename, halves };
}

const parameterLine = (p: ParamView): string => {
  const dir = p.direction ? `${p.direction} ` : '';
  const type = p.type ? ` : ${p.type}` : '';
  return `${dir}${p.name}${type};`;
};

const portLine = (p: ParamView): string => {
  const dir = p.direction ? `${p.direction} ` : '';
  const type = p.type ? ` : ${p.type}` : '';
  return `${dir}port ${p.name}${type};`;
};

const actorDefName = (actor: PartView): string => actor.defName ?? `${capitalise(actor.name)}Actor`;

const capitalise = (s: string): string => (s.length === 0 ? s : s[0].toUpperCase() + s.slice(1));

/** The layer a rule reads, and the one it writes. */
export function ruleLayers(rule: TransitionRule): { from: Layer; to: Layer } {
  const to = TARGET[rule];
  const at = (AUTHORED_LAYERS as readonly Layer[]).indexOf(to);
  return { from: AUTHORED_LAYERS[at - 1], to };
}

class Writer {
  #lines: string[] = [];
  #depth = 1;
  push(): void {
    this.#depth += 1;
  }
  pop(): void {
    this.#depth -= 1;
  }
  line(text: string): void {
    this.#lines.push(`${'    '.repeat(this.#depth)}${text}`);
  }
  comment(text: string): void {
    this.line(`// ${text}`);
  }
  blank(): void {
    if (this.#lines.at(-1) !== '') this.#lines.push('');
  }
  text(): string {
    return `${this.#lines.join('\n')}\n`;
  }
}
