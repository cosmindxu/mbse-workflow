/**
 * The dialect facts CV-16 rests on, pinned.
 *
 * A population is a member definition, a usage carrying the multiplicity, and
 * two named representatives joined through a directed port pair. Each of those
 * choices was forced by the checker: indexed ends do not parse, an undirected
 * port is a warning, and a symmetric pair checks clean but leaves the
 * connectivity report unable to tell one member from the other. If Sysprose
 * moves under any of them, this fails before a paid run finds out.
 */
import { describe, expect, it } from 'vitest';
import { resolve } from 'node:path';
import { InProcessBackend } from '../../src/sysprose/inprocess.ts';

const backend = new InProcessBackend({
  dir: process.env.SYSPROSE_DIR ?? resolve(process.env.HOME ?? '', 'sysprose'),
  expectedCommit: 'any',
});

const model = (la: string): string => `package Probe {
    package Kinds { metadata def Member; }
    package Common {
        item def CoordinationUpdate;
        port def MeshPort { out item update : CoordinationUpdate; }
        interface def MeshLink { end sender : MeshPort; end receiver : ~MeshPort; }
    }
    package LA {
${la}
    }
}`;

const MEMBER = `        #Member part def SwarmMember {
            out port meshOut : Common::MeshPort;
            in port meshIn : ~Common::MeshPort;
            state def Modes {
                initial start;
                transition start -> idle;
                state idle;
                state busy;
                transition idle -> busy;
                transition busy -> idle;
            }
        }
        part fleet : SwarmMember [12];
        part memberA : SwarmMember;
        part memberB : SwarmMember;
        interface peerLink : Common::MeshLink connect memberA.meshOut to memberB.meshIn;`;

describe('dialect facts behind CV-16', () => {
  it('a directed peer link between two representatives checks clean, and the fleet carries its multiplicity', async () => {
    await backend.withModel(model(MEMBER), 'probe.sysml', (m) => {
      const diagnostics = m.report.diagnostics;
      expect(diagnostics.filter((d) => d.severity === 'error'), 'errors').toEqual([]);
      expect(diagnostics.map((d) => d.code)).not.toContain('validation/connection-compatibility');
      expect(diagnostics.map((d) => d.code)).not.toContain('validation/port-direction');
      const fleet = backend.elements(m).find((e) => e.qualifiedName === 'Probe::LA::fleet');
      expect(fleet?.multiplicity).toBe('12');
    });
  });

  it('the layer view reads the peer link as usage-to-usage, which the connectivity payload cannot', async () => {
    await backend.withModel(model(MEMBER), 'probe.sysml', (m) => {
      const [link] = backend.layerView(m, 'LA').connections;
      expect(link).toMatchObject({ name: 'peerLink', type: 'MeshLink', from: 'memberA::meshOut', to: 'memberB::meshIn', metaclass: 'InterfaceUsage' });
    });
  });

  it('at PA, a connection typed by a connection def reads as a typed usage-to-usage link', async () => {
    const pa = MEMBER.replace(
      'interface peerLink : Common::MeshLink connect memberA.meshOut to memberB.meshIn;',
      'connection def RadioLink { end a : Common::MeshPort; end b : ~Common::MeshPort; }\n        connection peerLink : RadioLink connect memberA.meshOut to memberB.meshIn;',
    );
    await backend.withModel(model(pa), 'probe.sysml', (m) => {
      expect(m.report.diagnostics.filter((d) => d.severity === 'error'), 'errors').toEqual([]);
      const [link] = backend.layerView(m, 'LA').connections;
      expect(link).toMatchObject({ name: 'peerLink', type: 'RadioLink', from: 'memberA::meshOut', to: 'memberB::meshIn' });
    });
  });

  it('initial start opens a machine: every state reachable', async () => {
    await backend.withModel(model(MEMBER), 'probe.sysml', (m) => {
      const reach = backend.reach(m);
      const codes = (reach.diagnostics ?? []).map((d) => d.code);
      expect(codes).not.toContain('verification/unreachable-state');
    });
  });

  it('an indexed end does not parse', async () => {
    const indexed = MEMBER.replace('connect memberA.meshOut to memberB.meshIn', 'connect fleet[1].meshOut to fleet[2].meshIn');
    await backend.withModel(model(indexed), 'probe.sysml', (m) => {
      expect(m.report.summary.errors).toBeGreaterThan(0);
    });
  });
});

describe('dialect facts behind CV-17', () => {
  const measures = (la: string, pa = ''): string => `package Probe {
    package Kinds { metadata def MoE; metadata def Estimate; }
    package Common {
        attribute def Ratio { doc /* a fraction */ }
        #MoE attribute sectorCoverageRatio : Ratio { require constraint { sectorCoverageRatio >= 0.95 } }
    }
    package LA {
${la}
    }
    package PA {
${pa}
    }
}`;
  const LA_ESTIMATE = '        #Estimate attribute sectorCoverageRatio :> Common::sectorCoverageRatio = 0.97 { doc /* twelve drones at a 40/60 duty */ }';
  const PA_ESTIMATE = '        #Estimate attribute sectorCoverageRatio :> Common::sectorCoverageRatio = 0.96 { doc /* two in maintenance */ }';

  it('an estimate loads clean, carries its value in the elements payload, and bounds to itself', async () => {
    await backend.withModel(measures(LA_ESTIMATE, PA_ESTIMATE), 'probe.sysml', async (m) => {
      expect(m.report.diagnostics.filter((d) => d.severity === 'error')).toEqual([]);
      const row = backend.elements(m).find((e) => e.qualifiedName === 'Probe::LA::sectorCoverageRatio');
      expect(row?.value).toBe('0.97');
      expect(backend.tags(m).has('Probe::LA::sectorCoverageRatio', 'Estimate')).toBe(true);
      const la = (await backend.bounds(m, 'Probe::LA::sectorCoverageRatio', 'min')).bounds[0];
      expect(la).toMatchObject({ outcome: 'optimum', value: 0.97 });
      // Two layers' estimates of one measure coexist: subsetting is no axiom on Common.
      const pa = (await backend.bounds(m, 'Probe::PA::sectorCoverageRatio', 'min')).bounds[0];
      expect(pa).toMatchObject({ outcome: 'optimum', value: 0.96 });
    });
  });

  it('a derived estimate bounds to one value both ways, though z3 cannot prove it optimal', async () => {
    const derived = [
      '        attribute fleetSize : ScalarValues::Real = 12.0;',
      '        attribute flightMinutes : ScalarValues::Real = 40.0;',
      '        attribute rechargeMinutes : ScalarValues::Real = 60.0;',
      '        attribute sectors : ScalarValues::Real = 5.0;',
      '        attribute airborne : ScalarValues::Real;',
      '        assert constraint duty { airborne == fleetSize * flightMinutes / (flightMinutes + rechargeMinutes) }',
      '        #Estimate attribute sectorCoverageRatio :> Common::sectorCoverageRatio { doc /* airborne over sectors */ }',
      // A doc inside the body, as the estimate guidance asks: the value must still bound.
      '        assert constraint coverage { doc /* airborne drones spread over the sectors */ sectorCoverageRatio == airborne / sectors }',
    ].join('\n');
    const { worstCase } = await import('../../src/spec/measures.ts');
    await backend.withModel(measures(derived), 'probe.sysml', async (m) => {
      expect(m.report.diagnostics.filter((d) => d.severity === 'error')).toEqual([]);
      const qn = 'Probe::LA::sectorCoverageRatio';
      const lo = (await backend.bounds(m, qn, 'min')).bounds[0];
      expect(lo?.outcome).toBe('bound-without-optimality');
      expect(lo?.value).toBeCloseTo(0.96);
      const result = await worstCase(async (sense) => (await backend.bounds(m, qn, sense)).bounds[0], 'max');
      expect(result.outcome).toBe('derived');
      expect(result.value).toBeCloseTo(0.96);
    });
  });

  it('bounding the Common name decides nothing, which is why the estimate is what is read', async () => {
    await backend.withModel(measures(LA_ESTIMATE), 'probe.sysml', async (m) => {
      const common = (await backend.bounds(m, 'Probe::Common::sectorCoverageRatio', 'min')).bounds[0];
      expect(['optimum', 'supremum', 'infimum']).not.toContain(common?.outcome);
    });
  });
});

describe('a population through the transitions', () => {
  // A two-drone OA with a peer flow, an actor, and a tagged coordination activity.
  const kinds = 'package Kinds { metadata def Actor; metadata def Member; metadata def Coordination; metadata def C2; metadata def prose; metadata def prompt; }';
  const common = `package Common {
        item def SectorHandover;
        item def CoordinationUpdate;
        port def MeshPort { out item update : CoordinationUpdate; }
        interface def MeshLink { end sender : MeshPort; end receiver : ~MeshPort; }
    }`;
  const oa = `package OA {
        part def Drone { doc /* a watch asset */ }
        #Actor part def OperationsCentre { doc /* tasks the watch */ }
        part droneA : Drone;
        part droneB : Drone;
        part opsCentre : OperationsCentre;
        action def HandOverSector; action def TakeOverSector; action def IssueTasking;
        #Coordination action handOverSector : HandOverSector { out sector : Common::SectorHandover; }
        action takeOverSector : TakeOverSector { in sector : Common::SectorHandover; }
        action issueTasking : IssueTasking;
        allocate handOverSector to droneA;
        allocate takeOverSector to droneB;
        allocate issueTasking to opsCentre;
        flow handover of Common::SectorHandover from handOverSector.sector to takeOverSector.sector;
    }`;
  const wrap = (...layers: string[]): string => `package Probe {\n    ${[kinds, common, ...layers].join('\n    ')}\n}`;
  const population = { memberDef: 'SwarmMember', fleetPart: 'fleet', size: 12, meshPort: 'MeshPort', meshInterface: 'MeshLink' };

  it('T-01 merges what both members perform into one function, tagged from its definition, and loads clean', async () => {
    const { generateSkeleton } = await import('../../src/transition/skeleton.ts');
    const halves = oa
      .replace('action def IssueTasking;', 'action def IssueTasking; action def WatchSector; #Coordination action def RelayReport;')
      .replace(
        'allocate issueTasking to opsCentre;',
        [
          'allocate issueTasking to opsCentre;',
          '        action watchA : WatchSector; action watchB : WatchSector;',
          '        allocate watchA to droneA; allocate watchB to droneB;',
          '        action alphaRelayReport : RelayReport { out meshOut : Common::CoordinationUpdate; in meshIn : Common::CoordinationUpdate; }',
          '        action bravoRelayReport : RelayReport { out meshOut : Common::CoordinationUpdate; in meshIn : Common::CoordinationUpdate; }',
          '        allocate alphaRelayReport to droneA; allocate bravoRelayReport to droneB;',
          '        flow relayAlphaToBravo of Common::CoordinationUpdate from alphaRelayReport.meshOut to bravoRelayReport.meshIn;',
        ].join('\n'),
      );
    const sa = await backend.withModel(wrap(halves), 'oa.sysml', (m) =>
      generateSkeleton({ rule: 'T01', from: backend.layerView(m, 'OA'), root: 'Probe', systemName: 'Probe', systemEntity: 'droneA', memberDef: 'SwarmMember', population, namedFunctions: ['relayReport'] }),
    );
    expect(sa.text.match(/action def WatchSector\b/g)).toHaveLength(1);
    expect(sa.text).toContain('action watchSector : WatchSector;');
    expect(sa.text).not.toMatch(/action watch[AB]\b/);
    expect(sa.text).toContain('trace watchSector to Probe::OA::watchA;');
    expect(sa.text).toContain('trace watchSector to Probe::OA::watchB;');
    // The tag sits on the OA definition only; the merged usage carries it, under the brief's name.
    expect(sa.text).toContain('#Coordination action relayReport : RelayReport {');
    expect(sa.text).toContain('allocate relayReport to system;');
    expect(sa.text).toMatch(/flow relayAlphaToBravo of \S+ from relayReport(::|\.)meshOut to relayReport(::|\.)meshIn;/);
    expect(sa.carried.peerFlows).toBe(1);
    // Different definitions performed by different members stay two functions.
    expect(sa.text).toContain('action handOverSector : HandOverSector');
    expect(sa.text).toContain('action takeOverSector : TakeOverSector');
    await backend.withModel(wrap(halves, sa.text), 'sa.sysml', (m) => {
      expect(m.report.diagnostics.filter((d) => d.severity === 'error')).toEqual([]);
      const conn = backend.connectivity(m);
      expect(conn.unconnectedPorts.map((p) => p.qualifiedName).filter((q) => q.includes('::SA::relayReport'))).toEqual([]);
    });
  });

  it('T-01 carries parameters declared on the definition as `in item`, and the flows between them resolve', async () => {
    // v5's OA: parameters on the definitions, written `in item x : T;`, none on the usages.
    const { generateSkeleton } = await import('../../src/transition/skeleton.ts');
    const onDefs = `package OA {
        part def Drone { doc /* a watch asset */ }
        part droneA : Drone;
        part droneB : Drone;
        #Coordination action def HandOverSector {
            in item offerIn : Common::CoordinationUpdate;
            out item offerOut : Common::CoordinationUpdate;
        }
        action handOverA : HandOverSector { doc /* a */ }
        action handOverB : HandOverSector { doc /* b */ }
        allocate handOverA to droneA;
        allocate handOverB to droneB;
        action issue { out item taskingOut : Common::SectorHandover; }
        action take : HandOverSector;
        allocate take to droneA;
        flow handOverFlow of Common::CoordinationUpdate from handOverA.offerOut to handOverB.offerIn;
    }`;
    const sa = await backend.withModel(wrap(onDefs), 'oa.sysml', (m) =>
      generateSkeleton({ rule: 'T01', from: backend.layerView(m, 'OA'), root: 'Probe', systemName: 'Probe', systemEntity: 'droneA', memberDef: 'SwarmMember', population, namedFunctions: ['handOverSector'] }),
    );
    expect(sa.text).toMatch(/action def HandOverSector \{[^}]*in offerIn : Common::CoordinationUpdate;[^}]*out offerOut : Common::CoordinationUpdate;/s);
    expect(sa.text).toContain('#Coordination action handOverSector : HandOverSector;');
    expect(sa.text).toMatch(/action issue : IssueDefinition \{\s*out taskingOut : Common::SectorHandover;/);
    await backend.withModel(wrap(onDefs, sa.text), 'sa.sysml', (m) => {
      expect(m.report.diagnostics.filter((d) => d.severity === 'error')).toEqual([]);
    });
  });

  it('T-01 takes over both representatives, keeps the tag, carries the member definition, and loads clean', async () => {
    const { generateSkeleton } = await import('../../src/transition/skeleton.ts');
    const sa = await backend.withModel(wrap(oa), 'oa.sysml', (m) =>
      generateSkeleton({ rule: 'T01', from: backend.layerView(m, 'OA'), root: 'Probe', systemName: 'Probe', systemEntity: 'droneA', memberDef: 'SwarmMember', population }),
    );
    expect(sa.text).toContain('allocate handOverSector to system;');
    expect(sa.text).toContain('allocate takeOverSector to system;');
    expect(sa.text).toContain('allocate issueTasking to opsCentre;');
    expect(sa.text).toContain('#Coordination action handOverSector');
    expect(sa.text).toContain('#Member part def SwarmMember');
    expect(sa.text).not.toMatch(/part fleet\b/);
    expect(sa.carried.actors).toBe(1);
    await backend.withModel(wrap(oa, sa.text), 'sa.sysml', (m) => {
      expect(m.report.diagnostics.filter((d) => d.severity === 'error')).toEqual([]);
    });

    // T-02 carries the definition and the tag on into LA.
    const la = await backend.withModel(wrap(oa, sa.text), 'sa.sysml', (m) =>
      generateSkeleton({ rule: 'T02', from: backend.layerView(m, 'SA'), root: 'Probe', systemName: 'Probe', population }),
    );
    expect(la.text).toContain('#Member part def SwarmMember');
    expect(la.text).toContain('#Coordination action handOverSector');
    await backend.withModel(wrap(oa, sa.text, la.text), 'la.sysml', (m) => {
      expect(m.report.diagnostics.filter((d) => d.severity === 'error')).toEqual([]);
    });
  });
});

describe('rules a state machine carries (CV-18)', () => {
  // The three kinds, written with the exact text ruleTemplate hands an author,
  // placeholders filled with this machine's states.
  const fill = (text: string, states: Record<string, string>): string => text.replace(/state <([^>]+)>/g, (_, hint: string) => `state ${states[hint]}`);

  it('the templates load clean, decide, and join back to the rule their doc names', async () => {
    const { ruleTemplate, carriersIn, ruleNameOf, sameFields } = await import('../../src/spec/rules.ts');
    const { matchingBrace } = await import('../../src/model/statements.ts');
    const recall = fill(ruleTemplate('RecallWins', 'winsUntil'), { 'the state that starts it': 'Recalled', 'the state that ends it': 'Landed', 'the state that must not hold': 'Surveilling' });
    const clearance = fill(ruleTemplate('WatchAfterClearance', 'precededBy'), { 'the state that must come first': 'Cleared', 'the state that may only follow': 'Surveilling' });
    const home = fill(ruleTemplate('CanGetHome', 'canAlwaysReturn'), { 'the state it can always get back to': 'Landed' });
    // Broken on purpose: Landed does come before Recalled.
    const broken = fill(ruleTemplate('RecalledBeforeLanding', 'precededBy'), { 'the state that must come first': 'Recalled', 'the state that may only follow': 'Landed' });
    const text = `package Probe {
    package SA {
        #Rule requirement RecallWins { doc /* a recall wins until landing */ }
        part def Drone {
            state def DroneMode {
                ${recall}
                ${clearance}
                ${home}
                ${broken}
                initial Start;
                state Landed;
                state Cleared;
                state Surveilling;
                state Recalled;
                transition Start -> Landed;
                transition Landed -> Cleared;
                transition Cleared -> Surveilling;
                transition Surveilling -> Recalled;
                transition Recalled -> Landed;
            }
        }
    }
}`;
    await backend.withModel(text, 'rules.sysml', async (m) => {
      expect(m.report.diagnostics.filter((d) => d.severity === 'error')).toEqual([]);
      const machine = backend.elements(m).find((e) => e.qualifiedName === 'Probe::SA::Drone::DroneMode')!;
      const report = backend.behaviour(m, machine.id);
      const carriers = carriersIn(text, matchingBrace);
      const verdicts = Object.fromEntries(
        report.properties.map((p) => {
          const carrier = carriers.find((c) => sameFields(c.fields, p.property as unknown as Record<string, string>));
          return [carrier ? ruleNameOf(carrier.doc) : '?', p.claim];
        }),
      );
      expect(verdicts).toEqual({ RecallWins: 'pass', WatchAfterClearance: 'pass', CanGetHome: 'pass', RecalledBeforeLanding: 'fail' });
    });
  });

  it('a carrier naming a state the machine lacks is unreadable, not undecided', async () => {
    const { isUnreadable } = await import('../../src/spec/rules.ts');
    const text = `package Probe { package SA { part def D { state def M {
        @SysproseVerification::PropertyPattern { doc /* R: x */ attribute pattern = "recovery"; attribute scope = "globally"; attribute p = "state <the state it can always get back to>"; }
        initial S; state A; state B; transition S -> A; transition A -> B; transition B -> A;
    } } } }`;
    await backend.withModel(text, 'unknown.sysml', async (m) => {
      const machine = backend.elements(m).find((e) => e.qualifiedName === 'Probe::SA::D::M')!;
      const [p] = backend.behaviour(m, machine.id).properties;
      expect(p.claim).toBe('inconclusive');
      expect(isUnreadable({ claim: String(p.claim), code: p.code ?? undefined, detail: p.detail ?? undefined })).toBe(true);
    });
  });

  it('a carrier with any attribute beyond the pattern fields is refused, not read', async () => {
    const text = `package Probe { package SA { part def D { state def M {
        @SysproseVerification::PropertyPattern { attribute pattern = "recovery"; attribute scope = "globally"; attribute p = "state A"; attribute rule = "X"; }
        initial S; state A; state B; transition S -> A; transition A -> B; transition B -> A;
    } } } }`;
    await backend.withModel(text, 'refused.sysml', async (m) => {
      const machine = backend.elements(m).find((e) => e.qualifiedName === 'Probe::SA::D::M')!;
      const [p] = backend.behaviour(m, machine.id).properties;
      expect(p.claim).not.toBe('pass');
      expect(p.code).toBe('verification/malformed-property');
      expect(p.detail).toContain('is not a property field');
    });
  });
});

