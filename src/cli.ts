#!/usr/bin/env -S npx tsx
/**
 * `mbse-workflow` — run the workflow, or look at one that ran.
 *
 * Five verbs: `run` starts one, `resume` picks it up, `status` says where it
 * got to, `gate` is how a person answers a gate, and `check` re-runs one step's
 * checks against what is on disk (which is also how a contributor's edit is
 * verified before the run continues).
 */
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { Command } from 'commander';
import { loadConfig } from './config/load.ts';
import { GATES_BY_MODE, ModeSchema, type RunMode } from './config/schema.ts';
import { InProcessBackend } from './sysprose/inprocess.ts';
import { ClaudeCliClient } from './llm/claude-cli.ts';
import { FakeLlmClient } from './llm/fake.ts';
import { AutoGate, FileGate, TtyGate, type GateController } from './orch/gates.ts';
import { runWorkflow } from './orch/machine.ts';
import { loadState } from './orch/state.ts';
import { makeLayout } from './model/layout.ts';
import { runStepChecks } from './check/checker.ts';
import { briefFactsOf } from './agents/author.ts';
import { STEPS, step as stepById, type GateId, type StepId } from './spec/steps.ts';
import { isLayer, type Layer } from './spec/layers.ts';
import type { Knobs } from './check/classify.ts';
import { readCallLog, unrecordedSpend } from './audit/contribution.ts';
import { simulationInputOf } from './realization/adapter.ts';
import { simulationOf } from './realization/simulation.ts';

const program = new Command();
program.name('mbse-workflow').description('layered model authoring, gated on Sysprose checks').version('0.1.0');

program
  .command('run')
  .description('run the workflow from a brief')
  .requiredOption('--brief <path>', 'the brief: a markdown or text file describing the system to model')
  .requiredOption('--out <dir>', 'where the model, the packets and the state go')
  .option('--mode <mode>', 'autonomous | gated | reviewed | contributor', 'autonomous')
  .option('--unattended', 'take every gate automatically and never wait for a person', false)
  .option('--llm <backend>', 'claude | fake', 'claude')
  .option('--model <name>', 'model for the agents that have no override')
  .option('--budget-usd <amount>', 'stop before spending more than this', parseFloat)
  .option('--sysprose <dir>', 'the Sysprose checkout to drive')
  .option('--requirements <path>', 'customer requirements, for the requirement lane')
  .option('--infrastructure <path>', 'existing infrastructure, for the brownfield lane')
  .option('--from-step <id>', 're-enter at this step')
  .option('--config <path>', 'settings file (default: config/workflow.yaml)')
  .action(async (opts) => {
    const mode = ModeSchema.parse(opts.mode) as RunMode;
    const config = loadConfig(opts.config, {
      sysproseDir: opts.sysprose,
      llmBackend: opts.llm,
      model: opts.model,
      budgetUsd: opts.budgetUsd,
      knobs: {
        requirements_intake: opts.requirements !== undefined,
        infrastructure_intake: opts.infrastructure !== undefined,
      },
    });
    mkdirSync(opts.out, { recursive: true });
    const layout = makeLayout(opts.out, 'System');
    const backend = new InProcessBackend({ dir: config.sysprose.dir, expectedCommit: config.sysprose.expected_commit });
    const llm =
      config.llm.backend === 'fake'
        ? new FakeLlmClient({})
        : new ClaudeCliClient({
            concurrency: config.limits.llm_concurrency,
            defaultModel: config.llm.models.default,
            timeoutMs: config.limits.llm_call_timeout_ms,
            maxOutputTokens: config.limits.llm_max_output_tokens,
            runBudgetUsd: config.limits.run_budget_usd,
            maxBudgetUsd: config.limits.per_call_budget_usd,
            logPath: layout.llmLogPath,
          });

    const result = await runWorkflow({
      dir: opts.out,
      mode,
      config,
      backend,
      llm,
      gates: gateController(opts, layout),
      briefText: readFileSync(opts.brief, 'utf8'),
      requirementsText: opts.requirements ? readFileSync(opts.requirements, 'utf8') : undefined,
      infrastructureText: opts.infrastructure ? readFileSync(opts.infrastructure, 'utf8') : undefined,
      fromStep: opts.fromStep as StepId | undefined,
    });
    report(result.state, result.layout.dir);
    if (result.finalPath && existsSync(result.finalPath)) {
      process.stdout.write(`\nmodel: ${result.finalPath}\naudit: ${result.layout.auditDirFor('final')}\n`);
    }
    process.exitCode = Object.values(result.state.steps).some((s) => s?.status === 'blocked') ? 1 : 0;
  });

program
  .command('resume')
  .description('continue a run where it stopped')
  .requiredOption('--out <dir>', 'the run directory')
  .option('--unattended', 'take every gate automatically', false)
  .option('--from-step <id>', 're-enter at this step')
  .option('--budget-usd <amount>', 'ceiling for this leg of the run', parseFloat)
  .option('--model <name>', 'model for the agents that have no override')
  .option('--sysprose <dir>', 'the Sysprose checkout to drive')
  .option('--config <path>', 'settings file')
  .action(async (opts) => {
    const state = loadState(resolve(opts.out, 'state.json'));
    if (!state) throw new Error(`no run in ${opts.out}`);
    // The budget counts this leg, not the whole history: what was already spent
    // bought the fragments that are on disk.
    const config = loadConfig(opts.config, {
      budgetUsd: opts.budgetUsd,
      model: opts.model,
      sysproseDir: opts.sysprose,
    });
    const layout = makeLayout(opts.out, state.root);
    const backend = new InProcessBackend({ dir: config.sysprose.dir, expectedCommit: config.sysprose.expected_commit });
    const llm = new ClaudeCliClient({
      concurrency: config.limits.llm_concurrency,
      defaultModel: config.llm.models.default,
      timeoutMs: config.limits.llm_call_timeout_ms,
      maxOutputTokens: config.limits.llm_max_output_tokens,
      runBudgetUsd: config.limits.run_budget_usd,
      logPath: layout.llmLogPath,
    });
    const result = await runWorkflow({
      dir: opts.out,
      mode: state.mode,
      config,
      backend,
      llm,
      gates: gateController(opts, layout),
      briefText: existsSync(layout.briefPath) ? readFileSync(layout.briefPath, 'utf8') : '',
      fromStep: opts.fromStep as StepId | undefined,
    });
    report(result.state, result.layout.dir);
  });

program
  .command('status')
  .description('where a run got to')
  .requiredOption('--out <dir>', 'the run directory')
  .action((opts) => {
    const state = loadState(resolve(opts.out, 'state.json'));
    if (!state) throw new Error(`no run in ${opts.out}`);
    report(state, opts.out);
  });

program
  .command('gate')
  .description('answer a gate a run is waiting on')
  .requiredOption('--out <dir>', 'the run directory')
  .requiredOption('--gate <id>', 'G-SEED | G-OA | G-SA | G-LA | G-PA | G-EPBS | G-FINAL')
  .option('--approve', 'record the decision and let the run go on — a step that is blocked still stops', false)
  .option('--reject <comments>', 'send it back, with what to change')
  .action((opts) => {
    const state = loadState(resolve(opts.out, 'state.json'));
    const layout = makeLayout(opts.out, state?.root ?? 'System');
    mkdirSync(layout.gatesDir, { recursive: true });
    const decision = opts.approve
      ? { decision: 'approve' as const }
      : { decision: 'reject' as const, comments: typeof opts.reject === 'string' ? opts.reject : undefined };
    writeFileSync(layout.gateDecisionPath(opts.gate as GateId), `${JSON.stringify(decision, null, 2)}\n`);
    process.stdout.write(`${opts.gate}: ${decision.decision}${decision.comments ? ` — ${decision.comments}` : ''}\n`);
  });

program
  .command('check')
  .description("re-run one step's checks against what is on disk")
  .requiredOption('--out <dir>', 'the run directory')
  .option('--step <id>', 'the step whose checks to run')
  .option('--layer <layer>', 'the layer to check (picks that layer\'s authoring step)')
  .option('--alt <k>', 'an alternative rather than the layer itself', (v) => parseInt(v, 10))
  .option('--config <path>', 'settings file')
  .option('--root <name>', 'root package name, when there is no state file')
  .action(async (opts) => {
    const state = loadState(resolve(opts.out, 'state.json'));
    const config = loadConfig(opts.config);
    const layout = makeLayout(opts.out, opts.root ?? state?.root ?? 'System');
    const backend = new InProcessBackend({ dir: config.sysprose.dir, expectedCommit: config.sysprose.expected_commit });
    const id = opts.step ?? stepForLayer(opts.layer);
    const spec = stepById(id as StepId);
    const knobs = (state?.knobs ?? config.knobs) as Knobs;
    const verdict = await runStepChecks(spec, {
      backend,
      layout,
      knobs,
      alternative: opts.alt,
      docCoverageMin: config.limits.doc_coverage_min,
      substitute:
        opts.alt !== undefined && spec.layer
          ? { [spec.layer]: readFileSync(layout.fragmentPath(spec.layer as Layer, opts.alt), 'utf8') }
          : undefined,
      brief: state?.brief ? briefFactsOf(state.brief) : undefined,
    });
    process.stdout.write(
      `${spec.id} ${spec.name}: ${verdict.blocking ? 'blocking' : 'clear'} — ${verdict.elementCount} elements, ${verdict.items.length} finding(s)\n`,
    );
    for (const item of verdict.items) {
      process.stdout.write(`  ${item.blocking ? 'BLOCK' : 'note '} ${item.code} ${item.qualifiedName ?? ''}: ${item.message}\n`);
    }
    process.exitCode = verdict.blocking ? 1 : 0;
  });

function gateController(opts: { unattended?: boolean; mode?: string }, layout: ReturnType<typeof makeLayout>): GateController {
  if (opts.unattended) return new AutoGate();
  return process.stdin.isTTY ? new TtyGate() : new FileGate(layout);
}

function stepForLayer(layer?: string): string {
  if (!layer || !isLayer(layer)) throw new Error('pass --step, or --layer with one of Kinds Common Needs Imposed OA SA LA PA EPBS');
  const authoring = STEPS.filter((s) => s.layer === layer && s.checks.length > 0);
  const last = authoring[authoring.length - 1];
  if (!last) throw new Error(`no step authors ${layer}`);
  return last.id;
}

function report(state: ReturnType<typeof loadState>, dir: string): void {
  if (!state) return;
  const rows = STEPS.map((s) => {
    const r = state.steps[s.id];
    return `  ${s.id.padEnd(4)} ${s.name.padEnd(22)} ${(r?.status ?? 'pending').padEnd(8)} ${
      r?.iterations ? `${r.iterations} repair(s)` : ''
    }${r?.gate ? ` gate:${r.gate.decision}` : ''}${r?.note ? ` — ${r.note}` : ''}`;
  });
  process.stdout.write(
    [
      `${state.root} — ${state.mode} mode, gates armed: ${GATES_BY_MODE[state.mode].join(' ')}`,
      `  ${dir}`,
      `  ${state.llm.calls} model call(s), ${state.llm.costUsd.toFixed(2)} USD, ${Math.round(state.llm.durationMs / 1000)} s${(state.legs?.length ?? 1) > 1 ? ` over ${state.legs!.length} legs` : ''}`,
      ...((note) => (note ? [`  ${note}`] : []))(unrecordedSpend(state.llm, readCallLog(resolve(dir, 'audit', 'llm-log.jsonl')))),
      ...(state.llm.killed
        ? [`  ${state.llm.killed} call(s) killed by the timeout: they may be billed and report no cost, so the total is a floor`]
        : []),
      '',
      ...rows,
      '',
    ].join('\n'),
  );
}

program
  .command('simulate')
  .description('generate the simulation of a finished run: a world, a fleet, a scenario')
  .requiredOption('--out <dir>', 'the run directory')
  .option('--config <path>', 'settings file')
  .option(
    '--time-scale <n>',
    'wall-clock compression: 10 turns a 40-minute flight into 4 minutes',
    (v) => parseFloat(v),
    10,
  )
  .option('--into <dir>', 'where to write the artefacts (default: <out>/sim)')
  .action(async (opts) => {
    const config = loadConfig(opts.config);
    const backend = new InProcessBackend({
      dir: config.sysprose.dir,
      expectedCommit: config.sysprose.expected_commit,
    });
    const input = await simulationInputOf(opts.out, backend, { timeScale: opts.timeScale });
    const output = simulationOf(input);

    const into = resolve(opts.into ?? resolve(opts.out, 'sim'));
    mkdirSync(into, { recursive: true });
    for (const [name, body] of Object.entries(output.files)) {
      // Artefact names carry directories now — one model per member lives
      // under `models/` — so the parent has to exist before the write.
      const path = resolve(into, name);
      mkdirSync(dirname(path), { recursive: true });
      writeFileSync(path, body);
    }

    process.stdout.write(
      [
        `${input.root}: ${input.population?.size ?? 0} \u00d7 ${input.population?.memberDef} ` +
          `over ${input.budgets.areaOfInterestKm2 ?? '?'} km\u00b2`,
        `  ${Object.keys(output.files).length} artefact(s) in ${into}`,
        `  ${input.memberMachines.length} machine(s), ` +
          `${input.memberMachines.reduce((n, m) => n + m.states.length, 0)} state(s) mapped`,
        `  ${input.nodes.length} #Node part(s), ${input.coordination.length} coordination ` +
          `function(s), ${input.rules.length} rule(s) to monitor`,
        `  ${input.measures.length} measure(s) as acceptance criteria`,
        '',
        'What it assumes, and every generated file says so too:',
        ...output.assumptions.map((line) => `  - ${line}`),
        '',
        // The runtime is WP2; until it exists, say so rather than implying a
        // `simulate` that flies anything.
        'This generates the simulation. Running it needs the runtime in `sim/` (WP2).',
        '',
      ].join('\n'),
    );
  });

await program.parseAsync(process.argv);
