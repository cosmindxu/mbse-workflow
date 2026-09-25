import { existsSync, readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { resolve } from 'node:path';
import { parse } from 'yaml';
import { ConfigSchema, type WorkflowConfig } from './schema.ts';

export interface ConfigOverrides {
  sysproseDir?: string;
  llmBackend?: 'claude' | 'fake';
  model?: string;
  budgetUsd?: number;
  knobs?: Partial<WorkflowConfig['knobs']>;
  limits?: Partial<WorkflowConfig['limits']>;
}

/** Read `config/workflow.yaml` (or a path), apply overrides, fill in defaults. */
export function loadConfig(path?: string, overrides: ConfigOverrides = {}): WorkflowConfig {
  const file = path ?? resolve(import.meta.dirname, '../../config/workflow.yaml');
  const raw = existsSync(file) ? (parse(readFileSync(file, 'utf8')) as unknown) : {};
  const config = ConfigSchema.parse(raw ?? {});
  if (overrides.sysproseDir) config.sysprose.dir = overrides.sysproseDir;
  if (!config.sysprose.dir) config.sysprose.dir = process.env.SYSPROSE_DIR ?? resolve(homedir(), 'sysprose');
  if (overrides.llmBackend) config.llm.backend = overrides.llmBackend;
  if (overrides.model) config.llm.models = { ...config.llm.models, default: overrides.model };
  if (overrides.budgetUsd !== undefined) config.limits.run_budget_usd = overrides.budgetUsd;
  if (overrides.knobs) config.knobs = { ...config.knobs, ...overrides.knobs };
  if (overrides.limits) config.limits = { ...config.limits, ...overrides.limits };
  return config;
}

export const modelFor = (config: WorkflowConfig, agent: string): string =>
  config.llm.models[agent] ?? config.llm.models.default ?? 'sonnet';
