import type { WorkflowConfig } from '../config/schema.ts';
import type { ModelLayout } from '../model/layout.ts';
import type { SysproseBackend } from '../sysprose/backend.ts';
import type { LlmClient } from '../llm/client.ts';
import type { RunState } from '../orch/state.ts';
import type { Knobs } from '../check/classify.ts';

export interface AgentContext {
  config: WorkflowConfig;
  layout: ModelLayout;
  backend: SysproseBackend;
  llm: LlmClient;
  state: RunState;
  knobs: Knobs;
  log: (message: string) => void;
}

/** The standard tag vocabulary every model of this workflow declares. */
export const STANDARD_KINDS = [
  ['OA', 'SA', 'LA', 'PA', 'EPBS'],
  ['Mission', 'Capability', 'Chain', 'Actor'],
  ['Logical', 'Behaviour', 'Node'],
  ['Mode', 'State'],
  ['Hazard', 'Accepted', 'Rule', 'MoE', 'Estimate', 'Variant'],
  ['Member', 'Coordination', 'C2', 'Configuration'],
  ['Imposed', 'Standard', 'Customer'],
  ['CI_CSCI', 'CI_HWCI', 'CI_COTS', 'CI_TBD'],
];

export function kindsFragment(extra: readonly string[]): string {
  const lines = [
    '    package Kinds {',
    '        doc /* User-defined keywords (CV-02): layer, structural role, mode and lifecycle tags.',
    '               Every `#Tag` used anywhere in this model is declared here. */',
    ...STANDARD_KINDS.map((group) => `        ${group.map((k) => `metadata def ${k};`).join(' ')}`),
  ];
  const clean = [...new Set(extra.map((k) => k.trim()).filter((k) => /^[A-Za-z_][A-Za-z0-9_]*$/.test(k)))].filter(
    (k) => !STANDARD_KINDS.flat().includes(k),
  );
  if (clean.length > 0) {
    lines.push('        // asked for by the brief', `        ${clean.map((k) => `metadata def ${k};`).join(' ')}`);
  }
  lines.push('    }');
  return `${lines.join('\n')}\n`;
}
