/**
 * The first step: a brief becomes the ground the model is built on.
 *
 * SEED is the only agent that is not handed a model, and the only one whose
 * answer is mostly not model text: the mission sentence, the environment
 * quadrants it was derived from, the capabilities, and the measures every later
 * architecture is scored against. What it does write — package Common — is the
 * vocabulary every layer shares, which is why it is worth one careful call
 * rather than letting each layer invent its own items.
 */
import { writeFileSync } from 'node:fs';
import { buildSystemPrompt } from '../prompts/system.ts';
import { SeedOutputSchema, type SeedOutput } from '../llm/schemas.ts';
import { preflight } from '../model/fragments.ts';
import { step as stepById } from '../spec/steps.ts';
import { modelFor } from '../config/load.ts';
import { kindsFragment, type AgentContext } from './context.ts';

export interface SeedResult {
  brief: SeedOutput;
  rationale: string;
  preflightProblems: string[];
}

export async function runSeed(ctx: AgentContext, briefText: string): Promise<SeedResult> {
  const step = stepById('S00');
  const system = buildSystemPrompt({ step, knobs: ctx.knobs, root: ctx.layout.root || 'System' });
  const knobList = (Object.keys(ctx.knobs) as Array<keyof typeof ctx.knobs>)
    .map((k) => `- ${k}: ${ctx.knobs[k] ? 'on' : 'off'}`)
    .join('\n');

  const user = [
    '## The brief',
    '',
    briefText.trim(),
    '',
    '## What to produce',
    '',
    'Settle the ground the whole model is built on:',
    '- the mission sentence, read off the environment: what comes in, what goes out, what constrains the system, what supplies it;',
    '- the function sentence, in the form `<System> <verb>s <object> from <state> to <state>`;',
    '- the operational entity the system takes over — the one whose activities become system functions. It is an entity of the operation, not the system itself;',
    '- the capabilities, the stakeholders, and the measures of effectiveness the architectures will be scored on. A measure\'s target is the number the brief states for it when the brief states one; set a target yourself only where the brief is silent, and say so in the measure\'s doc — a target nobody asked for can make every architecture fail. A number the brief marks as a placeholder awaiting the customer\'s is `placeholder: true`. A number the brief FIXES rather than asks the design to achieve (the fleet it can field, the time an operator has per report) is `kind: "budget"`: it is still declared, and never scored. When the brief fixes an area a population works over and an endurance for its members, it almost always implies a cruise speed too, and without one nothing can say whether a member reaches its station and returns inside that endurance \u2014 a swarm flown at v7\'s numbers spent more than its whole flight budget on the return leg alone. Declare the speed as a budget when the brief gives one; when the brief is silent, say so in the doc of the endurance budget rather than leaving the question unasked;',
    '- `hazards`, `rules`, `modes` and `items`: ONLY what the brief itself names — the hazards it already knows, the rules it says the system never breaks, the operating modes it names, and the items whose fields it lists. Leave each empty when the brief is silent; a layer finds its own hazards later. A rule is one of three kinds: `winsUntil` (once one situation holds, another never does until a third — a recall wins until landing), `precededBy` (one situation only after another — no watching before clearance), `canAlwaysReturn` (a situation reachable from everywhere — an isolated member can always get home). Say whose state machine carries each rule and mode: `member`, `fleet`, `ground`, or `system` when there is no population;',
    '- `package Common`: the item definitions for everything that flows, the port definitions, the interface definitions, and one `#MoE attribute` per measure with a `require constraint` holding it to its target. Every item in `items` is an `item def` here with exactly its fields as attributes, each with a doc: `item def DetectionReport { doc /* … */ attribute confidence : ScalarValues::Real { doc /* … */ } }`.',
    '- when the system is several identical members that interact (a swarm, a fleet, a constellation): the `population` — the member definition the solution layers will instantiate, the usage that carries the count, the size, the port and interface definitions in `package Common` a member exchanges with a peer through, the capability that is coordination between members, and the resource that carries member-to-member traffic. Declare that port and interface in Common in this shape, which the members are wired through from LA down: `port def <PeerPort> { out item update : <Item>; }` and `interface def <PeerInterface> { end sender : <PeerPort>; end receiver : ~<PeerPort>; }`. The operational entity the system takes over is then one representative member;',
    '- `coordinationFunctions`: what members settle between themselves, and `c2Functions`: the command and control an operator exercises over the whole system — named as the brief names them, camelCase verb phrases that are not keywords (`assign`, `accept` and `send` are keywords). Leave both empty when there is no population.',
    '',
    '## Options switched on for this run',
    '',
    knobList,
    // A rejection at G-SEED used to write the reviewer's comment into `Common`
    // — the file this step rewrites on its next run, so nothing ever read it.
    ...reviewerSection(ctx.state.gateComments?.[step.id] ?? []),
  ].join('\n');

  const result = await ctx.llm.complete({
    tag: 'S00:SEED',
    system,
    user,
    schema: SeedOutputSchema,
    model: modelFor(ctx.config, 'SEED'),
    timeoutMs: ctx.config.limits.llm_call_timeout_ms,
  });
  const brief = result.data;

  // The root package is named from the system, so the layout the caller made
  // with a placeholder name is not the one the files are written under.
  const checked = preflight(brief.commonFragment, 'Common', { root: brief.systemName });
  writeFileSync(ctx.layout.fragmentPath('Kinds'), kindsFragment(brief.extraKinds));
  writeFileSync(ctx.layout.fragmentPath('Common'), checked.fragment);
  writeFileSync(ctx.layout.rootHeaderPath, rootHeader(brief));
  writeFileSync(ctx.layout.briefJsonPath, `${JSON.stringify(brief, null, 2)}\n`);
  writeFileSync(ctx.layout.briefPath, briefMarkdown(brief, briefText, ctx.knobs));

  return {
    brief,
    rationale: brief.rationale,
    preflightProblems: checked.problems.map((p) => `${p.code}: ${p.message}`),
  };
}

/** What a person said when they rejected the brief, for the run that follows. */
export function reviewerSection(comments: readonly string[]): string[] {
  if (comments.length === 0) return [];
  return [
    '',
    '## What a reviewer said about the last attempt',
    '',
    'The brief you produced was rejected with these words. Answer them in this attempt, and say in the rationale what you changed.',
    '',
    ...comments.map((c) => `- ${c}`),
  ];
}

const rootHeader = (brief: SeedOutput): string =>
  `    doc /* ${brief.systemName} — layered model.\n           Mission: ${brief.mission}\n           Function: ${brief.functionSentence}\n           One package per perspective; references point upward only. */\n`;

/**
 * Whether a target's number is written in the brief, or SEED set it.
 *
 * v5's brief stated neither the fleet nor the coverage, SEED set 0.95 and 12,
 * and no architecture met the pair. Whether a number came from the customer is
 * the first thing to ask when a target turns out unreachable.
 */
export function targetSource(target: number, briefText: string, placeholder = false): 'brief' | 'placeholder in the brief' | 'set by SEED' {
  if (placeholder) return 'placeholder in the brief';
  // Exact numeric equality: rounding would read 0.95 as the brief's 0.9.
  const numbers = briefText.match(/\d+(?:[.,]\d+)?/g) ?? [];
  return numbers.some((n) => Number(n.replace(',', '.')) === target) ? 'brief' : 'set by SEED';
}

function briefMarkdown(brief: SeedOutput, source: string, knobs: Record<string, boolean>): string {
  return [
    `# ${brief.systemName}`,
    '',
    `**Mission**: ${brief.mission}`,
    '',
    `**Function**: ${brief.functionSentence}`,
    '',
    `**Operational entity the system takes over**: \`${brief.systemEntity}\``,
    '',
    '## Environment',
    '',
    '| Quadrant | Element | What it is |',
    '|---|---|---|',
    ...brief.environment.map((e) => `| ${e.quadrant} | \`${e.name}\` | ${e.doc} |`),
    '',
    '## Stakeholders',
    '',
    ...brief.stakeholders.map((s) => `- **${s.name}** — ${s.role}`),
    '',
    '## Capabilities',
    '',
    ...brief.capabilities.map((c) => `- \`${c.name}\` — ${c.doc}`),
    '',
    ...populationMarkdown(brief),
    ...knownMarkdown(brief),
    '## Measures of effectiveness',
    '',
    '| Measure | Sense | Target | Target from | Unit | What it decides |',
    '|---|---|---|---|---|---|',
    ...brief.moes.map((m) => `| \`${m.name}\` | ${m.sense} | ${m.target} | ${targetSource(m.target, source, m.placeholder)} | ${m.unit || '—'} | ${m.doc} |`),
    '',
    '## Options',
    '',
    '| Knob | State |',
    '|---|---|',
    ...Object.entries(knobs).map(([k, v]) => `| ${k} | ${v ? 'on' : 'off'} |`),
    '',
    '## Why this framing',
    '',
    brief.rationale,
    '',
    '## The brief as it was given',
    '',
    '```',
    source.trim(),
    '```',
    '',
  ].join('\n');
}

/** What the brief fixed by name — hazards, rules, modes, items — only the sections it has. */
function knownMarkdown(brief: SeedOutput): string[] {
  const out: string[] = [];
  if ((brief.hazards ?? []).length > 0)
    out.push('## Hazards the brief names', '', ...brief.hazards!.map((h) => `- \`${h.name}\` — ${h.doc}`), '');
  if ((brief.rules ?? []).length > 0)
    out.push('## Rules the system never breaks', '', '| Rule | Kind | Carried by | In the brief\'s words |', '|---|---|---|---|', ...brief.rules!.map((r) => `| \`${r.name}\` | ${r.kind} | ${r.of} | ${r.doc} |`), '');
  if ((brief.modes ?? []).length > 0)
    out.push('## Modes', '', '| Mode | Of | What it is |', '|---|---|---|', ...brief.modes!.map((m) => `| \`${m.name}\` | ${m.of} | ${m.doc} |`), '');
  if ((brief.items ?? []).length > 0)
    out.push('## What the items carry', '', ...brief.items!.map((i) => `- \`${i.name}\`: ${i.fields.map((f) => `\`${f.name}\``).join(', ')}`), '');
  return out;
}

/** The population, and the functions it implies — only when the brief has one. */
function populationMarkdown(brief: SeedOutput): string[] {
  const p = brief.population;
  if (!p) return [];
  const list = (fns: SeedOutput['coordinationFunctions']): string[] =>
    (fns ?? []).length > 0 ? (fns ?? []).map((f) => `- \`${f.name}\` — ${f.doc}`) : ['- none named'];
  return [
    '## Population',
    '',
    `${p.size} members of \`${p.memberDef}\`, carried by \`${p.fleetPart}\`. ${p.doc}`,
    '',
    `- peer port: \`Common::${p.meshPort}\`; peer interface: \`Common::${p.meshInterface}\``,
    `- coordination capability: \`${p.coordinationCapability}\``,
    ...(p.bearer ? [`- carried by: \`${p.bearer}\``] : []),
    '',
    '## Coordination between members (#Coordination)',
    '',
    ...list(brief.coordinationFunctions),
    '',
    '## Command and control (#C2)',
    '',
    ...list(brief.c2Functions),
    '',
  ];
}
