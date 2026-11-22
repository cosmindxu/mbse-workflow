/**
 * The bonus lane runs `sysprose variability`: the product families a model
 * writes, and each configuration's verdict under the command's own exit
 * contract (0 holds; 1 invalid, violated or void; 2 undecided or nothing to read).
 */
import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { InProcessBackend } from '../../src/sysprose/inprocess.ts';
import type { Loaded } from '../../src/sysprose/backend.ts';
import { meaningOf } from '../../src/sysprose/envelope.ts';
import { runSysprose } from '../../src/sysprose/spawn.ts';
import { variabilityLane, variabilityMarkdown } from '../../src/audit/final.ts';
import { step } from '../../src/spec/steps.ts';

const DIR = process.env.SYSPROSE_DIR ?? resolve(process.env.HOME ?? '', 'sysprose');
const backend = new InProcessBackend({ dir: DIR, expectedCommit: 'a66ba1f' });
const FAMILY = readFileSync(resolve(import.meta.dirname, '../fixtures/variability/sensor-family.sysml'), 'utf8');
const run = (text: string) => backend.withModel(text, 'family.sysml', (m: Loaded) => backend.variability(m));

describe('the variability check of the bonus lane', () => {
  it('is a non-blocking check of S60', () => {
    const s60 = step('S60');
    expect(s60.checks.find((c) => c.cmd === 'variability')).toMatchObject({ name: 'variability', blocking: false });
  });

  it('decides the fixture family: both configurations hold, the thermal head never runs on the battery', async () => {
    const r = await run(FAMILY);
    expect(r.exitCode).toBe(0);
    const o = r.owners[0];
    expect(o.status).toBe('read');
    expect(o.analysis).toMatchObject({ structural: 4, valid: 3, exact: true, void: false });
    expect(o.configurations.map((c) => [c.name.split('::').pop(), c.status])).toEqual([
      ['fieldKit', 'holds'],
      ['plantSurvey', 'holds'],
    ]);
    const md = variabilityMarkdown(variabilityLane(r)).join('\n');
    expect(md).toContain('`InspectionPlatform`: 3 valid configuration(s) of 4');
    expect(md).toContain('  - `fieldKit`: holds');
  });

  it('a violated configuration is a decided negative: exit 1, and the audit says violated', async () => {
    const r = await run(FAMILY.replace('power = power::longTether', 'power = power::standardBattery'));
    expect(r.exitCode).toBe(1);
    expect(meaningOf('variability', r.exitCode)).toContain('violated');
    expect(variabilityMarkdown(variabilityLane(r)).join('\n')).toContain('  - `plantSurvey`: **violated**');
  });

  it('a model with no family is undecided, never an all-clear, and the audit says there is nothing to configure', async () => {
    const r = await run('package P { part def A; part a : A; }');
    expect(r.exitCode).toBe(2);
    expect(variabilityMarkdown(variabilityLane(r)).join('\n')).toContain('writes no product family');
  });

  it('the in-process payload is what the CLI prints, with the same exit code and its meaning', async () => {
    const cli = await runSysprose<{ exitCode: number; owners: unknown[] }>({ dir: DIR }, 'variability', [], FAMILY);
    const own = await run(FAMILY);
    expect(cli.exitCode).toBe(0);
    expect(cli.contract).toBe('variability');
    expect(cli.meaning).toBe(meaningOf('variability', 0));
    const strip = (o: unknown) => JSON.parse(JSON.stringify(o, (k, v) => (k === 'id' || k === 'elementId' || k === 'key' || k === 'referenced' || k === 'activatedBy' ? undefined : v)));
    expect(strip(cli.payload)).toEqual(strip(own));
  }, 120_000);
});
