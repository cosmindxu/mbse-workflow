/**
 * The loop.
 *
 * Author, assemble, check, repair, transition, evaluate, audit — and a gate
 * wherever this run has one armed. Nothing here role-plays an engineer: the
 * method's activities decide the ORDER of the steps and what each one is checked
 * against, and that is all they are used for.
 *
 * Two properties are the whole point of writing it as a machine rather than a
 * script. Every transition is written to `state.json`, so a run that stops
 * comes back where it was; and every step is gated on a check whose command is
 * recorded, so a reader can re-run any of it.
 */
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { runStepChecks, topLayer, type Verdict } from '../check/checker.ts';
import { assemble, writeBuild } from '../model/assembler.ts';
import { makeLayout, type ModelLayout } from '../model/layout.ts';
import { generateSkeleton } from '../transition/skeleton.ts';
import { STEPS, type GateId, type StepId, type StepSpec } from '../spec/steps.ts';
import { buildSystemPrompt } from '../prompts/system.ts';
import { previousAuthoredLayer, type Layer } from '../spec/layers.ts';
import { GATES_BY_MODE, type RunMode, type WorkflowConfig } from '../config/schema.ts';
import type { SysproseBackend } from '../sysprose/backend.ts';
import { LlmError, type LlmClient } from '../llm/client.ts';
import type { GateController, GateRequest } from './gates.ts';
import { emptyState, loadState, openLeg, recordSpend, saveState, stepRecord, type RunState, type StepRecord } from './state.ts';
import { invalidate, recordInvalidation } from './invalidate.ts';
import { authorLayer, briefFacts, recordReviewerComment, repairFragment } from '../agents/author.ts';
import { authorAlternatives } from '../agents/alternatives.ts';
import { evaluateAlternatives } from '../agents/evaluate.ts';
import { runSeed } from '../agents/seed.ts';
import { writePacket, readIfExists } from '../audit/packet.ts';
import { writeFinalAudit } from '../audit/final.ts';
import type { AgentContext } from '../agents/context.ts';
import type { Knobs } from '../check/classify.ts';

export interface RunOptions {
  dir: string;
  mode: RunMode;
  config: WorkflowConfig;
  backend: SysproseBackend;
  llm: LlmClient;
  gates: GateController;
  briefText?: string;
  /** Extra inputs for the intake lanes. */
  requirementsText?: string;
  infrastructureText?: string;
  fromStep?: StepId;
  log?: (message: string) => void;
}

export interface RunResult {
  state: RunState;
  layout: ModelLayout;
  finalPath?: string;
}

export async function runWorkflow(opts: RunOptions): Promise<RunResult> {
  const log = opts.log ?? ((m: string) => process.stderr.write(`${m}\n`));
  const knobs = opts.config.knobs as Knobs;
  const version = await opts.backend.version();
  if (!version.matches) {
    log(
      `  note: Sysprose is at ${version.commit}, the checks were calibrated against ${version.expected}. ` +
        'Re-run the probes if a predicate starts disagreeing with the tool.',
    );
  }

  // The root package is named by SEED, so a resumed run reads it back and a new
  // one starts under a placeholder until the brief settles it.
  const existing = loadState(resolve(opts.dir, 'state.json'));
  const root = existing?.root ?? existing?.brief?.systemName ?? 'System';
  let layout = makeLayout(opts.dir, root);
  layout.ensure();

  const state =
    existing ??
    emptyState({
      root,
      mode: opts.mode,
      knobs: knobs as unknown as Record<string, boolean>,
      sysprose: { dir: version.dir, commit: version.commit, expected: version.expected, matches: version.matches },
    });
  state.mode = opts.mode;
  const leg = openLeg(state);
  // Saved after every call, not only when a step finishes (see LlmClient.onSpend).
  opts.llm.onSpend = () => {
    recordSpend(state, leg, opts.llm.spent());
    saveState(layout.statePath, state);
  };

  // A resumed run first asks what a person changed while it was stopped. An
  // explicit --from-step is that person saying where to start; otherwise the
  // fragments decide.
  const armed = new Set<string>(GATES_BY_MODE[opts.mode]);
  let ctx: AgentContext = { config: opts.config, layout, backend: opts.backend, llm: opts.llm, state, knobs, log };

  if (existing && opts.fromStep === undefined) {
    const result = invalidate(state, layout);
    if (result.changed.length > 0) {
      const path = recordInvalidation(layout, result);
      log(
        `  ${result.changed.join(', ')} changed since the last run: ` +
          `${result.recheck.join(', ') || 'nothing'} re-checked, ` +
          `${result.invalidated.join(', ') || 'nothing'} will run again (${path})`,
      );
      saveState(layout.statePath, state);
      // The person's layer is checked as it stands. If it does not clear, it is
      // repaired only as far as the findings require — and if that fails, the
      // gate opens: the one thing this must never do is rewrite their work.
      for (const id of result.recheck) {
        const step = STEPS.find((s) => s.id === id)!;
        const record = stepRecord(state, id);
        log(`\n${id} ${step.name} (${step.layer}) — re-checking a fragment a person edited`);
        const recheck = (): Promise<Verdict> =>
          runStepChecks(step, {
            backend: ctx.backend,
            layout,
            knobs,
            brief: briefFacts(ctx),
            docCoverageMin: ctx.config.limits.doc_coverage_min,
            auditDir: layout.auditDirFor(id),
          });
        const repaired = await repairFragment(ctx, {
          tag: `${id}:RECHECK`,
          system: buildSystemPrompt({ step, knobs, root: layout.root }),
          layer: step.layer as Layer,
          fragmentPath: layout.fragmentPath(step.layer as Layer),
          verdict: await recheck(),
          recheck,
          label: `${id} (edited)`,
        });
        record.iterations = repaired.iterations;
        record.blocking = repaired.verdict.items.filter((i) => i.blocking).length;
        record.fragmentHashes = assemble(layout, step.layer as Layer).fragmentHashes;
        record.status = repaired.verdict.blocking ? 'blocked' : 'done';
        if (record.status === 'done') record.note = undefined;
        writePacket({ layout, step: id, verdict: repaired.verdict, rationales: ['Re-checked after a person edited the fragment.', ...repaired.rationales] });
        saveState(layout.statePath, state);
        if (repaired.verdict.blocking) {
          const gate = (step.gate ?? 'G-FINAL') as GateId;
          const decision = await opts.gates.decide(gateRequest(gate, step, repaired.verdict, layout));
          record.gate = { gate, decision: decision.decision, comments: decision.comments, at: new Date().toISOString() };
          saveState(layout.statePath, state);
          if (decision.decision !== 'approve') {
            log(`  ${id}: the edited fragment does not clear its checks and was not approved. Stopping here.`);
            return { state, layout };
          }
        }
      }
    }
  }

  let startAt = opts.fromStep ? STEPS.findIndex((s) => s.id === opts.fromStep) : 0;
  // Re-entering an author step re-enters the transition that feeds it: the
  // fragment on disk is the last answer, not the skeleton, and an author that
  // starts from its own previous answer inherits every link that answer
  // dropped. The transition is a script and costs nothing.
  if (startAt > 0 && STEPS[startAt].agent === 'AUTHOR') {
    const before = STEPS[startAt - 1];
    if (before.agent === 'TRANSITION' && before.layer === STEPS[startAt].layer) {
      log(`  ${opts.fromStep} starts from a generated skeleton: re-running ${before.id} first`);
      startAt -= 1;
    }
  }
  for (const [index, step] of STEPS.entries()) {
    if (index < startAt) continue;
    const record = stepRecord(state, step.id);

    if (step.knob && !knobs[step.knob]) {
      record.status = 'skipped';
      record.note = `the ${step.knob} lane is off`;
      saveState(layout.statePath, state);
      continue;
    }
    if (record.status === 'done' && index >= startAt && opts.fromStep === undefined) {
      continue;
    }

    record.status = 'running';
    record.startedAt = new Date().toISOString();
    state.current = step.id;
    saveState(layout.statePath, state);
    log(`\n${step.id} ${step.name}${step.layer ? ` (${step.layer})` : ''}`);

    let verdict: Verdict | undefined;
    let rejections = 0;
    let done = false;

    while (!done) {
      let outcome: StepOutcome;
      try {
        outcome = await runStep(ctx, step, opts, record);
      } catch (err) {
        // A run that stops because it ran out of budget, or because the model
        // could not be reached, is not a crash: the fragments and packets up to
        // here are worth keeping, and `resume` re-enters at this step. Saying so
        // in the state file is what makes that recoverable rather than a stack
        // trace and a directory nobody trusts.
        const reason = err instanceof LlmError ? err.message : err instanceof Error ? err.message : String(err);
        record.status = 'blocked';
        record.note = reason;
        record.finishedAt = new Date().toISOString();
        recordSpend(state, leg, opts.llm.spent());
        saveState(layout.statePath, state);
        log(`  ${step.id} stopped: ${reason}`);
        log(`  everything up to here is on disk — resume with \`mbse-workflow resume --out ${layout.dir}\``);
        return { state, layout };
      }
      verdict = outcome.verdict;
      ctx = outcome.ctx;
      layout = ctx.layout;

      record.iterations = outcome.iterations;
      record.blocking = verdict ? verdict.items.filter((i) => i.blocking).length : 0;
      record.prefixHash = verdict?.prefixHash;
      record.fragmentHashes = assemble(layout, verdict?.layer ?? topLayer(layout)).fragmentHashes;
      record.status = outcome.blocked ? 'blocked' : 'done';
      // A note explains why a step stopped or was invalidated. Once it has run
      // and cleared, that explanation is history and a reader deserves not to
      // see it: the shipped v3 example has S21 marked `done` and annotated
      // "failed after 3 attempts: session limit", which is two contradictory
      // facts in one record.
      if (record.status === 'done') record.note = undefined;
      recordSpend(state, leg, opts.llm.spent());
      saveState(layout.statePath, state);

      const gate = step.gate;
      const needsGate = gate !== undefined && (armed.has(gate) || outcome.blocked);
      if (!needsGate) {
        done = true;
        break;
      }
      const decision = await opts.gates.decide(gateRequest(gate as GateId, step, verdict, layout));
      record.gate = { gate: gate as GateId, decision: decision.decision, comments: decision.comments, at: new Date().toISOString() };
      saveState(layout.statePath, state);

      if (decision.decision === 'reject' && rejections < 2 && step.layer) {
        rejections += 1;
        if (decision.comments) {
          recordReviewerComment(layout.fragmentPath(step.layer), step.layer, decision.comments, rejections);
          // Also kept in the state: a step that rewrites its own layer (SEED,
          // EVALUATE) would otherwise lose the comment before it runs again.
          state.gateComments = { ...state.gateComments, [step.id]: [...(state.gateComments?.[step.id] ?? []), decision.comments] };
          saveState(layout.statePath, state);
        }
        log(`  ${gate}: rejected — running ${step.id} again with the comment in the model`);
        // A rejected gate is not a failed step: the decision file is consumed so
        // the next round waits for a fresh one rather than reading this one.
        clearDecision(layout, gate as GateId);
        record.status = 'running';
        continue;
      }
      if (decision.decision === 'reject') {
        record.status = 'blocked';
        record.note = 'rejected at the gate';
        saveState(layout.statePath, state);
        log(`  ${gate}: rejected — stopping here. Resume with \`mbse-workflow resume --out ${layout.dir}\`.`);
        return { state, layout };
      }
      done = true;
    }

    if (record.status === 'blocked') {
      record.finishedAt = new Date().toISOString();
      saveState(layout.statePath, state);
      // Say what to do, not only that it stopped: approving the gate of a
      // blocked step records the decision and still stops here, because the
      // next layer would be derived from one the checks refused.
      log(`  ${step.id} is blocked after ${record.iterations} repair round(s). Nothing further runs.`);
      if (step.layer)
        log(
          `  edit ${layout.fragmentPath(step.layer)} and \`mbse-workflow resume --out ${layout.dir}\`: ` +
            `that layer is re-checked, never re-authored, and the layers below it are re-derived.`,
        );
      return { state, layout };
    }
    record.finishedAt = new Date().toISOString();
    saveState(layout.statePath, state);
  }

  state.current = undefined;
  saveState(layout.statePath, state);
  return { state, layout, finalPath: layout.finalPath };
}

/* ─────────────────────────────── one step ───────────────────────────────── */

interface StepOutcome {
  verdict?: Verdict;
  iterations: number;
  blocked: boolean;
  ctx: AgentContext;
}

async function runStep(
  ctx: AgentContext,
  step: StepSpec,
  opts: RunOptions,
  record: StepRecord,
): Promise<StepOutcome> {
  const before = step.layer ? readIfExists(ctx.layout.fragmentPath(step.layer)) : undefined;

  switch (step.agent) {
    case 'SEED': {
      const seed = await runSeed(ctx, opts.briefText ?? '');
      // The model is named by the brief, so everything after this step is laid
      // out under the system's own name.
      const layout = makeLayout(ctx.layout.dir, seed.brief.systemName);
      layout.ensure();
      const next: AgentContext = { ...ctx, layout, state: { ...ctx.state, root: seed.brief.systemName, brief: seed.brief } };
      ctx.state.root = seed.brief.systemName;
      ctx.state.brief = seed.brief;
      const recheck = (): Promise<Verdict> =>
        runStepChecks(step, {
          backend: next.backend,
          layout,
          knobs: next.knobs,
          brief: briefFacts(next),
          docCoverageMin: next.config.limits.doc_coverage_min,
          auditDir: layout.auditDirFor(step.id),
        });
      const repaired = await repairFragment(next, {
        tag: 'S00:SEED',
        system: buildSystemPrompt({ step, knobs: next.knobs, root: seed.brief.systemName }),
        layer: 'Common',
        fragmentPath: layout.fragmentPath('Common'),
        verdict: await recheck(),
        recheck,
        label: 'S00',
      });
      writePacket({
        layout,
        step: step.id,
        verdict: repaired.verdict,
        before,
        after: readIfExists(layout.fragmentPath('Common')),
        fragmentPath: layout.fragmentPath('Common'),
        rationales: [seed.rationale, ...repaired.rationales],
        todos: seed.preflightProblems,
      });
      return { verdict: repaired.verdict, iterations: repaired.iterations, blocked: repaired.verdict.blocking, ctx: next };
    }

    case 'REQ-INTAKE':
    case 'INFRA-INTAKE': {
      const layer = step.layer as Layer;
      const source = step.agent === 'REQ-INTAKE' ? opts.requirementsText : opts.infrastructureText;
      const result = await authorLayer(ctx, {
        step,
        layer,
        extra: [
          source
            ? `## What the customer supplied\n\n${source.trim()}`
            : 'The customer supplied no document for this lane. Model only what the brief already states, and say in `todos` what is missing.',
        ],
      });
      writePacket({
        layout: ctx.layout,
        step: step.id,
        verdict: result.verdict,
        before,
        after: readIfExists(result.fragmentPath),
        fragmentPath: result.fragmentPath,
        rationales: result.rationales,
        todos: result.todos,
      });
      return { verdict: result.verdict, iterations: result.iterations, blocked: result.blocked, ctx };
    }

    case 'TRANSITION': {
      const layer = step.layer as Layer;
      const from = previousAuthoredLayer(layer) as Layer;
      const assembly = assemble(ctx.layout, from);
      const skeleton = await ctx.backend.withModel(assembly.text, ctx.layout.buildPath(from), (m) =>
        generateSkeleton({
          rule: step.transition ?? 'T01',
          from: ctx.backend.layerView(m, from),
          root: ctx.layout.root,
          systemName: ctx.state.brief?.systemName ?? ctx.layout.root,
          systemEntity: ctx.state.brief?.systemEntity,
          memberDef: ctx.state.brief?.population?.memberDef,
          population: ctx.state.brief?.population,
          namedFunctions: [...(ctx.state.brief?.coordinationFunctions ?? []), ...(ctx.state.brief?.c2Functions ?? [])].map((f) => f.name),
        }),
      );
      writeFileSync(ctx.layout.fragmentPath(layer), skeleton.text);
      const verdict = await runStepChecks(step, {
        backend: ctx.backend,
        layout: ctx.layout,
        knobs: ctx.knobs,
        brief: briefFacts(ctx),
        docCoverageMin: ctx.config.limits.doc_coverage_min,
        auditDir: ctx.layout.auditDirFor(step.id),
      });
      ctx.log(
        `  carried: ${skeleton.carried.functions} function(s), ${skeleton.carried.flows} flow(s), ` +
          `${skeleton.carried.actors} actor(s), ${skeleton.carried.capabilities} capability(ies)`,
      );
      writePacket({
        layout: ctx.layout,
        step: step.id,
        verdict,
        before,
        after: skeleton.text,
        fragmentPath: ctx.layout.fragmentPath(layer),
        rationales: [`Generated by ${step.transition} from ${from}. Nothing here was invented: every element carries a realization link to the one it came from.`],
        extra: skeleton.carried,
      });
      return { verdict, iterations: 0, blocked: verdict.blocking, ctx };
    }

    case 'AUTHOR': {
      const layer = step.layer as Layer;
      // An author step that owns a transition rule (EPBS, T-04) generates its
      // own skeleton when nothing has been written for the layer yet: one
      // candidate configuration item per physical part, each already traced.
      // Measured: without it the layer was written from a blank page.
      if (step.transition && !existsSync(ctx.layout.fragmentPath(layer))) {
        const from = previousAuthoredLayer(layer) as Layer;
        const assembly = assemble(ctx.layout, from);
        const skeleton = await ctx.backend.withModel(assembly.text, ctx.layout.buildPath(from), (m) =>
          generateSkeleton({
            rule: step.transition!,
            from: ctx.backend.layerView(m, from),
            root: ctx.layout.root,
            systemName: ctx.state.brief?.systemName ?? ctx.layout.root,
            systemEntity: ctx.state.brief?.systemEntity,
            memberDef: ctx.state.brief?.population?.memberDef,
            population: ctx.state.brief?.population,
          }),
        );
        writeFileSync(ctx.layout.fragmentPath(layer), skeleton.text);
        ctx.log(`  ${step.id}: skeleton from ${step.transition} — ${skeleton.carried.parts} candidate item(s)`);
      }
      const skeleton = readIfExists(ctx.layout.fragmentPath(layer));
      const result = await authorLayer(ctx, { step, layer, skeleton });
      writePacket({
        layout: ctx.layout,
        step: step.id,
        verdict: result.verdict,
        before,
        after: readIfExists(result.fragmentPath),
        fragmentPath: result.fragmentPath,
        rationales: result.rationales,
        todos: result.todos,
      });
      return { verdict: result.verdict, iterations: result.iterations, blocked: result.blocked, ctx };
    }

    case 'ALTERNATIVES': {
      const layer = step.layer as Layer;
      const count = ctx.config.limits.n_alternatives[layer as 'LA' | 'PA'] ?? 2;
      const { results } = await authorAlternatives(ctx, step, layer, count);
      record.alternatives = results.map((r) => ({
        k: r.k,
        status: r.result.blocked ? 'blocked' : 'done',
        iterations: r.result.iterations,
      }));
      for (const r of results) {
        writePacket({
          layout: ctx.layout,
          step: step.id,
          verdict: r.result.verdict,
          after: readIfExists(r.result.fragmentPath),
          fragmentPath: r.result.fragmentPath,
          rationales: r.result.rationales,
          todos: r.result.todos,
          extra: { alternative: r.k, blocked: r.result.blocked },
        });
      }
      const usable = results.filter((r) => !r.result.blocked);
      ctx.log(`  ${usable.length} of ${count} alternative(s) cleared their checks`);
      return {
        verdict: results[0]?.result.verdict,
        iterations: Math.max(...results.map((r) => r.result.iterations), 0),
        // One good alternative is enough to choose from; none is not.
        blocked: usable.length === 0,
        ctx,
      };
    }

    case 'EVALUATE': {
      const layer = step.layer as Layer;
      // The candidates were written by the ALTERNATIVES step for this layer,
      // which is a different record: reading this step's own would evaluate an
      // empty list and block a run that has two perfectly good architectures.
      const source = STEPS.find((s) => s.agent === 'ALTERNATIVES' && s.layer === layer);
      const written = source ? ctx.state.steps[source.id]?.alternatives : undefined;
      const candidates = (written ?? []).filter((a) => a.status === 'done').map((a) => ({ k: a.k, iterations: a.iterations }));
      if (candidates.length === 0) {
        ctx.log(`  no alternative cleared its checks — nothing to choose between`);
        return { iterations: 0, blocked: true, ctx };
      }
      const evaluation = await evaluateAlternatives(
        ctx, step, layer, candidates,
        (written ?? []).map((a) => ({ k: a.k, status: a.status })),
      );
      for (const alt of written ?? []) {
        alt.chosen = alt.k === evaluation.chosen;
        alt.score = evaluation.scores.find((s) => s.k === alt.k)?.total;
      }
      ctx.log(`  chose alternative ${evaluation.chosen}${evaluation.overrode ? ' (the reviewing model preferred another)' : ''}`);
      const verdict = await runStepChecks(step, {
        backend: ctx.backend,
        layout: ctx.layout,
        knobs: ctx.knobs,
        brief: briefFacts(ctx),
        docCoverageMin: ctx.config.limits.doc_coverage_min,
        auditDir: ctx.layout.auditDirFor(step.id),
      });
      writePacket({
        layout: ctx.layout,
        step: step.id,
        verdict,
        before,
        after: readIfExists(ctx.layout.fragmentPath(layer)),
        fragmentPath: ctx.layout.fragmentPath(layer),
        rationales: [evaluation.rubric.rationale],
        extra: { chosen: evaluation.chosen, scores: evaluation.scores, metrics: evaluation.metrics },
      });
      return { verdict, iterations: 0, blocked: verdict.blocking, ctx };
    }

    case 'CHECK': {
      const verdict = await runStepChecks(step, {
        backend: ctx.backend,
        layout: ctx.layout,
        knobs: ctx.knobs,
        brief: briefFacts(ctx),
        docCoverageMin: ctx.config.limits.doc_coverage_min,
        auditDir: ctx.layout.auditDirFor(step.id),
      });
      writePacket({ layout: ctx.layout, step: step.id, verdict });
      // Bonus lane: it reports, it never stops the run (Q-04).
      return { verdict, iterations: 0, blocked: false, ctx };
    }

    case 'AUDIT': {
      if (step.id === 'S70') {
        const verdict = await runStepChecks(step, {
          backend: ctx.backend,
          layout: ctx.layout,
          knobs: ctx.knobs,
          brief: briefFacts(ctx),
        docCoverageMin: ctx.config.limits.doc_coverage_min,
          auditDir: ctx.layout.auditDirFor('final'),
        });
        await writeFinalAudit(ctx, verdict);
        writePacket({ layout: ctx.layout, step: step.id, verdict });
        return { verdict, iterations: 0, blocked: verdict.blocking, ctx };
      }
      writeIndex(ctx.layout, step.id, step.auditOf ?? []);
      return { iterations: 0, blocked: false, ctx };
    }

    default: {
      const never: never = step.agent;
      throw new Error(`no runner for agent ${String(never)}`);
    }
  }
}

/* ────────────────────────────── small parts ─────────────────────────────── */

function gateRequest(gate: GateId, step: StepSpec, verdict: Verdict | undefined, layout: ModelLayout): GateRequest {
  const items = verdict?.items ?? [];
  const blocking = items.filter((i) => i.blocking);
  return {
    gate,
    step: step.id,
    layer: step.layer,
    blocked: blocking.length > 0,
    summary: [
      `${step.id} ${step.name}${step.layer ? ` (${step.layer})` : ''}`,
      verdict ? `  ${verdict.elementCount} elements, ${verdict.checks.length} checks, ${blocking.length} blocking finding(s)` : '',
      `  packet: ${layout.auditDirFor(step.id)}`,
      ...blocking.slice(0, 10).map((i) => `  - ${i.code} ${i.qualifiedName ?? ''}: ${i.message}`),
    ]
      .filter(Boolean)
      .join('\n'),
    auditDir: layout.auditDirFor(step.id),
    items: items.map((i) => ({ code: i.code, message: i.message, blocking: i.blocking })),
    at: new Date().toISOString(),
  };
}

function clearDecision(layout: ModelLayout, gate: GateId): void {
  const path = layout.gateDecisionPath(gate);
  if (existsSync(path)) writeFileSync(`${path}.${Date.now()}.used`, readFileSync(path, 'utf8'));
  if (existsSync(path)) writeFileSync(path, '');
  if (existsSync(path)) {
    // Emptied rather than deleted: the record of what was decided stays beside
    // the run, and the wait loop only accepts a file it can parse.
  }
}

function writeIndex(layout: ModelLayout, step: StepId, covers: StepId[]): void {
  const dir = layout.auditDirFor(step);
  mkdirSync(dir, { recursive: true });
  writeFileSync(
    resolve(dir, 'index.md'),
    [`# ${step}`, '', 'This packet covers:', '', ...covers.map((c) => `- [${c}](../${c}/rationale.md)`), ''].join('\n'),
  );
}

export { writeBuild };
