/**
 * What each agent is asked to return.
 *
 * Every call is one prompt and one structured answer — no tool use, no
 * conversation. The schema is handed to the model as a JSON schema and the
 * answer is validated against the same zod object, so a malformed answer is
 * caught before any of it reaches a file, let alone Sysprose.
 */
import { z } from 'zod';

export const MoeSchema = z.object({
  name: z.string().describe('camelCase attribute name, e.g. missionEnduranceMinutes'),
  unit: z.string().describe('unit of measure, or "" when the measure is a count or a ratio'),
  sense: z.enum(['min', 'max']).describe('is a smaller or a larger value better'),
  target: z.number().describe('the value the requirement holds the design to'),
  doc: z.string().describe('one sentence: what this measures and why it decides between architectures'),
  placeholder: z
    .boolean()
    .optional()
    .describe('true when the brief says this number is a placeholder awaiting the customer\'s: the target is used, and every report says it is not the customer\'s'),
  kind: z
    .enum(['measure', 'budget'])
    .optional()
    .describe('"budget" when the brief FIXES the number (a fleet it can field, a time an operator has): held as a requirement, never scored; "measure" (the default) when architectures can do better or worse on it'),
});

/**
 * A system made of N identical members (a swarm, a fleet, a constellation).
 *
 * Without this the brief had one place for "twelve drones" — a MoE target —
 * and nothing downstream was obliged to instantiate it: three runs modelled
 * one drone and a ground station, and the number 12 surfaced only as a
 * configuration-item multiplicity at the last layer.
 */
export const PopulationSchema = z.object({
  memberDef: z.string().describe('PascalCase part definition of ONE member, e.g. SwarmMember — the replicable element every layer instantiates'),
  fleetPart: z.string().describe('camelCase usage that carries the population and its multiplicity, e.g. fleet'),
  size: z.number().int().min(2).describe('how many members the design is sized for'),
  meshPort: z.string().describe('the port definition in package Common a member exchanges with a peer through'),
  meshInterface: z.string().describe('the interface definition in package Common that joins two members'),
  coordinationCapability: z.string().describe('the capability (by its name in `capabilities`) that is coordination between members'),
  bearer: z.string().optional().describe('the environment resource that carries member-to-member traffic, e.g. the radio link, when there is one'),
  doc: z.string().describe('one sentence: what the members are and why they must interact'),
});
export type Population = z.infer<typeof PopulationSchema>;

export const NamedFunctionSchema = z.object({
  name: z.string().describe('camelCase verb phrase, not a SysML keyword (assign, accept and send are keywords)'),
  doc: z.string(),
});

/** A hazard the customer already knows about, stated in the brief. */
export const BriefHazardSchema = z.object({
  name: z.string().describe('PascalCase ending in Hazard, e.g. PositionDriftHazard'),
  doc: z.string().describe('one sentence: what goes wrong, in the brief\'s words'),
});

/**
 * A rule the system never breaks, written so a model checker can refute it.
 *
 * Three kinds only, because they are the ones the in-process checker decides
 * on a state machine without an unreachable state: `winsUntil` (once Q, never
 * P until R — "a recall wins until the drone lands"), `precededBy` (P only
 * after S — "no watching before clearance"), `canAlwaysReturn` (P reachable
 * from everywhere — "an isolated drone can always get home"). A plain "never
 * P" needs a state P that exists and is never reached, which the reachability
 * gate forbids.
 */
export const BriefRuleSchema = z.object({
  name: z.string().describe('PascalCase, e.g. RecallWins'),
  doc: z.string().describe('the rule in the brief\'s words'),
  kind: z.enum(['winsUntil', 'precededBy', 'canAlwaysReturn']),
  of: z.enum(['member', 'fleet', 'ground', 'system']).describe('whose state machine carries it: one member, the fleet as a whole, the ground, or the system when there is no population'),
});

/** An operating mode the brief names. */
export const BriefModeSchema = z.object({
  name: z.string().describe('PascalCase state name, e.g. NavigationDegraded'),
  doc: z.string(),
  of: z.enum(['member', 'fleet', 'ground', 'system']),
});

/** What a flowing item must carry, when the brief lists its fields. */
export const BriefItemSchema = z.object({
  name: z.string().describe('PascalCase item def name in package Common, e.g. DetectionReport'),
  fields: z.array(z.object({ name: z.string().describe('camelCase attribute name'), doc: z.string() })).min(1),
});

export const SeedOutputSchema = z.object({
  systemName: z
    .string()
    .describe('PascalCase, no spaces: the root package and the system definition are named from this'),
  systemEntity: z
    .string()
    .describe(
      'camelCase name of the operational entity the system will take over — the OA entity whose activities become system functions. The OA author declares `part <systemEntity>` by exactly this name, untagged. When a population exists it is one representative member, typed by population.memberDef.',
    ),
  mission: z.string().describe('one sentence, from the environment quadrants: what the system is for'),
  functionSentence: z
    .string()
    .describe('<System> <verb>s <object> from <state> to <state> — one sentence, the seed of the whole model'),
  stakeholders: z.array(z.object({ name: z.string(), role: z.string() })).min(1),
  environment: z
    .array(z.object({ name: z.string(), quadrant: z.enum(['input', 'output', 'constraining', 'resource']), doc: z.string() }))
    .min(1)
    .describe('the environment diagram: what comes in, what goes out, what constrains, what supplies'),
  capabilities: z.array(z.object({ name: z.string().describe('PascalCase'), doc: z.string() })).min(1),
  moes: z.array(MoeSchema).min(1).describe('the measures the architecture alternatives will be scored against'),
  population: PopulationSchema.optional().describe('present only when the system is several identical members that interact with each other'),
  coordinationFunctions: z
    .array(NamedFunctionSchema)
    .optional()
    .describe('what members settle between themselves (handover, rotation, redistribution, deconfliction, relay); each becomes a #Coordination function from SA down; empty when there is no population'),
  c2Functions: z
    .array(NamedFunctionSchema)
    .optional()
    .describe('command and control an operator exercises over the whole system (tasking, supervision, recall, status picture, acknowledgement); each becomes a #C2 function from SA down'),
  hazards: z.array(BriefHazardSchema).optional().describe('ONLY the hazards the brief itself names; empty when it names none. Never invent one here — each layer states the hazards it finds.'),
  rules: z.array(BriefRuleSchema).optional().describe('ONLY the rules the brief says the system never breaks; empty when it states none'),
  modes: z.array(BriefModeSchema).optional().describe('ONLY the operating modes the brief names; empty when it names none'),
  items: z.array(BriefItemSchema).optional().describe('ONLY the items whose fields the brief lists (what a report carries, say); each is an item def in package Common with exactly these attributes'),
  extraKinds: z
    .array(z.string())
    .describe('extra #Keyword tags this model needs beyond the standard set, PascalCase, may be empty'),
  commonFragment: z
    .string()
    .describe(
      'the whole `package Common { … }` fragment: item definitions, port definitions and interface definitions every layer shares, plus the #MoE attributes on nothing yet. No layer content.',
    ),
  rationale: z.string().describe('why this framing, in a few sentences — it goes into the audit packet'),
});
export type SeedOutput = z.infer<typeof SeedOutputSchema>;
export type Moe = z.infer<typeof MoeSchema>;

export const FragmentOutputSchema = z.object({
  fragment: z.string().describe('exactly one `package <Layer> { … }` — no root package, no imports, no markdown fence'),
  rationale: z.string().describe('what you decided and why; it goes into the audit packet, not into the model'),
  todos: z.array(z.string()).describe('what you deliberately left for a later step, may be empty'),
  commonAdditions: z
    .array(z.string())
    .describe('declarations that belong in package Common because more than one layer needs them, may be empty'),
});
export type FragmentOutput = z.infer<typeof FragmentOutputSchema>;

export const ComponentsOutputSchema = z.object({
  declarations: z
    .string()
    .describe(
      'ONLY the declarations of this architecture: part definitions, parts, their ports, connections and interfaces between them, component state definitions, and one `allocate <function> to <part>;` per function. No `package` wrapper, no functions, no flows, no trace lines — those are already in the layer and are added around your answer.',
    ),
  rationale: z.string().describe('what split of responsibilities this is and why; it goes into the audit packet'),
  todos: z.array(z.string()).describe('what you deliberately left for a later step, may be empty'),
  commonAdditions: z
    .array(z.string())
    .describe('declarations that belong in package Common because more than one layer needs them, may be empty'),
});
export type ComponentsOutput = z.infer<typeof ComponentsOutputSchema>;

export const RepairOutputSchema = z.object({
  fragment: z.string().describe('the whole corrected fragment, same shape as before'),
  rationale: z.string().describe('what was wrong and what you changed'),
  touched: z.array(z.string()).describe('the elements you changed, by name'),
  commonAdditions: z
    .array(z.string())
    .describe(
      'declarations to add to package Common, when the fix is a shared definition that is missing (an item def a flow or a trigger needs, a port def). Without this the only way to fix an unresolved shared type is to delete the reference. May be empty.',
    )
    .default([]),
});
export type RepairOutput = z.infer<typeof RepairOutputSchema>;

export const EvaluateOutputSchema = z.object({
  scores: z.array(
    z.object({
      alternative: z.number().int().describe('the alternative number, as given'),
      criteria: z.array(
        z.object({
          name: z.string(),
          score: z.number().min(1).max(5),
          reason: z.string(),
        }),
      ),
    }),
  ),
  recommended: z.number().int().describe('the alternative you would choose'),
  rationale: z.string().describe('the comparison, in a few sentences — this is what a reviewer reads first'),
});
export type EvaluateOutput = z.infer<typeof EvaluateOutputSchema>;

export const AuditSummarySchema = z.object({
  summary: z.string().describe('what this step produced and what it decided, in a few sentences'),
  openIssues: z.array(z.string()).describe('what a reviewer should look at, may be empty'),
});
export type AuditSummary = z.infer<typeof AuditSummarySchema>;
