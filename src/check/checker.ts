/**
 * One step's checks, over one model.
 *
 * Everything a step asks is asked of a single loaded model: the prefix is
 * assembled, loaded once, and every command and post-condition reads that one
 * binding. That is not only speed — two loads of the same text mint different
 * element ids, and a packet whose payloads disagree about which element is
 * which is a packet nobody can follow.
 *
 * The diagnostics are read first. When the text did not load cleanly there is
 * no point asking a traceability matrix what it thinks: the analytics would be
 * reporting about the fragment that parsed, not the one that was written.
 */
import { mkdirSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { assemble, toFragmentLine, writeBuild, type Assembly } from '../model/assembler.ts';
import { matchingBrace, packageBody } from '../model/statements.ts';
import type { ModelLayout } from '../model/layout.ts';
import { SolverCrashedError, type SysproseBackend, type Loaded } from '../sysprose/backend.ts';
import { AUTHORED_LAYERS, LAYERS, layerIndex, previousAuthoredLayer, type Layer } from '../spec/layers.ts';
import { checkCommand, isBlocking, type CheckSpec, type PredicateId, type StepSpec } from '../spec/steps.ts';
import { carriersIn, ruleNameOf, sameFields, type RuleRow } from '../spec/rules.ts';
import { itemFromDiagnostic, type Knobs, type RepairItem } from './classify.ts';
import { noteFor } from '../spec/codes.ts';
import { PREDICATES, type BriefFacts, type CarriedEstimates, type EstimateSide, type PayloadBag } from './predicates.ts';
import type { ElementRow } from '../sysprose/types.ts';
import { definingExpression, definingExpressions, expressionNames, isProvisional } from '../spec/measures.ts';

export interface CheckContext {
  backend: SysproseBackend;
  layout: ModelLayout;
  knobs: Knobs;
  brief?: BriefFacts;
  /** Author this layer's checks against a substituted fragment (an alternative). */
  substitute?: Partial<Record<Layer, string>>;
  alternative?: number;
  /** Where payloads are written. No directory, no payload files. */
  auditDir?: string;
  /** Assemble up to this layer instead of the step's own. */
  upTo?: Layer;
  /** Passed to the documentation gate; 0 or absent turns it off. */
  docCoverageMin?: number;
}

export interface CheckOutcome {
  name: string;
  cmd: string;
  /** The command a reader types to reproduce it. */
  cli: string;
  blocking: boolean;
  /** Did this check produce nothing blocking? */
  ok: boolean;
  durationMs: number;
  payloadFile?: string;
  items: RepairItem[];
}

export interface Verdict {
  step: string;
  layer?: Layer;
  alternative?: number;
  prefixPath: string;
  prefixHash: string;
  /** Is anything here worth sending back to an agent? */
  blocking: boolean;
  checks: CheckOutcome[];
  items: RepairItem[];
  durationMs: number;
  loaded: boolean;
  elementCount: number;
  /** Checks and estimate reads run a second time because the solver crashed under the first (`solver/retried`). */
  solverRetries: number;
}

/** What a run says about the checks it ran again after a solver crash. */
export const solverRetriesNote = (n: number): string =>
  n === 1 ? '1 solver crash, retried once' : `${n} solver crashes, each retried once`;

/**
 * A solver read, run once more if the solver crashed under it.
 *
 * The crash is z3's WASM module trapping, not a finding about the model: the
 * module is gone and the next call makes a fresh one. `onRetry` hears of each,
 * so every retry is counted and noted; a second crash is thrown, for the
 * caller to report as a check that could not run. One door for every site, so
 * no read is retried by one rule and missed by another.
 */
export async function retryOnSolverCrash<T>(read: () => Promise<T> | T, onRetry: (err: SolverCrashedError) => void): Promise<T> {
  try {
    return await read();
  } catch (err) {
    if (!(err instanceof SolverCrashedError)) throw err;
    onRetry(err);
    return await read();
  }
}

/** What a retried read says: `what` is the check, or the bound, it was. */
const retriedMessage = (what: string, err: SolverCrashedError): string =>
  `${what}: the solver crashed under it (WASM trap: ${err.trap}) and it was run again on a fresh module; the result is the second run's`;

/** The non-blocking note a retried read leaves in a verdict. */
const retriedItem = (what: string, err: SolverCrashedError, check?: string): RepairItem => ({
  source: 'predicate',
  code: 'solver/retried',
  severity: 'warning',
  blocking: false,
  message: retriedMessage(what, err),
  hint: noteFor('solver/retried')?.note,
  check,
});

/**
 * `bounds` for a reader with no check to carry a `solver/retried` item — the
 * trade-off's measures, the final audit's table: read once more if the solver
 * crashed under it, each retry logged and counted for the step that owns the
 * read. A second crash is thrown, for the reader to say the solver crashed
 * rather than that there is no estimate.
 */
export const boundsRetried =
  (backend: SysproseBackend, m: Loaded, log: (line: string) => void, counted: () => void) =>
  (qn: string, sense: 'min' | 'max') =>
    retryOnSolverCrash(
      () => backend.bounds(m, qn, sense),
      (err) => {
        counted();
        log(`  ${retriedMessage(`the ${sense} bound of \`${qn}\``, err)}`);
      },
    );

/** The highest layer that has a fragment — what a step with no layer of its own is checked against. */
export function topLayer(layout: ModelLayout, substitute?: Partial<Record<Layer, string>>): Layer {
  const full = assemble(layout, 'EPBS', substitute ? { substitute } : {});
  return full.layers.length > 0 ? full.layers[full.layers.length - 1] : 'Kinds';
}

export async function runStepChecks(step: StepSpec, ctx: CheckContext): Promise<Verdict> {
  const started = Date.now();
  const layer = ctx.upTo ?? step.layer ?? topLayer(ctx.layout, ctx.substitute);
  const assembly = assemble(ctx.layout, layer, ctx.substitute ? { substitute: ctx.substitute } : {});
  const prefixPath = writeBuild(ctx.layout, assembly, ctx.alternative);
  if (ctx.auditDir) mkdirSync(ctx.auditDir, { recursive: true });

  const outcomes: CheckOutcome[] = [];
  const payloads: PayloadBag = {};
  let solverRetries = 0;
  // Solver crashes on the estimate reads, kept until the checks that own those
  // predicates have outcomes to carry them.
  const estimateRetries: Array<{ predicate: PredicateId; item: RepairItem }> = [];
  const unreadEstimates = new Map<PredicateId, Set<string>>();
  const unread = (predicate: PredicateId, qn: string): void => {
    unreadEstimates.set(predicate, (unreadEstimates.get(predicate) ?? new Set()).add(qn));
  };

  const result = await ctx.backend.withModel(assembly.text, prefixPath, async (m: Loaded) => {
    // Always collected: every post-condition needs the element list and the
    // keyword index, and neither is worth a second load.
    payloads.elements = ctx.backend.elements(m);
    const tags = ctx.backend.tags(m);
    payloads.check = m.report;
    // The layer as the transitions see it: connections with their usage-level
    // ends, actions with their tags. What the population gates read.
    if (step.layer && (AUTHORED_LAYERS as readonly Layer[]).includes(step.layer)) payloads.layerView = ctx.backend.layerView(m, step.layer);
    // Every bounds read below is run once more if the solver crashed under it,
    // and noted against the check whose predicate reads it. One that crashed
    // twice is not a missing estimate: the step could not be checked, and the
    // gates leave that measure's verdict out rather than guess it.
    const readBounds = (predicate: PredicateId) => (qn: string, sense: 'min' | 'max') =>
      retryOnSolverCrash(
        () => ctx.backend.bounds(m, qn, sense),
        (err) => {
          solverRetries += 1;
          estimateRetries.push({ predicate, item: retriedItem(`the ${sense} bound of \`${qn}\``, err) });
        },
      );
    // What each measure's estimate bounds to in this layer, for moe.estimated:
    // an estimate derived by a constraint carries no literal, and only the
    // solver can say it is a point. Asked both ways; only where the gate runs.
    const measures = ctx.brief?.moes ?? [];
    const wantsEstimates = step.checks.some((c) => c.predicates?.includes('moe.estimated'));
    if (wantsEstimates && measures.length > 0 && step.layer && m.report.summary.errors === 0) {
      const estimates: Record<string, { min?: number; max?: number; refused?: string; solverCrashed?: boolean }> = {};
      const names = new Set((payloads.elements as ElementRow[]).map((e) => e.qualifiedName));
      const bounds = readBounds('moe.estimated');
      for (const name of measures) {
        const qn = `${ctx.layout.root}::${step.layer}::${name}`;
        if (!names.has(qn)) continue;
        try {
          const lo = (await bounds(qn, 'min')).bounds[0];
          const hi = (await bounds(qn, 'max')).bounds[0];
          // Why no value, when the solver answered and Sysprose would not
          // confirm the point — the repair needs that, not "nothing fixes it".
          const refused = [lo, hi].find((r) => r?.code === 'verification/not-evaluable')?.detail ?? undefined;
          estimates[name] = { min: lo?.value ?? undefined, max: hi?.value ?? undefined, refused };
        } catch (err) {
          // An estimate bounds cannot read is one the gate reports as missing.
          if (err instanceof SolverCrashedError) {
            estimates[name] = { solverCrashed: true };
            unread('moe.estimated', qn);
          }
        }
      }
      payloads.estimates = estimates;
    }

    // The layer above's estimate beside this one's, for moe.carriedEstimate.
    // The layer above is already in this model — the prefix holds it — so this
    // is more solver calls, not another load.
    const above = step.layer ? previousAuthoredLayer(step.layer) : undefined;
    const wantsCarried = step.checks.some((c) => c.predicates?.includes('moe.carriedEstimate'));
    if (wantsCarried && above && measures.length > 0 && step.layer && m.report.summary.errors === 0) {
      payloads.carried = await carriedEstimates(ctx, m, payloads.elements as ElementRow[], step.layer, above, readBounds('moe.carriedEstimate'), (qn) =>
        unread('moe.carriedEstimate', qn),
      );
    }

    // The rules each machine of this layer carries, checked, for rules.carried
    // and rules.hold. Only machines that carry a property are walked.
    const wantsRules = step.checks.some((c) => c.predicates?.includes('rules.carried'));
    if (wantsRules && (ctx.brief?.rules ?? []).length > 0 && step.layer && m.report.summary.errors === 0) {
      const layerText = packageBody(m.text, step.layer)?.body ?? m.text;
      const carriers = carriersIn(layerText, matchingBrace);
      const rows: RuleRow[] = [];
      if (carriers.length > 0) {
        const prefix = `${ctx.layout.root}::${step.layer}::`;
        const machines = (payloads.elements as ElementRow[]).filter((e) => e.metaclass === 'StateDefinition' && e.qualifiedName.startsWith(prefix));
        for (const machine of machines) {
          try {
            const report = ctx.backend.behaviour(m, machine.id);
            for (const p of report.properties) {
              const fields = (p.property ?? {}) as unknown as Record<string, string | undefined>;
              const carrier = carriers.find((c) => sameFields(c.fields, fields));
              rows.push({
                machine: machine.qualifiedName,
                owner: machine.qualifiedName.split('::').slice(0, -1).join('::'),
                rule: carrier ? ruleNameOf(carrier.doc) : undefined,
                fields: Object.fromEntries(Object.entries(fields).filter(([k, v]) => typeof v === 'string' && k !== 'source' && k !== 'carrier')) as Record<string, string>,
                claim: String(p.claim),
                code: p.code ?? undefined,
                detail: p.detail ?? undefined,
              });
            }
          } catch {
            // A machine the walk cannot read carries no checked rule; the gate says so.
          }
        }
      }
      payloads.rules = rows;
    }

    const loadedCleanly = m.report.summary.errors === 0;
    for (const spec of step.checks) {
      const blocking = isBlocking(spec.blocking, ctx.knobs);
      const at = Date.now();
      if (spec.cmd !== 'check' && !loadedCleanly) {
        outcomes.push({
          name: spec.name,
          cmd: spec.cmd,
          cli: checkCommand(spec, prefixPath),
          blocking,
          ok: true,
          durationMs: 0,
          items: [],
        });
        continue;
      }
      let payload: unknown;
      const retried: RepairItem[] = [];
      try {
        payload = await retryOnSolverCrash(
          () => runOne(ctx.backend, m, spec),
          (err) => {
            solverRetries += 1;
            retried.push(retriedItem(`\`${spec.name}\``, err, spec.name));
          },
        );
      } catch (err) {
        outcomes.push({
          name: spec.name,
          cmd: spec.cmd,
          cli: checkCommand(spec, prefixPath),
          blocking,
          ok: !blocking,
          durationMs: Date.now() - at,
          items: [
            {
              source: 'predicate',
              code: 'check/failed',
              severity: 'error',
              blocking,
              message: `\`${spec.name}\` could not run: ${err instanceof Error ? err.message : String(err)}${retried.length > 0 ? ' — on the second attempt, the solver having crashed under the first' : ''}`,
              check: spec.name,
            },
          ],
        });
        continue;
      }
      payloads[spec.name] = payload;
      const payloadFile = ctx.auditDir ? resolve(ctx.auditDir, `${spec.name}.json`) : undefined;
      if (payloadFile) writeFileSync(payloadFile, `${JSON.stringify(payload, null, 2)}\n`);
      outcomes.push({
        name: spec.name,
        cmd: spec.cmd,
        cli: checkCommand(spec, prefixPath),
        blocking,
        ok: true,
        durationMs: Date.now() - at,
        payloadFile,
        items: retried,
      });
    }

    // The estimate reads' retries, and the reads that crashed twice, on the
    // check whose predicate needed them.
    for (const spec of step.checks) {
      const outcome = outcomes.find((o) => o.name === spec.name);
      if (!outcome) continue;
      for (const r of estimateRetries) if (spec.predicates?.includes(r.predicate)) outcome.items.push({ ...r.item, check: spec.name });
      for (const [predicate, unreadQns] of unreadEstimates) {
        if (!spec.predicates?.includes(predicate)) continue;
        const qns = [...unreadQns];
        outcome.items.push({
          source: 'predicate',
          code: 'check/failed',
          severity: 'error',
          blocking: outcome.blocking,
          message:
            `the solver crashed twice reading the estimates (${qns.map((q) => `\`${q}\``).join(', ')}): the step could not be checked. ` +
            `\`${predicate}\` says nothing about ${qns.length === 1 ? 'that measure' : 'those measures'} rather than call ${qns.length === 1 ? 'it' : 'them'} missing; check the step again.`,
          check: spec.name,
        });
      }
    }

    // Post-conditions run after every payload is in, because several read more
    // than their own check's: "is this function allocated to an actor" is an
    // answer from the allocation matrix, wherever the question came from.
    for (const spec of step.checks) {
      const outcome = outcomes.find((o) => o.name === spec.name);
      if (!outcome || !spec.predicates) continue;
      for (const id of spec.predicates) {
        const items = PREDICATES[id]({
          step,
          layer: step.layer,
          root: ctx.layout.root,
          knobs: ctx.knobs,
          brief: ctx.brief,
          payloads,
          tags,
          blocking: isBlocking(spec.blocking, ctx.knobs),
          alternative: ctx.alternative,
          docCoverageMin: ctx.docCoverageMin,
        });
        outcome.items.push(...items.map((i) => ({ ...i, check: spec.name })));
      }
    }
    return { report: m.report, elementCount: m.report.elements.count };
  });

  // Diagnostics attach to the `check` outcome, or to a synthetic one when the
  // step does not run `check` itself — a finding is never dropped for want of
  // somewhere to put it.
  const provisional = new Set((ctx.brief?.measures ?? []).filter(isProvisional).map((m) => m.name));
  const diagnosticItems = result.report.diagnostics.map((d) =>
    itemFromDiagnostic(d, step, ctx.knobs, 'check', provisional),
  );
  const checkOutcome = outcomes.find((o) => o.cmd === 'check');
  if (checkOutcome) {
    checkOutcome.items.push(...diagnosticItems);
  } else if (diagnosticItems.length > 0) {
    outcomes.unshift({
      name: 'check',
      cmd: 'check',
      cli: `npm run check -- ${prefixPath} --json`,
      blocking: true,
      ok: true,
      durationMs: 0,
      items: diagnosticItems,
    });
  }

  const items = outcomes.flatMap((o) => o.items).map((i) => inherit(withFragmentLine(i, assembly), step.layer));
  for (const outcome of outcomes) outcome.ok = !outcome.items.some((i) => i.blocking);

  return {
    step: step.id,
    layer: step.layer,
    alternative: ctx.alternative,
    prefixPath,
    prefixHash: assembly.hash,
    blocking: items.some((i) => i.blocking),
    checks: outcomes,
    items,
    durationMs: Date.now() - started,
    loaded: true,
    elementCount: result.elementCount,
    solverRetries,
  };
}

/**
 * How many equations deep a derived input is followed to the assumptions under
 * it. v9's coverage under jamming is three deep (the coverage, the gap share,
 * the transit time); past this, the input is compared as the value it has.
 */
const MAX_INPUT_DEPTH = 8;

/**
 * Each measure's estimate at `layer` and at the layer above, with its basis and,
 * when it is derived, the value of every assumption its equation rests on in
 * that layer. Literal means the `#Estimate` carries a number; derived means it
 * has none and the solver fixes it to one point (as moe.estimated accepts it).
 *
 * The assumptions are the leaves: an input that is itself valueless and fixed
 * by an asserted equation of the layer is followed into that equation's inputs.
 * One level deep, v9's coverage under jamming at LA and PA read
 * `areaUnderWatchFraction` and `sectorGapShareOfLostHandOver` — two derived
 * quantities — so a move in the transit time under both was reported as two
 * intermediates that moved, and never as the number that did.
 */
async function carriedEstimates(
  ctx: CheckContext,
  m: Loaded,
  elements: ElementRow[],
  layer: Layer,
  above: Layer,
  bounds: (qn: string, sense: 'min' | 'max') => Promise<{ bounds: Array<{ value?: number | null }> }>,
  crashedTwice: (qn: string) => void,
): Promise<CarriedEstimates> {
  const root = ctx.layout.root;
  const rows = new Map(elements.map((e) => [e.qualifiedName, e]));
  const literal = (row: ElementRow | undefined): number | undefined =>
    row && /^-?\d+(\.\d+)?(e-?\d+)?$/i.test(row.value.trim()) ? Number(row.value.trim()) : undefined;
  // One point both ways, or nothing: a value the solver will not pin is not
  // one to compare.
  const point = async (qn: string): Promise<number | undefined> => {
    try {
      const lo = (await bounds(qn, 'min')).bounds[0]?.value ?? undefined;
      const hi = (await bounds(qn, 'max')).bounds[0]?.value ?? undefined;
      if (lo === undefined || hi === undefined) return undefined;
      return Math.abs(lo - hi) <= 1e-9 * Math.max(1, Math.abs(lo)) ? lo : undefined;
    } catch (err) {
      // No value either way; a read the solver crashed under twice is also
      // said, as a step that could not be checked.
      if (err instanceof SolverCrashedError) crashedTwice(qn);
      return undefined;
    }
  };
  // The feature a chain (`fleet.size`) ends at, as `elements` lists it: a
  // member declared in the head's own body, else one of its type's.
  const chainRow = (l: Layer, chain: string): ElementRow | undefined => {
    const [head, ...rest] = chain.split('.');
    let at = rows.get(`${root}::${l}::${head}`);
    for (const segment of rest) {
      if (!at) return undefined;
      const typeName = at.type.split(/[,\s]/)[0]?.split('::').pop();
      const owner: ElementRow = at;
      at =
        rows.get(`${owner.qualifiedName}::${segment}`) ??
        (typeName
          ? (elements.find((e) => e.qualifiedName === `${root}::${l}::${typeName}::${segment}`) ??
            elements.find((e) => e.qualifiedName.startsWith(`${root}::`) && e.qualifiedName.endsWith(`::${typeName}::${segment}`)))
          : undefined);
    }
    return at;
  };
  const valueOf = async (l: Layer, name: string): Promise<number | undefined> => {
    const qn = `${root}::${l}::${name}`;
    const row = rows.get(qn);
    if (row) return literal(row) ?? point(qn);
    if (!name.includes('.')) return undefined;
    // A chain has no row of its own. Sysprose's evaluator reads it through the
    // feature it resolves to — its type's member, or that member's equation —
    // without the solver; a backend without the evaluator reads that feature.
    // Only a number is an answer: every object has a `valueOf`, Object's own,
    // and on a backend that does not define one it returns the backend.
    try {
      const value: unknown = ctx.backend.valueOf?.(m, qn);
      if (typeof value === 'number' && Number.isFinite(value)) return value;
    } catch {
      // A chain the backend cannot resolve: the elements may still name it.
    }
    const resolved = chainRow(l, name);
    return resolved ? (literal(resolved) ?? point(resolved.qualifiedName)) : undefined;
  };
  const text = (l: Layer): string => packageBody(m.text, l)?.body ?? '';
  // The assumptions under `expr`, by name: each input, or — when the input is
  // valueless and an asserted equation of the layer fixes it — the inputs of
  // that equation, in turn. `path` guards a cycle (`a == b + 1`, `b == a - 1`):
  // a name met again on its own path is compared as the value it has.
  const leaves = async (l: Layer, expr: string, path: ReadonlySet<string>, into: Record<string, number | undefined>): Promise<void> => {
    for (const input of expressionNames(expr)) {
      if (input in into) continue;
      const row = rows.get(`${root}::${l}::${input}`);
      // Not the equation it was reached through, read backwards: from `m == p`,
      // the expression "defining" `p` is `m`.
      const deeper =
        row && row.value.trim() === '' && !path.has(input) && path.size < MAX_INPUT_DEPTH
          ? definingExpressions(text(l), input).find((e) => !path.has(e))
          : undefined;
      if (deeper !== undefined) await leaves(l, deeper, new Set([...path, input]), into);
      else into[input] = await valueOf(l, input);
    }
  };
  const side = async (l: Layer, name: string): Promise<EstimateSide | undefined> => {
    const qn = `${root}::${l}::${name}`;
    const row = rows.get(qn);
    if (!row || row.metaclass !== 'AttributeUsage') return undefined;
    const stated = literal(row);
    if (stated !== undefined) return { value: stated, derived: false, basis: row.doc || undefined };
    const value = await point(qn);
    const expr = definingExpression(text(l), name);
    const inputs: Record<string, number | undefined> = {};
    if (expr) await leaves(l, expr, new Set([name]), inputs);
    return { value, derived: value !== undefined, basis: row.doc || undefined, inputs: expr ? inputs : undefined };
  };
  const out: CarriedEstimates = { above, measures: {} };
  for (const name of ctx.brief?.moes ?? []) {
    const here = await side(layer, name);
    const before = await side(above, name);
    if (here || before) out.measures[name] = { above: before, here };
  }
  return out;
}

/**
 * A raw diagnostic anchored in an earlier layer is inherited, not owed.
 *
 * Only diagnostics: a predicate that names an element above — a hazard the
 * layer must mitigate, a function it must realise — is asking this layer for
 * something, and that stays blocking. Common and Kinds are not "above": this
 * step may have written into Common, and a defect there is its own.
 */
export function inherit(item: RepairItem, layer: Layer | undefined): RepairItem {
  if (item.source !== 'diagnostic' || !item.blocking || layer === undefined || item.layer === undefined) return item;
  if (item.layer === layer || !(AUTHORED_LAYERS as readonly Layer[]).includes(item.layer) || layerIndex(item.layer) >= layerIndex(layer)) return item;
  return {
    ...item,
    blocking: false,
    inherited: item.layer,
    message: `${item.message} — in ${item.layer}, above this layer: reported, not repaired here. Re-check that layer's step.`,
  };
}

function withFragmentLine(item: RepairItem, assembly: Assembly): RepairItem {
  if (item.prefixLine === undefined) return item;
  const mapped = toFragmentLine(assembly, item.prefixLine);
  return mapped
    ? { ...item, layer: mapped.layer, fragmentLine: mapped.line, fragmentPath: mapped.path }
    : item;
}

function runOne(backend: SysproseBackend, m: Loaded, spec: CheckSpec): Promise<unknown> | unknown {
  switch (spec.cmd) {
    case 'check':
      return m.report;
    case 'elements':
      return backend.elements(m);
    case 'trace':
      return backend.trace(m, spec.args?.relation ?? 'trace', spec.args?.from, spec.args?.to);
    case 'connectivity':
      return backend.connectivity(m);
    case 'reach':
      return backend.reach(m);
    case 'orphans':
      return backend.orphans(m);
    case 'requirements':
      return backend.requirements(m, spec.args?.kind);
    case 'stats':
      return backend.stats(m);
    case 'verify':
      return backend.verify(m);
    case 'consistency':
      return backend.consistency(m);
    case 'refine':
      return backend.refine(m, spec.args?.via);
    case 'evidence-status':
      return backend.evidenceStatus(m);
    case 'fault-tree':
      return backend.faultTree(m);
    case 'check-behaviour':
      return behaviourSweep(backend, m);
    default: {
      const never: never = spec.cmd;
      throw new Error(`unhandled check command ${String(never)}`);
    }
  }
}

/** The state machines one sweep checks at most: each is a model-checking walk. */
const MAX_MACHINES = 40;

export interface BehaviourRow {
  machine: string;
  /** `carried` — the properties the machine states; `recovery to X` — the default; `none` — nothing to check. */
  property: string;
  exitCode: number;
  counts: { passed: number; failed: number; vacuous: number; inconclusive: number };
  detail?: string;
}

/**
 * `check-behaviour` over every state machine of the model.
 *
 * The command needs `--element`, which is why the design's step table could
 * not run it. A machine that states no property of its own, and that is
 * written to come back to the state it opens at, gets the property that says
 * so: every reachable configuration can get back there — no trap state. A
 * machine with no transition back is a lifecycle, and gets none: v5's EPBS
 * delivery machines go Delivered → Accepted → InService and rightly never
 * return, and the default refuted all three. Tags could not tell them apart:
 * v5 tagged those lifecycles #State.
 */
export function behaviourSweep(backend: SysproseBackend, m: Loaded): { machines: BehaviourRow[]; skipped: number } {
  const machines = backend.elements(m).filter((e) => e.metaclass === 'StateDefinition');
  const rows: BehaviourRow[] = [];
  for (const def of machines.slice(0, MAX_MACHINES)) {
    try {
      let report = backend.behaviour(m, def.id);
      let property = 'carried';
      if (report.properties.length === 0) {
        // Read the machine in its own layer: the same name is often defined at
        // LA and PA, and v7's PA FleetConfiguration was checked for recovery to
        // a state only LA's machine had.
        const layer = def.qualifiedName.split('::')[1];
        const text = (layer ? packageBody(m.text, layer)?.body : undefined) ?? m.text;
        const initial = initialStateOf(text, def.name);
        if (!initial || !returnsTo(text, def.name, initial)) {
          rows.push({ machine: def.qualifiedName, property: 'none', exitCode: report.exitCode, counts: report.counts });
          continue;
        }
        report = backend.behaviour(m, def.id, `pattern=recovery,scope=globally,p=state ${initial}`);
        property = `recovery to ${initial}`;
      }
      const failed = report.properties.find((p) => p.claim === 'fail');
      rows.push({ machine: def.qualifiedName, property, exitCode: report.exitCode, counts: report.counts, detail: (failed ?? report.properties[0])?.detail ?? undefined });
    } catch (err) {
      rows.push({ machine: def.qualifiedName, property: 'error', exitCode: 2, counts: { passed: 0, failed: 0, vacuous: 0, inconclusive: 0 }, detail: err instanceof Error ? err.message : String(err) });
    }
  }
  return { machines: rows, skipped: Math.max(0, machines.length - MAX_MACHINES) };
}

/** Whether some transition of the machine, other than the one out of `initial`, leads to `state`. */
export function returnsTo(text: string, defName: string, state: string): boolean {
  const open = new RegExp(`\\bstate\\s+def\\s+${defName}\\s*\\{`).exec(text);
  if (!open) return false;
  const start = open.index + open[0].length - 1;
  const close = matchingBrace(text, start);
  const body = text.slice(start + 1, close < 0 ? undefined : close);
  const initial = /\binitial\s+(\w+)\s*;/.exec(body)?.[1];
  return [...body.matchAll(new RegExp(`\\btransition\\s+(?:\\w+\\s+first\\s+)?(\\w+)\\b[^;]*?(?:->|\\bthen)\\s*${state}\\s*;`, 'g'))].some((t) => t[1] !== initial);
}

/** The state a machine opens at: the target of the transition out of `initial`, else the first state declared. */
export function initialStateOf(text: string, defName: string): string | undefined {
  const open = new RegExp(`\\bstate\\s+def\\s+${defName}\\s*\\{`).exec(text);
  if (!open) return undefined;
  const start = open.index + open[0].length - 1;
  const close = matchingBrace(text, start);
  const body = text.slice(start + 1, close < 0 ? undefined : close);
  const initial = /\binitial\s+(\w+)\s*;/.exec(body)?.[1];
  if (initial) {
    const target = new RegExp(`\\btransition\\s+(?:\\w+\\s+first\\s+)?${initial}\\s*->\\s*(\\w+)`).exec(body)?.[1];
    if (target) return target;
  }
  return /(?:^|[;{}\n])\s*state\s+(\w+)\s*[;{]/.exec(body)?.[1];
}

/** Every layer, in assembly order, that has a fragment on disk. */
export const layersPresent = (layout: ModelLayout): Layer[] =>
  LAYERS.filter((l) => layerIndex(l) <= layerIndex('EPBS') && assemble(layout, l).layers.includes(l));
