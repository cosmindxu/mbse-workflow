/**
 * Several architectures for the same functions.
 *
 * This is the step the word "optimal" in the goal actually rests on: without a
 * second candidate there is nothing to be better than. The function layer is
 * fixed before this runs, so what differs between alternatives is exactly the
 * thing under study — how responsibilities are split across components — and
 * each one is checked in its own assembled file so their names never collide.
 */
import { boundText, estimateLine, scoredMoes } from '../spec/measures.ts';
import type { Moe } from '../llm/schemas.ts';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { authorLayer, type AuthorResult } from './author.ts';
import { ComponentsOutputSchema } from '../llm/schemas.ts';
import { PLACEHOLDER } from '../transition/skeleton.ts';
import { withoutTradeOff } from './evaluate.ts';
import { balanceBraces, matchingBrace, mergeNestedPackages, nestedAdditions, packageBody, splitStatements, unwrapWholePackage, withoutDuplicates } from '../model/statements.ts';
import type { AgentContext } from './context.ts';
import { layerIndex, previousAuthoredLayer, type Layer } from '../spec/layers.ts';
import { hazardPaths } from '../model/hazards.ts';
import { ruleTemplate } from '../spec/rules.ts';

export { hazardPaths };
import type { StepSpec } from '../spec/steps.ts';

export interface AlternativesResult {
  results: Array<{ k: number; result: AuthorResult }>;
}

export async function authorAlternatives(
  ctx: AgentContext,
  step: StepSpec,
  layer: Layer,
  count: number,
): Promise<AlternativesResult> {
  const functionLayer = readFileSync(ctx.layout.fragmentPath(layer), 'utf8');
  const results: Array<{ k: number; result: AuthorResult }> = [];
  // A layer evaluated before carries the earlier trade-off record; the
  // alternatives are built on the function layer, not on the last decision.
  const head = stripPlaceholder(
    withoutTradeOff(functionLayer, layer).replace(/\s*\}\s*$/, ''),
    layer,
    ctx.state.brief?.systemName ?? ctx.layout.root,
  );
  // The functions the section has to allocate, by name, off the head itself.
  // Tags first: a carried `#Coordination action x` is a function like any other,
  // and a regex that required `action` at the start of the line never saw it.
  const functionNames = [...head.matchAll(/^\s*(?:#[\w']+\s+)*action\s+([A-Za-z_][A-Za-z0-9_]*)\s*[:;{]/gm)].map((m) => m[1]);
  // What the head already allocates — an actor's activities — is not the
  // section's to allocate. v7's prompt said "exactly 28" of which 9 were the
  // actors'; both PA alternatives allocated the 13 tagged ones and dropped the
  // 6 untagged system functions.
  const alreadyAllocated = new Set([...head.matchAll(/^\s*allocate\s+([A-Za-z_][A-Za-z0-9_]*)\s+to\b/gm)].map((m) => m[1]));
  const toAllocate = functionNames.filter((f) => !alreadyAllocated.has(f));
  const taggedIn = (tag: string): string[] =>
    [...head.matchAll(/^\s*((?:#[\w']+\s+)+)action\s+([A-Za-z_][A-Za-z0-9_]*)/gm)]
      .filter((m) => m[1].split(/\s+/).includes(`#${tag}`))
      .map((m) => m[2]);
  const population = ctx.state.brief?.population;
  const coordinationNames = taggedIn('Coordination');
  const c2Names = taggedIn('C2');
  // The hazards the head states. Stripping the placeholder took its satisfy
  // lines with it, so each of these is unmitigated until the section names
  // which component mitigates it — which is the point.
  // The hazards the gate reads: every one stated from SA down to this layer,
  // not only this layer's. Measured on v5: the prompt named LA's eight while
  // requirements.hazardsByComponent also demanded SA's five, a repair round
  // the first answer could not have avoided.
  // Named by their path from the root: the same hazard name is often restated
  // at SA, LA and PA, and `satisfy X by p;` answers only the nearest one
  // (probed on v5: `SA::Hazards::X` clears SA's alone, `Hazards::X` this layer's).
  const hazardNames = ctx.knobs.safety
    ? [
        ...new Set(
          (['SA', 'LA', 'PA'] as Layer[])
            .filter((l) => layerIndex(l) < layerIndex(layer))
            .map((l) => (existsSync(ctx.layout.fragmentPath(l)) ? readFileSync(ctx.layout.fragmentPath(l), 'utf8') : ''))
            .concat(head)
            .flatMap(hazardPaths),
        ),
      ]
    : [];

  // The LLM calls can overlap — the client has its own concurrency limit — but
  // every check inside them queues behind the one Sysprose process this host
  // allows. Running them together is what makes the wait the longest call
  // rather than the sum of them.
  const runs = Array.from({ length: count }, (_, i) => i + 1).map(async (k) => {
    // The function layer is the orchestrator's, and it is the same for every
    // alternative: the model is asked for the components section only, and
    // every answer — first or repaired — is spliced onto the pristine head.
    // Measured, twice, before this: asked to keep the functions and their
    // realization links, the model rewrote the layer and dropped every trace.
    const marker = `        // ── architecture, alternative ${k} ──`;
    const result = await authorLayer(ctx, {
      step,
      layer,
      alternative: k,
      alternatives: count,
      skeleton: functionLayer,
      compose: {
        schema: ComponentsOutputSchema,
        // Asked for its components alone, the model returned the whole layer:
        // 84 actions, 110 traces, and 188 duplicate names once glued onto the
        // head. Whatever comes back, only what the head does not already
        // declare is kept — by name, and for relationships by text.
        build: (section) => {
          // The raw answer, kept beside the packet: when a composed fragment
          // fails to parse, the question is always what the model wrote
          // versus what was done to it, and the fragment on disk is the latter.
          const dir = ctx.layout.auditDirFor(step.id);
          mkdirSync(dir, { recursive: true });
          writeFileSync(resolve(dir, `alt-${k}.raw-section.${Date.now()}.txt`), section);
          const composed = composeSection(head, section, { root: ctx.layout.root, functions: functionNames, marker });
          for (const note of composed.notes) ctx.log(`    ${step.id} alt-${k}: ${note}`);
          return composed.fragment;
        },
        // A repaired fragment comes back whole. The marker, when the model
        // kept it, says where the section starts; when it did not — models
        // drop comments — the whole layer body is taken and `build` drops, by
        // name, everything the head already declares. Measured: a repair
        // without the marker, unwrapped by a regex that missed, glued the
        // whole layer onto the head and put 184 duplicate names at the root.
        extract: (fragment) => {
          // Indentation-insensitive: the model re-indents comments it keeps.
          const needle = marker.trim();
          const at = fragment.indexOf(needle);
          if (at >= 0) {
            const additions = nestedAdditions(head, fragment.slice(0, at), layer);
            const section = fragment.slice(at + needle.length).replace(/\s*\}\s*$/, '');
            return additions ? `${section}\n${additions}` : section;
          }
          return packageBody(fragment, layer)?.body ?? fragment;
        },
      },
      extra: [
        [
          'The fragment above is this layer\'s function layer. It is fixed, it is the SAME for every alternative, and it is added around your answer — do not repeat any of it.',
          'Return ONLY the declarations of your architecture: the part definitions and parts, their ports, the connections between them, their state definitions, and one `allocate <function> to <part>;` for every function in the fragment above.',
          // Measured: a first answer allocated 11 of 21 functions and spent a
          // repair round on the other ten. The count is known; say it.
          `There are exactly ${toAllocate.length} functions to allocate: ${toAllocate.join(', ')}${
            coordinationNames.length + c2Names.length > 0
              ? ` — the coordination and command-and-control ones AND every other one: ${toAllocate.filter((f) => !coordinationNames.includes(f) && !c2Names.includes(f)).map((f) => `\`${f}\``).join(', ') || 'none'}`
              : ''
          }. Your section is not complete until each of them appears in an \`allocate\` line — write those ${toAllocate.length} lines first, then the rest. Write each by its bare name, \`allocate <function> to <part>;\`: a path such as \`${ctx.layout.root}::${previousAuthoredLayer(layer) ?? 'SA'}::<function>\` names the layer above's function, allocates nothing here, and blocks (measured in v6: all 13 of one PA alternative's functions).`,
          `Alternative ${k} must be a genuinely different split of responsibilities from the others — different boundaries, not different names.`,
          // Measured: ten connections per alternative joined a component's `in`
          // port to the system's `in` port one layer up — a delegation, which
          // this dialect reports as incompatible. Connections stay in the layer.
          'Connections stay inside this layer: between your components, and between a component and an actor part of this layer. Never connect to a port of the layer above (`SA::system::…`): that is a delegation, and it is expressed by the allocation and the trace, not by a connection. A connection joins an `out` port to an `in` port.',
          ...(population ? populationGuidance(k, layer, population, coordinationNames, c2Names) : []),
          ...estimateGuidance(scoredMoes(ctx.state.brief?.moes ?? [])),
          ...briefFixedGuidance(ctx.state.brief, population !== undefined),
          ...(hazardNames.length > 0
            ? [
                `The layers so far state ${hazardNames.length} hazard(s) a component must answer: ${hazardNames.map((n) => `\`${n}\``).join(', ')}. Each must be mitigated by one of YOUR components — write \`satisfy <that path> by <your part>;\` for every one, with the path exactly as listed, and never restate one of them in your section (a restated hazard blocks); a satisfy by a function alone does not count, because every alternative shares the functions. Or tag the hazard \`#Accepted\` with the reason in its doc; accepting costs this alternative score. A hazard no component mitigates blocks the alternative.`,
              ]
            : []),
        ].join(' '),
      ],
    });
    return { k, result };
  });

  for (const settled of await Promise.all(runs)) results.push(settled);
  results.sort((a, b) => a.k - b.k);
  return { results };
}

/**
 * Take the placeholder out of the head: its definition, its usage, its trace,
 * and every allocation to it. What is left is the function layer with every
 * function unallocated — which is exactly the gate the section has to clear.
 */
export function stripPlaceholder(head: string, layer: Layer, systemName: string): string {
  const ph = PLACEHOLDER[layer];
  if (!ph) return head;
  // The DEFINITION stays. It is the type of the system as a whole — the
  // author hangs system-level requirements on it (`subject sys : <System>Logical`)
  // and an alternative's components may specialise it — and the orphan gate
  // exempts it by name. What goes is the USAGE, `part mainComponent`, and
  // every statement that names it: its trace, the allocations, the satisfies
  // and connections the author hung on it. Measured: with the definition
  // removed, two requirements in the head lost their subject type, and no
  // alternative can repair a head.
  let out = head.endsWith('\n') ? head : `${head}\n`;
  const usage = new RegExp(`^[ \\t]*part ${ph.usage}\\s*:[^\\n]*`, 'm');
  for (let guard = 0; guard < 5; guard += 1) {
    const u = usage.exec(out);
    if (!u) break;
    let end = u.index + u[0].length;
    const brace = u[0].indexOf('{');
    if (brace >= 0) {
      const close = matchingBrace(out, u.index + brace);
      if (close >= 0) end = close + 1;
    }
    const lineEnd = out.indexOf('\n', end);
    out = out.slice(0, u.index) + out.slice(lineEnd < 0 ? out.length : lineEnd + 1);
  }
  // The carried member definition is a placeholder too. An architecture wires
  // ports onto its members that the stub does not have, and a section that
  // redeclares the definition with them would be dropped as a duplicate of the
  // stub — so the stub goes and the section writes the definition in full.
  const member = /^[ \t]*#Member\s+part\s+def\s+[A-Za-z_][A-Za-z0-9_]*\s*\{/m;
  for (let guard = 0; guard < 5; guard += 1) {
    const m = member.exec(out);
    if (!m) break;
    const close = matchingBrace(out, m.index + m[0].length - 1);
    if (close < 0) break;
    const lineEnd = out.indexOf('\n', close);
    out = out.slice(0, m.index) + out.slice(lineEnd < 0 ? out.length : lineEnd + 1);
  }
  const parts = packageBody(`${out}\n}`);
  if (parts) {
    const word = new RegExp(`\\b${ph.usage}\\b`);
    const kept = splitStatements(parts.body).filter(
      (st) => !word.test(st.replace(/\/\*[\s\S]*?\*\//g, '').replace(/\/\/[^\n]*/g, '')),
    );
    out = `${parts.head}${kept.join('')}`;
  }
  return out;
}

/** The section sits one level inside the layer package. */
export function indent(section: string): string {
  const lines = section.replace(/\r\n/g, '\n').split('\n');
  const leads = lines.filter((l) => l.trim() !== '').map((l) => (/^(\s*)/.exec(l)?.[1].length ?? 0));
  const strip = leads.length > 0 ? Math.min(...leads) : 0;
  return lines.map((l) => (l.trim() === '' ? '' : `        ${l.slice(strip)}`)).join('\n');
}

/**
 * What an alternative must write when the system is a population, and which
 * side of the command-and-control decision it takes.
 *
 * Left to themselves, both architectures of the third run put every decision
 * at the ground station and the trade-off compared two stars. The decision the
 * brief asks for exists only if one alternative is built on each side of it,
 * so the side is assigned, and alt.c2Placement checks it was taken.
 */
/**
 * Every architecture states what it achieves on each measure (CV-17).
 *
 * The trade-off scores these at the measures weight, and the author of the
 * architecture is the one stating them — so the prompt asks for the worst case
 * and its basis, and says that a restated target is not an estimate. The
 * evaluator sees both alternatives' bases side by side.
 */
export function estimateGuidance(moes: readonly Moe[]): string[] {
  if (moes.length === 0) return [];
  return [
    `State this architecture's estimate for each of the ${moes.length} measures of effectiveness. The measures and their targets: ${moes.map((m) => `\`${m.name}\` ${boundText(m)}`).join(', ')}. Where the brief fixes the numbers a measure follows from (fleet size, flight and recharge time, sectors), DERIVE it so the solver checks the arithmetic: restate those numbers as attributes of this layer — \`attribute dronesFielded : ScalarValues::Real = 12;\` (a constraint cannot read \`Common::\`; where the brief's number is itself one of the measures, its literal \`#Estimate\` is that input — declare it once, never beside a plain attribute of the same name) — then \`#Estimate attribute <measure> :> Common::<measure> { doc /* the basis */ }\` with no value and \`assert constraint { doc /* what it computes */ <measure> == <expression over those attributes> }\` — the doc is what a reviewer reads, and an undocumented constraint counts against the layer's doc coverage. Where nothing derives it, state the literal: \`${estimateLine('<measure>')}\`. Either way the value is the WORST case this design delivers, not the target restated, with its basis in the doc. An estimate that misses its target is a legitimate answer — the comparison is what it is for.`,
  ];
}

/**
 * An alternative's section, composed onto the head it was written against:
 * path allocations localised, braces balanced, nested packages merged into the
 * head's, and everything the head already declares dropped. Pure, so a raw
 * answer kept in a packet can be recomposed offline with today's rules.
 */
export function composeSection(
  head: string,
  section: string,
  opts: { root: string; functions: readonly string[]; marker: string },
): { fragment: string; notes: string[] } {
  const notes: string[] = [];
  const localised = bareAllocations(section, opts.root, opts.functions);
  if (localised.count > 0) notes.push(`${localised.count} allocation(s) named another layer's function by path; rewritten to this layer's`);
  const balanced = balanceBraces(localised.text);
  if (balanced.dropped + balanced.appended > 0) notes.push(`balanced the section (${balanced.dropped} stray closing, ${balanced.appended} missing)`);
  // A package the head already has (Hazards, say) takes the section's body
  // inside it rather than being repeated or dropped.
  const unwrapped = unwrapWholePackage(balanced.text) ?? balanced.text;
  const joined = mergeNestedPackages(head, unwrapped);
  if (joined.merged.length > 0) notes.push(`merged ${joined.merged.join(', ')} into the layer's own package(s)`);
  const { kept, dropped } = withoutDuplicates(joined.head, joined.section);
  if (dropped.length > 0) notes.push(`dropped ${dropped.length} statement(s) the function layer already has`);
  return { fragment: `${joined.head}\n\n${opts.marker}\n${indent(kept)}\n    }\n`, notes };
}

/**
 * `allocate Root::LA::x to p;` → `allocate x to p;` when `x` is a function of
 * this layer. The path names the layer above's function, so the allocation
 * lands there and this layer's `x` reads unallocated: v6 lost all 13 of one PA
 * alternative's functions to it, and v7 19 more after the prompt said not to.
 * A function this layer does not have is left as written — that path is
 * deliberate or wrong in a way a person should see.
 */
export function bareAllocations(section: string, root: string, functions: readonly string[]): { text: string; count: number } {
  const known = new Set(functions);
  let count = 0;
  const text = section.replace(
    new RegExp(`\\ballocate\\s+${root}::(?:OA|SA|LA|PA)::([A-Za-z_][A-Za-z0-9_]*)(\\s+to\\b)`, 'g'),
    (whole, name: string, to: string) => {
      // v7's PA alternative named the layer above's action DEFINITIONS
      // (`LA::HandOverSector`); the function here is the usage, `handOverSector`.
      const local = known.has(name) ? name : known.has(name.replace(/^[A-Z]/, (c) => c.toLowerCase())) ? name.replace(/^[A-Z]/, (c) => c.toLowerCase()) : undefined;
      if (!local) return whole;
      count += 1;
      return `allocate ${local}${to}`;
    },
  );
  return { text, count };
}

/**
 * What the brief fixed by name, for an alternative's author: the modes and the
 * rules live on machines the section declares — the member's included, since
 * the head's member stub is replaced — and the component that enforces the
 * rules is not the one that detects.
 */
export function briefFixedGuidance(brief: AgentContext['state']['brief'], hasPopulation: boolean): string[] {
  const modes = brief?.modes ?? [];
  const rules = brief?.rules ?? [];
  const owner = (of: string): string => (!hasPopulation || of === 'system' ? 'the system component' : of === 'member' ? 'the #Member part def' : of === 'fleet' ? 'the fleet usage or a #Configuration machine' : 'a ground component');
  const out: string[] = [];
  if (modes.length > 0)
    out.push(`The brief's modes are states of your components' machines, under exactly these names: ${modes.map((m) => `\`${m.name}\` on ${owner(m.of)}`).join('; ')}. Each needs a transition into it and one out.`);
  if (rules.length > 0)
    out.push(
      `The rules the system never breaks are carried on those machines as checked properties, the doc naming the rule: ${rules.map((r) => `\`${r.name}\` on ${owner(r.of)} — \`${ruleTemplate(r.name, r.kind)}\``).join('; ')}. A rule a run can break blocks this alternative with that run. The satisfy is inherited: \`#Rule requirement\` is stated at SA only. Enforce the rules in a component of their own — a monitor that overrides the rest — not in the component that detects, classifies or decides what to report, and say in its doc what it overrides; the evaluation weighs that.`,
    );
  return out;
}

export function populationGuidance(
  k: number,
  layer: Layer,
  p: NonNullable<AgentContext['state']['brief']>['population'] & object,
  coordination: string[],
  c2: string[],
): string[] {
  const list = (names: string[]): string => (names.length > 0 ? names.map((n) => `\`${n}\``).join(', ') : 'none tagged yet');
  const link =
    layer === 'PA'
      ? `a connection between them typed by the connection def of the medium that carries it — \`connection peerLink : <Medium>Link connect memberA.meshOut to memberB.meshIn;\` — with the radio that carries it as a \`#Node\` part, not an actor`
      : `\`interface peerLink : Common::${p.meshInterface} connect memberA.meshOut to memberB.meshIn;\``;
  const lines = [
    `The system is a population of ${p.size} identical members (CV-16). Whatever else this architecture does, write: \`#Member part def ${p.memberDef} { out port meshOut : Common::${p.meshPort}; in port meshIn : ~Common::${p.meshPort}; }\` — declare it in full in your section, with meshOut and meshIn plus every other port your architecture connects to a member; the stub in the layer above is removed before your section is added, \`part ${p.fleetPart} : ${p.memberDef} [${p.size}];\`, two representatives \`part memberA : ${p.memberDef};\` and \`part memberB : ${p.memberDef};\`, and ${link}. A function every member performs is allocated to \`${p.fleetPart}\`; one a member performs for the others goes to \`memberA\` or \`memberB\`. An indexed end like \`${p.fleetPart}[1]\` does not parse.`,
    `Coordination between members (#Coordination): ${list(coordination)}. Command and control (#C2): ${list(c2)}. Where these are allocated is the decision this comparison is about, and it is measured.`,
  ];
  if (k === 1) {
    lines.push(
      'This alternative is the GROUND-CENTRIC design. Every #C2 function, and every #Coordination function that decides — who holds which sector, who recharges next, how coverage is re-spread — is allocated to a ground component. Members use the mesh to relay and to keep apart, and execute what they are assigned. In the ground component\'s doc, say what stops when the link to the members drops and what happens when the ground node itself fails.',
    );
  } else if (k === 2) {
    lines.push(
      `This alternative is the DISTRIBUTED design. At least half of the #Coordination functions are allocated to \`memberA\`, \`memberB\` or \`${p.fleetPart}\` — an elected or rotating coordinator, or negotiation over the mesh. Command and control stays with the operator: every #C2 function keeps a usage allocated to a ground component — tasking and the status picture are held on the ground, and a member may carry its own usage too (recall and land must reach every member). No ground component holds a coordination assignment the members cannot rebuild. In the member definition\'s doc, say how a coordinator is chosen and replaced, and what the swarm keeps doing when the ground link drops and when the ground node fails.`,
    );
  }
  return lines;
}
