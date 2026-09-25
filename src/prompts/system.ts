/**
 * What an authoring agent is told before it is shown anything.
 *
 * Three kinds of thing go in here and nothing else: the shape of the answer,
 * the house rules that apply to this step (by id, with their text), and the
 * limits of the dialect — the constructs that do not exist, and the words that
 * cannot name a feature. All three are the difference between a fragment that
 * needs one repair round and one that needs four.
 */
import { conventionsFor } from '../spec/conventions.ts';
import { noteFor } from '../spec/codes.ts';
import { RESERVED_FEATURE_NAMES } from '../spec/keywords.ts';
import type { Layer } from '../spec/layers.ts';
import type { KnobId, StepSpec } from '../spec/steps.ts';

export interface SystemPromptOptions {
  step: StepSpec;
  knobs: Record<KnobId, boolean>;
  root: string;
  /** The alternative this agent is writing, when it is writing one of several. */
  alternative?: number;
  alternatives?: number;
}

/** What each layer is for, in the words the step tables use. */
const LAYER_BRIEF: Partial<Record<Layer, string>> = {
  Common: 'Shared DEFINITIONS only — nothing happens here. Item definitions for what flows, port and interface definitions, attribute definitions, and one #MoE attribute per measure with a require constraint. No parts, no actions, no successions, no state machines, no transitions: behaviour belongs to a layer, and a succession written here has nothing to follow.',
  Needs: 'The customer\'s own words, as requirement definitions with a subject. Nothing is invented here and nothing is solved.',
  Imposed: 'What the customer already has and the design must use: existing components, imposed interfaces, standards. Everything is tagged #Imposed or #Standard and carries its source in a doc.',
  OA: 'The operation as it is, WITHOUT the system: the entities, what each of them does, what they exchange, and the operational modes. EVERY activity at this layer is a usage written directly in this package and `allocate`d to the entity that performs it -- for an actor as much as for a member -- never nested inside the part. A flow then joins two of them, `from taskMissionAct.taskingOut to taskingRecv.taskingIn`: two segments, a usage and its port. An activity written inside a part makes a three-segment end that resolves to nothing once the layer is carried down, and the exchange is lost. Every capability the brief names is a `#Capability use case def` here, with a `subject` naming the entity that holds it, and the overall mission is a `#Mission use case def` — they are what the next layer hands to the system, so a capability that is not modelled is one the system will never be asked for. Naming the system here is the one mistake this layer exists to prevent. When the brief declares a population, the entity the system takes over is several identical members: declare its definition once and at least two representative usages, then for each activity write the usage in this package and `allocate` it to the representative that performs it -- `action alphaHandOver : HandOver;` beside the parts, with `allocate alphaHandOver to memberA;` -- and NOT nested inside the member part, which reads as ownership rather than allocation and carries nothing to the next layer, and model what they exchange with each other as flows between their activities — including the coordination the operation already needs today.',
  SA: 'The system as one black box: its ports on the environment, the functions it takes over, the actors it faces. Every function traces to an operational activity. No internal structure — a population is still one box here, and its member definition is carried, not instantiated. The coordination between members and the command and control the brief names are functions of the system, tagged `#Coordination` and `#C2`, each with a flow.',
  LA: 'The system decomposed into logical components: what each does, what they exchange, their modes. Every logical function realises a system function. Nothing physical is chosen yet. Each architecture states its own worst-case estimate for every measure of effectiveness as `#Estimate attribute <measure> :> Common::<measure> = <value>` with its basis in the doc (CV-17). A population is one member definition, a usage carrying its multiplicity, and two representatives joined by the peer interface (CV-16); where the `#Coordination` and `#C2` functions are allocated — ground or members — is the architecture decision.',
  PA: 'The components that get built: behaviour parts hosted inside node parts by nesting, typed physical links, item definitions with units, resource budgets as require constraints, and a worst-case `#Estimate attribute <measure> :> Common::<measure> = <value>` per measure of effectiveness with its basis in the doc (CV-17), each written DIRECTLY in this package beside the parts and never collected together inside a part or a part def -- the trade-off reads each estimate by its name at the level of the layer, and one nested a level deeper is not scored at all. A population keeps its member definition, multiplicity and representative pair (CV-16); the link between two members is a connection typed by a medium connection def, and the radio that carries it is a `#Node` part, not an actor.',
  EPBS: 'One configuration item per thing procured, built or delivered: each realises a physical part, carries its contract as a requirement, and is verified by a verification case.',
};

const DIALECT_LIMITS = [
  '`expose` does not exist — a view states its scope in a doc.',
  '`allocation def` does not exist — allocation is the bare `allocate a to b;`.',
  'There is no `after(n)` time trigger and no guarded succession.',
  'A transition is `transition <from> -> <to>;` or `transition <name> first <from> accept <e> : <Item> do action <a> then <to>;` — measured: the anonymous `first a accept e : E then b;` does not parse.',
  'A trigger payload cannot be named `assign` or `event` — both are keywords. `accept assignment : X` is fine.',
  '`actor` as a keyword becomes a constraint, not an actor: write `#Actor part def X;` and a part of it.',
  '`message` is only for occurrence scenarios; between actions use `flow`.',
  '`variation`/`variant` parse but carry no meaning here — tag variants `#Variant`.',
  'Every `#Tag` must be declared as `metadata def <Tag>;` in package Kinds before it is used, and it goes BEFORE the keyword: `#Variant attribute x`, never `attribute #Variant x`.',
  'A doc is a comment: `doc /* what it is for */` — never `doc "…";`, which is a string the grammar does not expect there.',
  'A requirement definition and a requirement usage are counted separately: satisfy the one you mean.',
  'Indexed ends do not parse: `fleet[1].meshOut` is an error. An exchange between two members is written between two named usages of the member definition.',
  'There is no entry pseudostate: `entry;` and `transition entry -> S;` do not mean "initial". Write `initial start; transition start -> S;`.',
];

/**
 * What kind of hazard a layer adds, for the author who reads "state the
 * hazards this layer adds" as permission to state none: v7's EPBS did, and
 * `requirements.hazards` blocked it once.
 */
const LAYER_HAZARDS: Partial<Record<string, string>> = {
  SA: 'what the system as a whole can do wrong at its boundary',
  LA: 'what a split of responsibilities between components introduces — a single point of failure, a lost hand-off',
  PA: 'what the chosen technology introduces — a part that wears, a radio that drops, software that crashes',
  EPBS: 'what a configuration item introduces — a supplier that stops shipping, a version that drifts across the fleet, a part that becomes obsolete',
};

export function buildSystemPrompt(opts: SystemPromptOptions): string {
  const { step, knobs, root } = opts;
  const layer = step.layer;
  const lines: string[] = [];

  lines.push(
    'You are one step of a systems-architecture workflow. You write SysML-like model text, in the textual notation of the published SysML specification as the Sysprose checker accepts it — spec-shaped, never claimed as conformant.',
    '',
  );

  if (layer) {
    lines.push(`## Your job`, `Write the \`package ${layer}\` fragment of the model \`${root}\`.`, '');
    if (LAYER_BRIEF[layer]) lines.push(LAYER_BRIEF[layer] as string, '');
  }

  if (opts.alternative !== undefined) {
    lines.push(
      `You are writing architecture alternative ${opts.alternative} of ${opts.alternatives ?? '?'}. It must be a genuinely different way of organising the same functions — a different split of responsibilities, not a rename of someone else's.`,
      '',
    );
  }

  lines.push('## The answer', 'Return the object the schema asks for. The `fragment` field is model text and nothing else:');
  if (layer) {
    lines.push(
      `- exactly one \`package ${layer} { … }\`, and nothing outside it`,
      `- never re-declare the root package \`${root}\`; the layers are assembled into it`,
      '- no imports: this dialect has one file, and layers reference each other by qualified name',
      `- references to another layer are qualified: \`${root}::<Layer>::<name>\``,
      '- references point upward only: a layer never names one below it',
      '- no markdown fence around the fragment',
    );
  }
  lines.push('');

  const conventions = conventionsFor(step.uses);
  if (conventions.length > 0) {
    lines.push('## House rules that apply here');
    for (const c of conventions) lines.push(`- **${c.id} ${c.title}** — ${c.rule}`);
    lines.push('');
  }

  lines.push('## What this dialect does not have');
  for (const limit of DIALECT_LIMITS) lines.push(`- ${limit}`);
  lines.push(
    `- These words cannot name a feature — the grammar reads them as the start of a clause: ${RESERVED_FEATURE_NAMES.slice(0, 30).join(', ')}, and the other keywords of the language.`,
    '',
  );

  if (step.postconditions.length > 0) {
    lines.push('## What is checked after you answer', 'Your fragment is assembled with the layers above it and put through the checker. These have to hold:');
    for (const p of step.postconditions) lines.push(`- ${p}`);
    lines.push('');
  }

  if (step.failCodes.length > 0) {
    lines.push('## The mistakes this step is graded on');
    for (const code of step.failCodes) {
      const note = noteFor(code);
      lines.push(`- \`${code}\`${note ? ` — ${note.note}` : ''}`);
    }
    lines.push('');
  }

  const on = (Object.keys(knobs) as KnobId[]).filter((k) => knobs[k]);
  if (on.length > 0) {
    lines.push('## Options switched on for this run');
    if (knobs.modes_states) lines.push('- **modes and states**: give every element that has them two state definitions, tagged `#Mode` and `#State`. Every state must be reachable.');
    if (knobs.interfaces) lines.push('- **interfaces**: ports and connections are checked; a port that connects to nothing is reported.');
    if (knobs.variability) lines.push('- **variability**: where the design has options, tag them `#Variant`.');
    if (knobs.safety) lines.push(`- **safety**: every layer adds hazards of its own${layer && LAYER_HAZARDS[layer] ? ` — here, ${LAYER_HAZARDS[layer]}` : ''}; state at least one. `+'State the hazards this layer ADDS as `#Hazard` requirement usages inside a nested `package Hazards`, each naming the element it is about, under names no layer above uses — a hazard stated above is never restated; satisfy it by its path, `satisfy SA::Hazards::<name> by <what mitigates it>;`. Mitigate each one: `satisfy <hazard> by <the function or component that mitigates it>;`. A hazard you deliberately do not mitigate is tagged `#Accepted` with the reason in its doc. Every hazard stated so far in the model, this layer\'s and the ones above, has to be satisfied or accepted; a stated hazard nothing mitigates blocks the step.');
    if (knobs.verification) lines.push('- **verification**: numeric budgets are worth writing as `require constraint { … }` — a solver reads them later. It never blocks you.');
    lines.push('');
  }

  lines.push(
    '## How to work',
    '- Model what the inputs say. Do not invent capability the brief does not describe, and do not leave out what it does — and do not collapse a population the brief declares into a single instance.',
    '- Everything you were given from the layer above is there because it has to be realised here. If something should not be carried over, say so in `todos` rather than dropping it silently.',
    '- Give every element a `doc` that says what it is for. The audit is read by people who were not in this conversation.',
    '- Every type you name has to exist. If a flow, a trigger or a port needs an item definition that `package Common` does not declare, return that declaration in `commonAdditions` — naming `Common::Something` that is not there is the commonest way a layer fails to load.',
    '- Replace every `TODO` you are handed, or explain in `todos` why it stays.',
  );

  return lines.join('\n');
}
