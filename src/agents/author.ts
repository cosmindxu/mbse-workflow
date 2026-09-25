/**
 * The author of one layer, and the repair loop that follows it.
 *
 * The two are one file because they are one conversation with the model: write,
 * be told what the checker found, write again. The loop is bounded — after
 * `repair_iterations` the step is blocked and a gate opens, because an agent
 * that has failed three times on the same diagnostic will fail a fourth, and
 * the person waiting deserves to be told rather than billed.
 */
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { summarise } from '../audit/packet.ts';
import { runStepChecks, type CheckContext, type Verdict } from '../check/checker.ts';
import { preflight, insertBeforeClose } from '../model/fragments.ts';
import { assemble } from '../model/assembler.ts';
import { hazardNamesAbove } from '../model/hazards.ts';
import { buildSystemPrompt } from '../prompts/system.ts';
import { buildUserPrompt, guidanceFrom, type AuthorContext } from '../prompts/context.ts';
import { ComponentsOutputSchema, FragmentOutputSchema, RepairOutputSchema, type SeedOutput } from '../llm/schemas.ts';
import { previousAuthoredLayer, type Layer } from '../spec/layers.ts';
import type { StepSpec } from '../spec/steps.ts';
import { modelFor } from '../config/load.ts';
import type { RepairItem } from '../check/classify.ts';
import type { BriefFacts } from '../check/predicates.ts';
import { dedupePackage, matchingBrace } from '../model/statements.ts';
import type { AgentContext } from './context.ts';

export interface AuthorOptions {
  step: StepSpec;
  layer: Layer;
  /** Generated starting point from the transition, when there is one. */
  skeleton?: string;
  /** Comments a reviewer left. */
  reviewerComments?: string[];
  alternative?: number;
  alternatives?: number;
  /** Extra sections for the prompt — what the other alternatives look like, say. */
  extra?: string[];
  /** Write here instead of the layer's own fragment (an alternative). */
  fragmentPath?: string;
  /**
   * Ask for a section rather than a whole fragment, and build the fragment
   * around it. Applied to the first answer and to every repair, so a part of
   * the layer the model is not allowed to change cannot be lost by a rewrite.
   */
  compose?: {
    schema: typeof ComponentsOutputSchema;
    build: (section: string) => string;
    /** Recover the section from a repaired whole fragment. */
    extract: (fragment: string) => string;
  };
}

export interface AuthorResult {
  verdict: Verdict;
  iterations: number;
  fragmentPath: string;
  rationales: string[];
  todos: string[];
  blocked: boolean;
}

/** Write the layer, then repair it until it clears or the budget runs out. */
export async function authorLayer(ctx: AgentContext, opts: AuthorOptions): Promise<AuthorResult> {
  const { step, layer } = opts;
  const fragmentPath = opts.fragmentPath ?? ctx.layout.fragmentPath(layer, opts.alternative);
  const system = buildSystemPrompt({
    step,
    knobs: ctx.knobs,
    root: ctx.layout.root,
    alternative: opts.alternative,
    alternatives: opts.alternatives,
  });

  const context = await gatherContext(ctx, opts);
  const tag = `${step.id}:AUTHOR${opts.alternative === undefined ? '' : `:alt-${opts.alternative}`}`;
  const guard = (fragment: string): string => {
    if (!opts.skeleton || opts.compose) return fragment;
    const { text, restored } = restoreCarriedLinks(opts.skeleton, fragment);
    if (restored.length > 0) ctx.log(`    ${step.id}: restored ${restored.length} carried link(s) the answer dropped`);
    return text;
  };
  const user = buildUserPrompt(context, { maxChars: ctx.config.limits.prompt_max_chars, maxElementLines: 400 });
  const rationales: string[] = [];
  const todos: string[] = [];
  if (opts.compose) {
    const answer = await ctx.llm.complete({
      tag,
      system,
      user,
      schema: opts.compose.schema,
      model: modelFor(ctx.config, 'AUTHOR'),
      timeoutMs: ctx.config.limits.llm_call_timeout_ms,
    });
    rationales.push(answer.data.rationale);
    todos.push(...answer.data.todos);
    await writeFragment(ctx, fragmentPath, layer, opts.compose.build(answer.data.declarations), answer.data.commonAdditions);
  } else {
    const answer = await ctx.llm.complete({
      tag,
      system,
      user,
      schema: FragmentOutputSchema,
      model: modelFor(ctx.config, 'AUTHOR'),
      timeoutMs: ctx.config.limits.llm_call_timeout_ms,
    });
    rationales.push(answer.data.rationale);
    todos.push(...answer.data.todos);
    await writeFragment(ctx, fragmentPath, layer, guard(answer.data.fragment), answer.data.commonAdditions);
  }

  const repaired = await repairFragment(ctx, {
    tag,
    system,
    layer,
    fragmentPath,
    verdict: await check(ctx, opts, fragmentPath),
    recheck: () => check(ctx, opts, fragmentPath),
    label: `${step.id}${opts.alternative === undefined ? '' : ` alt-${opts.alternative}`}`,
    splice: opts.compose ? (fragment) => opts.compose!.build(opts.compose!.extract(fragment)) : guard,
    guidance: [...step.postconditions, ...(opts.extra ?? [])],
  });
  rationales.push(...repaired.rationales);

  return {
    verdict: repaired.verdict,
    iterations: repaired.iterations,
    fragmentPath,
    rationales,
    todos,
    blocked: repaired.verdict.blocking,
  };
}

export interface RepairOptions {
  tag: string;
  system: string;
  layer: Layer;
  fragmentPath: string;
  verdict: Verdict;
  recheck: () => Promise<Verdict>;
  label: string;
  /** Rebuild the fragment around the model's repaired section before it is written. */
  splice?: (fragment: string) => string;
  /**
   * What the first answer was told and the repair must not forget. Measured:
   * a physical alternative went from four findings to ten across a repair,
   * because the repair prompt carried the findings and the fragment and
   * nothing else — not the list of functions to allocate, not the rule that
   * connections stay in-layer.
   */
  guidance?: string[];
}

/**
 * Hand the findings back and check again, up to the budget.
 *
 * Every step that writes a fragment gets this, SEED included: a step whose
 * first answer does not load is not a different kind of problem from one whose
 * third does not, and a step with no repair round is a run that stops on a
 * missing semicolon.
 */
/**
 * The verdict each repair round was asked to fix, kept beside the packet.
 *
 * The packet's verdict.json is the last one; when a step blocks after three
 * rounds, what the first two were about is otherwise gone — the run log keeps
 * counts. Measured: finding out that two of three rounds at S21 went on one
 * inherited diagnostic meant reconstructing it from the check payload's
 * timestamps.
 */
function keepRoundVerdict(verdict: Verdict, round: number): void {
  const payload = verdict.checks.find((c) => c.payloadFile)?.payloadFile;
  if (!payload) return;
  writeFileSync(resolve(dirname(payload), `verdict.repair-${round}.json`), `${JSON.stringify(summarise(verdict), null, 2)}\n`);
}

export async function repairFragment(
  ctx: AgentContext,
  opts: RepairOptions,
): Promise<{ verdict: Verdict; iterations: number; rationales: string[] }> {
  let verdict = opts.verdict;
  let iterations = 0;
  const rationales: string[] = [];
  const stubbed = new Set<string>();
  while (verdict.blocking && iterations < ctx.config.limits.repair_iterations) {
    // Mechanical first: a missing shared type is written by the orchestrator,
    // not asked for again. Only what is left after that costs a model call.
    const stubs = stubMissingCommonTypes(ctx.layout.root, opts.layer, verdict.items).declarations.filter(
      (d) => !stubbed.has(d),
    );
    if (stubs.length > 0) {
      stubs.forEach((d) => stubbed.add(d));
      await addToCommon(ctx, opts.layer, stubs);
      ctx.log(`    ${opts.label}: stubbed ${stubs.length} shared type(s) the layer named and Common lacked`);
      rationales.push(`Orchestrator: ${stubs.length} item definition(s) stubbed in Common, each marked TODO.`);
      verdict = await opts.recheck();
      if (!verdict.blocking) break;
    }
    iterations += 1;
    ctx.log(`    ${opts.label}: repair ${iterations} (${verdict.items.filter((i) => i.blocking).length} blocking)`);
    keepRoundVerdict(verdict, iterations);
    const answer = await ctx.llm.complete({
      tag: `${opts.tag}:repair-${iterations}`,
      system: opts.system,
      user: repairPrompt(readFileSync(opts.fragmentPath, 'utf8'), verdict.items, opts.guidance),
      schema: RepairOutputSchema,
      model: modelFor(ctx.config, 'REPAIR'),
      timeoutMs: ctx.config.limits.llm_call_timeout_ms,
    });
    rationales.push(answer.data.rationale);
    // A repair may need a shared definition that is not there: an unresolved
    // `Common::X` is otherwise only fixable by deleting the reference, which
    // loses the thing the author was trying to say.
    const before = hazardNamesIn(readFileSync(opts.fragmentPath, 'utf8'));
    const text = opts.splice ? opts.splice(answer.data.fragment) : answer.data.fragment;
    await writeFragment(ctx, opts.fragmentPath, opts.layer, text, answer.data.commonAdditions ?? []);
    verdict = withDroppedHazards(await opts.recheck(), before, hazardNamesIn(readFileSync(opts.fragmentPath, 'utf8')), hazardNamesAbove(ctx.layout, opts.layer));
  }
  return { verdict, iterations, rationales };
}

/** Every `#Hazard … requirement <name>` a fragment states, whatever else it is tagged. */
export function hazardNamesIn(fragment: string): Set<string> {
  return new Set([...fragment.matchAll(/#Hazard\b[^\n;{]*?\brequirement\s+(?:def\s+)?([A-Za-z_][A-Za-z0-9_]*)/g)].map((m) => m[1]));
}

/**
 * A repair may not make a hazard disappear.
 *
 * The hazard gates ask that every hazard STATED be mitigated, so the cheapest
 * way to clear one under repair pressure is to delete it — and the gate goes
 * quiet. A name the fragment stated before a repair and not after is put back
 * in front of the model as a blocking item of its own.
 */
export function withDroppedHazards(verdict: Verdict, before: Set<string>, after: Set<string>, statedAbove: ReadonlySet<string> = new Set()): Verdict {
  // A restated hazard removed under repair is the refinement
  // `hazards.notRestated` asked for, not a deletion: the layer above still
  // states it. Without this the two gates demanded opposite things.
  const dropped = [...before].filter((name) => !after.has(name) && !statedAbove.has(name));
  if (dropped.length === 0) return verdict;
  const items: RepairItem[] = dropped.map((name) => ({
    source: 'predicate',
    code: 'hazards.kept',
    severity: 'error',
    blocking: true,
    cv: 'CV-09',
    message: `the repair removed the hazard \`${name}\`. A hazard is not fixed by deleting it: put it back, and satisfy it with the component that mitigates it or tag it \`#Accepted\` with the reason in its doc.`,
  }));
  return { ...verdict, blocking: true, items: [...verdict.items, ...items] };
}

/** Hoist the contents of every `package <Layer>Shared { … }` into Common itself. */
export function flattenSharedPackages(common: string): string {
  const open = /^([ \t]*)package (\w+)Shared\s*\{[ \t]*\n/m;
  let out = common;
  for (let guard = 0; guard < 20; guard += 1) {
    const m = open.exec(out);
    if (!m) break;
    const close = matchingBrace(out, out.indexOf('{', m.index));
    if (close < 0) break;
    const body = out
      .slice(m.index + m[0].length, close)
      .split('\n')
      .map((l) => (l.startsWith('    ') ? l.slice(4) : l))
      .join('\n')
      .replace(/\s+$/, '');
    const lineEnd = out.indexOf('\n', close);
    out =
      `${out.slice(0, m.index)}${m[1]}// ── shared definitions asked for by ${m[2]} (hoisted) ──\n${body}\n` +
      out.slice(lineEnd < 0 ? out.length : lineEnd + 1);
  }
  return out;
}

/**
 * What the skeleton carried, the answer keeps.
 *
 * Measured, at every authoring step that starts from a generated skeleton: the
 * model rewrites the layer and drops the `trace <fn> to <above>::<fn>;` lines
 * — 46 links to zero — even when each missing one is named in the repair
 * prompt. The links are not the model's to decide: they are the record of
 * where each function came from, and the transition wrote them. So for every
 * function the skeleton traced or allocated that still exists in the answer,
 * the line is put back if it is missing. Nothing is added for a function the
 * author removed; that is a decision, and the gates judge it.
 */
export function restoreCarriedLinks(skeleton: string, answer: string): { text: string; restored: string[] } {
  // Tags first: `#Coordination action handOverSector` is a function whose trace
  // and allocation are as much the transition's as any other.
  const functions = new Set([...answer.matchAll(/^\s*(?:#[\w']+\s+)*action\s+([A-Za-z_][A-Za-z0-9_]*)\s*[:;{]/gm)].map((m) => m[1]));
  const carried = [...skeleton.matchAll(/^\s*((?:trace|allocate)\s+([A-Za-z_][A-Za-z0-9_]*)\s+to\s+[^;\n]+;)/gm)]
    .map((m) => ({ line: m[1].trim(), subject: m[2] }))
    .filter((c) => functions.has(c.subject));
  const normalise = (l: string): string => l.replace(/\s+/g, ' ').trim();
  const present = new Set(answer.split('\n').map(normalise));
  const restored = carried.map((c) => c.line).filter((line) => !present.has(normalise(line)));
  if (restored.length === 0) return { text: answer, restored };
  const block = ['// carried from the layer above; restored by the orchestrator', ...restored].join('\n');
  return { text: insertBeforeClose(answer, block), restored };
}

/**
 * A type the layer names and Common lacks gets a stub, marked TODO.
 *
 * Measured: told twice, by name, that `Common::AreaActivity` did not resolve
 * and to return the declaration in commonAdditions, the repair returned other
 * declarations and the count of unresolved types did not move. This is the
 * one error class where the fix is fully determined by the diagnostic — the
 * name, and where it belongs — so the orchestrator writes it, marks it, and
 * the final audit lists every stub a person still has to describe. Nothing is
 * invented: an empty item definition with a TODO is the honest record that
 * the layer needed a type nobody has defined yet.
 */
export function stubMissingCommonTypes(
  root: string,
  layer: Layer,
  items: RepairItem[],
): { names: string[]; declarations: string[] } {
  const pattern = new RegExp(`\\b${root}::Common::([A-Za-z_][A-Za-z0-9_]*)\\b`);
  const names = [
    ...new Set(
      items
        .filter((i) => i.blocking && /unresolved-type/.test(i.code))
        .map((i) => pattern.exec(i.message)?.[1])
        .filter((n): n is string => n !== undefined),
    ),
  ];
  return {
    names,
    declarations: names.map(
      (n) => `item def ${n} { doc /* TODO: introduced by ${layer}, not yet described — say what this is and who produces it. */ }`,
    ),
  };
}

/** Put a reviewer's words into the model, where the next agent will read them. */
export function recordReviewerComment(fragmentPath: string, layer: Layer, comment: string, index: number): void {
  if (!existsSync(fragmentPath)) return;
  const fragment = readFileSync(fragmentPath, 'utf8');
  const block = [
    `#prompt part reviewerComment${index} {`,
    `    doc /* A reviewer asked for this at the ${layer} gate: ${comment.replace(/\*\//g, '* /')} */`,
    '}',
  ].join('\n');
  writeFileSync(fragmentPath, insertBeforeClose(fragment, block));
}

/* ────────────────────────────── internals ───────────────────────────────── */

async function writeFragment(
  ctx: AgentContext,
  fragmentPath: string,
  layer: Layer,
  text: string,
  commonAdditions: string[],
): Promise<void> {
  const checked = preflight(text, layer, { root: ctx.layout.root });
  writeFileSync(fragmentPath, checked.fragment);
  if (commonAdditions.length > 0) await addToCommon(ctx, layer, commonAdditions);
}

/**
 * Shared definitions go to Common, not into the layer that noticed them.
 *
 * A layer that declares its own copy of an item is a layer whose flows will not
 * connect to anyone else's. They land in a nested package named after the layer
 * that asked, so a reader can see who wanted what.
 */
/**
 * Common is written by several agents, and two alternatives finish their calls
 * close enough together to read it, both add the same declaration, and both
 * write. The read, the merge and the write are one critical section.
 */
let commonLock: Promise<void> = Promise.resolve();

function addToCommon(ctx: AgentContext, layer: Layer, additions: string[]): Promise<void> {
  const run = async (): Promise<void> => {
    const path = ctx.layout.fragmentPath('Common');
    if (!existsSync(path)) return;
    writeFileSync(path, mergeIntoShared(readFileSync(path, 'utf8'), layer, additions));
  };
  const next = commonLock.then(run, run);
  commonLock = next.then(
    () => undefined,
    () => undefined,
  );
  return next;
}

/**
 * Shared declarations go into `package Common` itself — flat.
 *
 * They were nested in a `package <Layer>Shared` for provenance, and that is
 * exactly what stopped every repair from converging: the model writes
 * `Common::AreaActivity`, the declaration landed at
 * `Common::LAShared::AreaActivity`, and the reference stayed unresolved through
 * three rounds while the declaration it needed sat one package too deep.
 * Provenance is a comment now. A declaration whose name Common already has,
 * anywhere in it, is not written twice — `item def X;` and `item def X { doc }`
 * are one declaration to the checker, and the second is a duplicate-name error
 * no repair can remove.
 */
const DECLARED_NAME =
  /\b(?:item|attribute|port|interface|enum|part|action|connection|metadata|occurrence|requirement|state|calc|constraint)\s+def\s+([A-Za-z_][A-Za-z0-9_]*)/g;

export function mergeIntoShared(common: string, layer: Layer, additions: string[]): string {
  // Anything an earlier version nested in `package <Layer>Shared` is hoisted
  // first: a declaration at Common::LAShared::X satisfies a name check and
  // resolves nothing a layer writes as Common::X. Measured: nine stubs were
  // skipped as "already declared" while the references stayed unresolved.
  common = dedupePackage(flattenSharedPackages(common), 'Common').text;
  const wanted = additions.map((d) => d.trim()).filter(Boolean);
  if (wanted.length === 0) return common;
  const declared = new Set([...common.matchAll(DECLARED_NAME)].map((m) => m[1]));
  const fresh = wanted.filter((d) => {
    const name = new RegExp(DECLARED_NAME.source).exec(d)?.[1];
    if (name === undefined) return !common.includes(d);
    if (declared.has(name)) return false;
    declared.add(name);
    return true;
  });
  if (fresh.length === 0) return common;
  const block = [`// ── shared definitions asked for by ${layer} ──`, ...fresh].join('\n');
  return insertBeforeClose(common, block);
}

async function check(ctx: AgentContext, opts: AuthorOptions, fragmentPath: string): Promise<Verdict> {
  const context: CheckContext = {
    backend: ctx.backend,
    layout: ctx.layout,
    knobs: ctx.knobs,
    brief: briefFacts(ctx),
    docCoverageMin: ctx.config.limits.doc_coverage_min,
    // Each alternative keeps its own payloads. Measured: two alternatives
    // checked in the same step wrote the same `check.json`, and the one read
    // afterwards belonged to whichever finished last.
    auditDir:
      opts.alternative === undefined
        ? ctx.layout.auditDirFor(opts.step.id)
        : resolve(ctx.layout.auditDirFor(opts.step.id), `alt-${opts.alternative}`),
    alternative: opts.alternative,
  };
  if (opts.alternative !== undefined) {
    context.substitute = { [opts.layer]: readFileSync(fragmentPath, 'utf8') };
  }
  return runStepChecks(opts.step, context);
}

export function briefFacts(ctx: AgentContext): BriefFacts | undefined {
  return ctx.state.brief ? briefFactsOf(ctx.state.brief) : undefined;
}

/** What the gates read from the brief. One function, so the run and `check` agree. */
export function briefFactsOf(brief: SeedOutput): BriefFacts {
  // A brief written before the population lane existed has none of these.
  const population = brief.population;
  return {
    systemName: brief.systemName,
    aliases: [brief.systemName.replace(/([a-z])([A-Z])/g, '$1 $2')],
    // A budget is a number the brief fixes: held by a requirement, not estimated or scored.
    moes: brief.moes.filter((m) => m.kind !== 'budget').map((m) => m.name),
    // The same measures with their numbers, for checks that compare an
    // estimate against what the brief's own budgets allow.
    measures: brief.moes
      .filter((m) => m.kind !== 'budget')
      .map((m) => ({ name: m.name, sense: m.sense, target: m.target, unit: m.unit, doc: m.doc })),
    budgets: Object.fromEntries(
      brief.moes
        .filter((m) => m.kind === 'budget' && typeof m.target === 'number')
        .map((m) => [m.name, m.target as number]),
    ),
    capabilities: brief.capabilities.map((c) => c.name),
    systemEntity: brief.systemEntity,
    population: population
      ? {
          memberDef: population.memberDef,
          fleetPart: population.fleetPart,
          size: population.size,
          meshPort: population.meshPort,
          meshInterface: population.meshInterface,
          coordinationCapability: population.coordinationCapability,
          bearer: population.bearer,
        }
      : undefined,
    coordinationFunctions: (brief.coordinationFunctions ?? []).map((f) => f.name),
    c2Functions: (brief.c2Functions ?? []).map((f) => f.name),
    hazards: (brief.hazards ?? []).map((h) => h.name),
    rules: (brief.rules ?? []).map((r) => ({ name: r.name, kind: r.kind, of: r.of })),
    modes: (brief.modes ?? []).map((m) => ({ name: m.name, of: m.of })),
    items: (brief.items ?? []).map((i) => ({ name: i.name, fields: i.fields.map((f) => f.name) })),
  };
}

async function gatherContext(ctx: AgentContext, opts: AuthorOptions): Promise<AuthorContext> {
  const above = previousAuthoredLayer(opts.layer);
  const assembly = assemble(ctx.layout, opts.layer);
  const context: AuthorContext = {
    brief: ctx.state.brief,
    layer: opts.layer,
    root: ctx.layout.root,
    skeleton: opts.skeleton,
    guidance: [],
    postconditions: opts.step.postconditions,
    reviewerComments: opts.reviewerComments ?? [],
    extra: opts.extra,
  };
  // One load for everything the prompt needs — the element summary of the layer
  // above, and the guidance the model itself carries for this layer.
  await ctx.backend.withModel(assembly.text, ctx.layout.buildPath(opts.layer), (m) => {
    const elements = ctx.backend.elements(m);
    if (above) context.above = { layer: above, elements };
    const stats = ctx.backend.stats(m);
    if (stats.nodeCount <= ctx.config.limits.full_prefix_max_elements) {
      context.fullPrefix = assembly.text;
    }
    for (const layer of [opts.layer, above].filter(Boolean) as Layer[]) {
      try {
        context.guidance.push(...guidanceFrom(ctx.backend.prompts(m, `${ctx.layout.root}::${layer}`)));
      } catch {
        // No guidance element for that layer yet. Not a problem: the step's own
        // post-conditions are in the prompt either way.
      }
    }
  });
  return context;
}

/**
 * Parse errors first. Measured: three syntax errors in a section made the
 * parser recover by closing the layer early, and ten connections then sat at
 * the root with one resolvable end. Listed by position, the ten came first
 * and the model spent its repair on them; the three that caused them were
 * further down. A text that does not parse has no other findings worth
 * reading yet.
 */
const FAMILY_ORDER = ['lexer', 'parse', 'mapper', 'import', 'ref', 'validation', 'verification'];
const familyRank = (code: string): number => {
  const at = FAMILY_ORDER.indexOf(code.split('/')[0]);
  return at < 0 ? FAMILY_ORDER.length : at;
};

function repairPrompt(fragment: string, items: RepairItem[], guidance: string[] = []): string {
  const blocking = [...items.filter((i) => i.blocking)].sort((x, y) => familyRank(x.code) - familyRank(y.code));
  const notes = items.filter((i) => !i.blocking);
  const parseFirst = blocking.some((i) => familyRank(i.code) <= 1);
  const lines = [
    '## What the checker found',
    '',
    'Fix these. Change only what they name — everything else in the fragment is already checked and traced.',
    'If a fix needs a definition that package Common does not have — an item type a flow or a trigger refers to, a port type — put that declaration in `commonAdditions` rather than deleting the reference or declaring a private copy.',
    ...(parseFirst
      ? [
          'The parse errors come first: fix those before anything else. When text does not parse, the checker recovers by closing scopes early, and most of the findings below them are consequences of that — a connection reported at the root with one endpoint is usually a syntax error a few lines above it.',
        ]
      : []),
    '',
    ...blocking.map(describe),
  ];
  if (notes.length > 0) {
    lines.push('', '## Also reported, not blocking', '', ...notes.slice(0, 20).map(describe));
  }
  if (guidance.length > 0) {
    lines.push('', '## What still holds for this answer', '', ...guidance.map((g) => `- ${g}`));
  }
  lines.push('', '## The fragment as it stands', '', '```', fragment.trimEnd(), '```');
  return lines.join('\n');
}

const describe = (item: RepairItem): string => {
  const where = item.fragmentLine ? ` (line ${item.fragmentLine})` : '';
  const who = item.qualifiedName ? ` \`${item.qualifiedName}\`` : '';
  const rule = item.cv ? ` [${item.cv}]` : '';
  const hint = item.hint ? `\n  ${item.hint}` : '';
  return `- \`${item.code}\`${who}${where}${rule}: ${item.message}${hint}`;
};
