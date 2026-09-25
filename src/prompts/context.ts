/**
 * What an authoring agent is shown.
 *
 * Not the model. The assembled prefix is the file the checker reads, and by PA
 * it is several hundred elements — handing it over whole spends the context on
 * text the agent is not allowed to edit anyway. What it gets instead is: the
 * brief, the skeleton it is meant to enrich, a one-line-per-element summary of
 * the layer above, the guidance the model itself carries for this layer, and
 * the post-conditions its answer will be held to. The full prefix goes in only
 * while the model is small enough for that to be free.
 */
import { ruleTemplate } from '../spec/rules.ts';
import { boundText } from '../spec/measures.ts';
import type { ElementRow } from '../sysprose/types.ts';
import type { PromptReport } from '../sysprose/types.ts';
import type { Layer } from '../spec/layers.ts';
import type { RepairItem } from '../check/classify.ts';
import type { SeedOutput } from '../llm/schemas.ts';

export interface AuthorContext {
  brief?: SeedOutput;
  layer?: Layer;
  root: string;
  /** The generated starting point, when this step follows a transition. */
  skeleton?: string;
  /** What is in the layer above, one line each. */
  above?: { layer: Layer; elements: ElementRow[] };
  /** `#prompt` guidance the model carries for this layer. */
  guidance: string[];
  postconditions: string[];
  /** Comments a human left at a gate. */
  reviewerComments: string[];
  /** What the previous attempt was told, when there was one. */
  previousItems?: RepairItem[];
  /** The whole assembled prefix, when it is small enough to be worth it. */
  fullPrefix?: string;
  /** Anything a step wants to add — the alternatives it must differ from, say. */
  extra?: string[];
}

export interface ContextLimits {
  maxChars: number;
  maxElementLines: number;
}

const DEFAULT_LIMITS: ContextLimits = { maxChars: 60_000, maxElementLines: 400 };

export function briefSection(brief: SeedOutput): string {
  const lines = [
    `**System**: ${brief.systemName}`,
    `**Mission**: ${brief.mission}`,
    `**Function**: ${brief.functionSentence}`,
    '',
    '**Environment**',
    ...brief.environment.map((e) => `- ${e.quadrant}: \`${e.name}\` — ${e.doc}`),
    '',
    '**Stakeholders**',
    ...brief.stakeholders.map((s) => `- ${s.name}: ${s.role}`),
    '',
    '**Capabilities**',
    ...brief.capabilities.map((c) => `- \`${c.name}\` — ${c.doc}`),
    '',
    '**Measures of effectiveness** (the architectures are scored on these)',
    ...brief.moes.map((m) => `- \`${m.name}\` (${m.kind === 'budget' ? `budget ${boundText(m)} — fixed by the brief, held by its requirement, not estimated or scored` : `target ${boundText(m)}`}) — ${m.doc}`),
    '',
    `**Operational entity the system takes over**: \`${brief.systemEntity}\` — declare its part under exactly this name, untagged.`,
    ...populationLines(brief),
    ...knownLines(brief),
  ];
  return lines.join('\n');
}

/**
 * What the brief fixed by name: the hazards it already knows, the modes it
 * names, the rules the system never breaks, the fields its items carry. Here
 * for the reason the population is — this section survives `fit()`.
 */
function knownLines(brief: SeedOutput): string[] {
  const lines: string[] = [];
  if ((brief.hazards ?? []).length > 0)
    lines.push('', `**Hazards the brief names** — each is a \`#Hazard requirement <name>\` in \`SA::Hazards\`, stated once there and satisfied by path below (\`satisfy SA::Hazards::<name> by <part>;\`), never restated: ${brief.hazards!.map((h) => `\`${h.name}\` (${h.doc})`).join('; ')}`);
  if ((brief.modes ?? []).length > 0)
    lines.push('', `**Modes the brief names** — each is a \`state\` of that name in a state definition of its owner: ${brief.modes!.map((m) => `\`${m.name}\` of the ${m.of} (${m.doc})`).join('; ')}`);
  if ((brief.rules ?? []).length > 0)
    lines.push(
      '',
      '**Rules the system never breaks** (CV-18) — each is a `#Rule requirement <name> { subject … ; doc /* … */ }` stated once at SA and satisfied by the part whose state machine carries it; from SA down that machine carries the rule as a property the checker refutes or confirms, doc first:',
      ...brief.rules!.map((r) => `- \`${r.name}\` (${r.kind}, on the ${r.of}'s machine) — ${r.doc}. Write inside that \`state def\`: \`${ruleTemplate(r.name, r.kind)}\``),
    );
  if ((brief.items ?? []).length > 0)
    lines.push('', `**What the items carry** — attributes of these item definitions in Common: ${brief.items!.map((i) => `\`${i.name}\` (${i.fields.map((f) => f.name).join(', ')})`).join('; ')}`);
  return lines;
}

/**
 * The population, first thing in every prompt that has one.
 *
 * It is in the brief section because that section survives `fit()`: by PA the
 * full prefix is thousands of elements and is the first thing dropped, and a
 * fleet stated only there was a fleet no author ever read.
 */
function populationLines(brief: SeedOutput): string[] {
  const p = brief.population;
  if (!p) return [];
  const names = (fns: SeedOutput['coordinationFunctions']): string =>
    (fns ?? []).map((f) => `\`${f.name}\``).join(', ') || 'none named';
  return [
    '',
    `**Population**: ${p.size} identical members. ${p.doc}`,
    `- member definition \`${p.memberDef}\`; the usage that carries the count \`${p.fleetPart}\`; peer port \`Common::${p.meshPort}\`; peer interface \`Common::${p.meshInterface}\`${p.bearer ? `; carried by \`${p.bearer}\`` : ''}`,
    `- At OA: the entity the system takes over is a population — its definition once, two representative usages, each with its own activities, and the interactions between them. Each coordination and command-and-control function below is an \`action def\` named after it, capitalised and tagged (\`#Coordination action def HandOverSector\`), and each member's activity is typed by it.`,
    `- From LA down (CV-16): one \`#Member part def ${p.memberDef}\` with \`out port meshOut : Common::${p.meshPort}; in port meshIn : ~Common::${p.meshPort};\`, \`part ${p.fleetPart} : ${p.memberDef} [${p.size}];\`, two representatives \`memberA\`/\`memberB\`, and \`interface peerLink : Common::${p.meshInterface} connect memberA.meshOut to memberB.meshIn;\`. Never collapse the population into one instance.`,
    `- **Coordination between members** (tag \`#Coordination\`): ${names(brief.coordinationFunctions)}`,
    `- **Command and control** (tag \`#C2\`): ${names(brief.c2Functions)}`,
  ];
}

/** One line per element: what it is, what it is typed by, what it is for. */
export function elementLines(elements: ElementRow[], root: string, layer: Layer, limit: number): string[] {
  const at = `${root}::${layer}::`;
  return elements
    .filter((e) => e.qualifiedName.startsWith(at))
    .slice(0, limit)
    .map((e) => {
      const type = e.type ? ` : ${e.type}` : '';
      const value = e.value ? ` = ${e.value}` : '';
      const doc = e.doc ? ` — ${collapse(e.doc)}` : '';
      return `${e.qualifiedName.slice(at.length)}${type}${value}  [${e.metaclass}]${doc}`;
    });
}

export function guidanceFrom(report: PromptReport | undefined): string[] {
  if (!report) return [];
  return report.prompts.map((p) => collapse(p.text));
}

export function buildUserPrompt(ctx: AuthorContext, limits: ContextLimits = DEFAULT_LIMITS): string {
  const sections: Array<[string, string]> = [];

  if (ctx.brief) sections.push(['The brief', briefSection(ctx.brief)]);

  if (ctx.above) {
    const lines = elementLines(ctx.above.elements, ctx.root, ctx.above.layer, limits.maxElementLines);
    sections.push([
      `What is in ${ctx.above.layer} (the layer above)`,
      lines.length > 0 ? lines.join('\n') : '(empty)',
    ]);
  }

  if (ctx.skeleton) {
    sections.push([
      'Your starting point',
      [
        'This was generated from the layer above by the transition rules. Everything in it is already traced and allocated — keep those links, replace the TODOs, and add what this layer introduces.',
        '',
        '```',
        ctx.skeleton.trimEnd(),
        '```',
      ].join('\n'),
    ]);
  }

  if (ctx.guidance.length > 0) {
    sections.push(['Guidance the model carries for this layer', ctx.guidance.map((g) => `- ${g}`).join('\n')]);
  }

  if (ctx.reviewerComments.length > 0) {
    sections.push([
      'A reviewer asked for this',
      ctx.reviewerComments.map((c) => `- ${c}`).join('\n'),
    ]);
  }

  if (ctx.previousItems && ctx.previousItems.length > 0) {
    sections.push([
      'What the checker said about your previous answer',
      ctx.previousItems.map(itemLine).join('\n'),
    ]);
  }

  if (ctx.postconditions.length > 0) {
    sections.push(['This is what your answer is checked against', ctx.postconditions.map((p) => `- ${p}`).join('\n')]);
  }

  for (const extra of ctx.extra ?? []) sections.push(['Also', extra]);

  if (ctx.fullPrefix) {
    sections.push(['The whole model so far', ['```', ctx.fullPrefix.trimEnd(), '```'].join('\n')]);
  }

  return fit(sections, limits.maxChars);
}

export function itemLine(item: RepairItem): string {
  const where = item.fragmentLine ? ` (line ${item.fragmentLine})` : '';
  const who = item.qualifiedName ? ` \`${item.qualifiedName}\`` : '';
  const rule = item.cv ? ` [${item.cv}]` : '';
  const hint = item.hint ? `\n    ${collapse(item.hint)}` : '';
  return `- ${item.blocking ? 'MUST FIX' : 'note'} \`${item.code}\`${who}${where}${rule}: ${collapse(item.message)}${hint}`;
}

const collapse = (text: string): string => text.replace(/\s+/g, ' ').trim();

/**
 * Keep the prompt under the budget by dropping whole sections from the back.
 *
 * The last sections are the optional ones — the full prefix, then the extras.
 * Truncating a fragment in the middle would hand the agent a model that does
 * not parse and ask it why.
 */
function fit(sections: Array<[string, string]>, maxChars: number): string {
  const render = (list: Array<[string, string]>): string =>
    list.map(([title, body]) => `## ${title}\n\n${body}`).join('\n\n');
  const kept = [...sections];
  let text = render(kept);
  while (text.length > maxChars && kept.length > 1) {
    const [dropped] = kept.splice(kept.length - 1, 1);
    text = `${render(kept)}\n\n## ${dropped[0]}\n\n(left out: this prompt was over its size budget)`;
  }
  return text;
}
