/**
 * The run's settings.
 *
 * The knobs are the ones the decision record fixed (05-decision.md §5) and
 * their defaults are the ones the user confirmed. Everything here is data a
 * reader can change without touching code; what is NOT here is the step table,
 * because a step's checks and post-conditions are the workflow, not a setting.
 */
import { z } from 'zod';

export const KnobsSchema = z
  .object({
    modes_states: z.boolean().default(true),
    interfaces: z.boolean().default(true),
    variability: z.boolean().default(true),
    safety: z.boolean().default(true),
    views: z.boolean().default(false),
    verification: z.boolean().default(true),
    requirements_intake: z.boolean().default(false),
    infrastructure_intake: z.boolean().default(false),
  })
  .default({});

export const LimitsSchema = z
  .object({
    /** How many times a fragment goes back to REPAIR before the step is blocked. */
    repair_iterations: z.number().int().min(0).default(3),
    n_alternatives: z.object({ LA: z.number().int().min(1).default(2), PA: z.number().int().min(1).default(2) }).default({}),
    /** Below this, the whole assembled model is handed to the author. */
    full_prefix_max_elements: z.number().int().default(200),
    prompt_max_chars: z.number().int().default(60_000),
    /** `claude` processes at once. Sysprose runs one at a time regardless. */
    llm_concurrency: z.number().int().min(1).default(2),
    /**
     * 15 minutes, measured rather than guessed: an opus call that writes a whole
     * package runs past 300 s, and a timeout throws the answer away — three
     * retries of a call that was going to succeed cost a quarter of an hour.
     */
    llm_call_timeout_ms: z.number().int().default(900_000),
    /** Output tokens per turn the CLI may spend; 0 leaves the CLI's default (64k for Claude 5). */
    llm_max_output_tokens: z.number().int().min(0).default(128_000),
    run_budget_usd: z.number().default(25),
    /** Share of a layer's own elements that must carry a doc. 0 turns the gate off. */
    doc_coverage_min: z.number().min(0).max(1).default(0.8),
    per_call_budget_usd: z.number().optional(),
  })
  .default({});

export const ModeSchema = z.enum(['autonomous', 'gated', 'reviewed', 'contributor']);
export type RunMode = z.infer<typeof ModeSchema>;

export const GATES_BY_MODE: Record<RunMode, string[]> = {
  autonomous: ['G-SEED', 'G-FINAL'],
  gated: ['G-SEED', 'G-LA', 'G-PA', 'G-FINAL'],
  reviewed: ['G-SEED', 'G-OA', 'G-SA', 'G-LA', 'G-PA', 'G-EPBS', 'G-FINAL'],
  contributor: ['G-SEED', 'G-LA', 'G-PA', 'G-FINAL'],
};

export const ConfigSchema = z.object({
  knobs: KnobsSchema,
  limits: LimitsSchema,
  llm: z
    .object({
      backend: z.enum(['claude', 'fake']).default('claude'),
      /** Per-agent model overrides; `default` covers the rest. */
      models: z.record(z.string()).default({ default: 'sonnet', SEED: 'opus', EVALUATE: 'opus' }),
    })
    .default({}),
  sysprose: z
    .object({
      dir: z.string().default(''),
      expected_commit: z.string().default('a66ba1f'),
    })
    .default({}),
  evaluate: z
    .object({
      /** How the alternatives are scored. The rubric is one input among these. */
      weights: z
        .object({
          moe: z.number().default(0.4),
          rubric: z.number().default(0.35),
          structure: z.number().default(0.25),
          // Only scored when the system is a population; neutral (0.5) otherwise.
          resilience: z.number().default(0),
        })
        .default({}),
      /**
       * What accepting a hazard costs: taken off the structure score per hazard
       * the alternative tags #Accepted, up to `cap`. Without it a design that
       * accepts a risk scored the same as one that mitigates it (v5's PA: 4 vs 1).
       */
      accepted_hazard_penalty: z
        .object({ per: z.number().default(0.05), cap: z.number().default(0.25) })
        .default({}),
    })
    .default({}),
});

export type WorkflowConfig = z.infer<typeof ConfigSchema>;
export type Knobs = z.infer<typeof KnobsSchema>;
export type Limits = z.infer<typeof LimitsSchema>;
