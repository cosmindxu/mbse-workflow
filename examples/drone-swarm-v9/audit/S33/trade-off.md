# LA architecture trade-off

**Chosen: alternative 2**

> **10 measure(s) scored every alternative the same and decided nothing here:** `areaUnderWatchFraction`, `reportAgeAtOperationsCentreSeconds`, `positionErrorWithoutSatelliteMetres`, `reportHoldWhileCutOffMinutes`, `missedDetectionFraction`, `falseAlarmsPerHour`, `alertsReachingOperatorPerHour`, `acknowledgedReportsThatMatterFraction`, `onboardClassificationCostUsdPerMember`, `unattendedWatchDurationHours`. A measure with the same estimate on both sides is still scored and still moves no score, and a reader is left believing the alternatives were examined on it. If one of these is the thing the alternatives differ about, the comparison has not been made on the thing that matters. In v7 four of fourteen measures scored both alternatives the same, so a third of that comparison turned on nothing.

## Score

| Alternative | Total | Measures | Review | Structure | Resilience |
|---|---|---|---|---|---|
| 1 | 0.517 | 0.29 | 0.44 | 0.84 | 0.25 |
| 2 | 0.650 | 0.29 | 0.56 | 0.86 | 0.81 |

## Command and control

| Alternative | Coordination and C2 on board | Links between members | Fleet | Hazards accepted |
|---|---|---|---|---|
| 1 | 2/13 | 2 | [12] | 0 |
| 2 | 8/13 | 1 | [12] | 0 |

## Measured

| Alternative | Elements | Connections | Unconnected ports | Unused defs | Functions realised | Repairs | Hazards accepted |
|---|---|---|---|---|---|---|---|
| 1 | 1730 | 180 | 0 | 5 | 21/21 | 1 | 0 |
| 2 | 1629 | 169 | 0 | 5 | 21/21 | 1 | 0 |

## Measures of effectiveness

Each value is the worst case the solver finds over the alternative's own `#Estimate` — a claim the architecture makes, not a measurement.

| Alternative | Measure | Worst case | Target | Met |
|---|---|---|---|---|
| 1 | `areaUnderWatchFraction` | vacuous | ≥ 0.9 | undecided |
| 1 | `coverageLossAfterMemberLossFraction` | vacuous | ≤ 0.25 | undecided |
| 1 | `coverageUnderMeshJammingFraction` | vacuous | ≥ 0.75 | undecided |
| 1 | `reportAgeAtOperationsCentreSeconds` | 40 s | ≤ 60 s | yes |
| 1 | `positionErrorWithoutSatelliteMetres` | 80 m | ≤ 50 m | no |
| 1 | `reportHoldWhileCutOffMinutes` | 40 min | ≥ 30 min | yes |
| 1 | `missedDetectionFraction` | 0.12 | ≤ 0.1 | no |
| 1 | `falseAlarmsPerHour` | 3 1/h | ≤ 2 1/h | no |
| 1 | `alertsReachingOperatorPerHour` | 24 1/h | ≤ 20 1/h | no |
| 1 | `acknowledgedReportsThatMatterFraction` | 0.7 | ≥ 0.8 | no |
| 1 | `onboardClassificationCostUsdPerMember` | 350 USD | ≤ 300 USD | no |
| 1 | `unattendedWatchDurationHours` | 0.7 h | ≥ 12 h | no |
| 2 | `areaUnderWatchFraction` | vacuous | ≥ 0.9 | undecided |
| 2 | `coverageLossAfterMemberLossFraction` | 0.16 | ≤ 0.25 | yes |
| 2 | `coverageUnderMeshJammingFraction` | 0.58 | ≥ 0.75 | no |
| 2 | `reportAgeAtOperationsCentreSeconds` | 40 s | ≤ 60 s | yes |
| 2 | `positionErrorWithoutSatelliteMetres` | 80 m | ≤ 50 m | no |
| 2 | `reportHoldWhileCutOffMinutes` | 40 min | ≥ 30 min | yes |
| 2 | `missedDetectionFraction` | 0.12 | ≤ 0.1 | no |
| 2 | `falseAlarmsPerHour` | 3 1/h | ≤ 2 1/h | no |
| 2 | `alertsReachingOperatorPerHour` | 24 1/h | ≤ 20 1/h | no |
| 2 | `acknowledgedReportsThatMatterFraction` | 0.7 | ≥ 0.8 | no |
| 2 | `onboardClassificationCostUsdPerMember` | 350 USD | ≤ 300 USD | no |
| 2 | `unattendedWatchDurationHours` | 0.7 h | ≥ 12 h | no |

## Review

This comparison exists to place command and control, and the two alternatives differ exactly there: Alternative 1 puts sector handover, rotation, redistribution, deconfliction, track correlation and admission inside one GroundSwarmCoordinator; Alternative 2 puts all eight on SwarmMember and leaves a thin GroundStation holding only tasking, priorities, recall, acknowledgement and the status picture. I would take Alternative 2. The deciding evidence is the two components' own state machines. SwarmCoordinatorModes.FleetUnreachable says each drone 'acts on its last assignment' — coverage then decays as endurance runs out, and Alternative 1 discharges its own GroundCoordinatorSinglePointHazard and CoordinationConcentrationHazard onto fleet while allocating no coordination function to fleet, so that mitigation is unbacked. GroundStationModes.LinkDown says the members coordinate and hold reports on their own, and the allocations back it. Alternative 1 is also the weaker model on its own arithmetic: watchingMembers evaluates to 6.8, contradicting the stated 0.78 and 0.16, so three measures score vacuous against Alternative 2's one, and its coverageUnderMeshJammingFraction basis literally blames 'the member-centred allocation' for a worst case that belongs to a ground-centred decision path. Alternative 1 is not without merit and two of its choices should be carried across: recallToFleet, which keeps recall alive when the coordinator dies — Alternative 2 has no equivalent and its operator cannot stop the swarm with the station gone; and the split of GroundDecisionRecordStore from GroundAlertTriage, which Alternative 2 collapses into one AlertTriageUnit so that losing the ranker loses the provenance record. Alternative 1's triggered transitions are also the better basis for checking RecallWins and QuarantinedStaysOut than Alternative 2's untriggered ones. Before PA, Alternative 2 needs four fixes: a direct recall path to fleet, records split out of AlertTriageUnit, triggers and a return direction on the peer link (one unidirectional MeshPort cannot be the whole evidence for eight coordination functions, least of all distributed admitMember), and a rule monitor separate from the component that detects and classifies — neither alternative has one today.

### Alternative 1

- **cohesion** 3/5 — The ground side is properly divided: GroundAlertTriage ranks and merges, GroundDecisionRecordStore keeps provenance, GroundOperatorConsole carries tasking/priorities/recall/status/acknowledgement. Splitting triage from the record store is the better of the two splits — losing the ranker does not lose the record of why a report was raised. Against that, GroundSwarmCoordinator is a bucket: sector handover, recharge rotation, coverage redistribution, airspace deconfliction, track correlation AND member admission. Identity-and-classifier-version gatekeeping has nothing to do with sector planning or with multi-sensor fusion; three unrelated jobs sit behind one port set. The four never-broken rules are carried by SwarmMemberStates/SwarmMemberModes, the same component that detects and classifies, with no separate monitor — the rules share faults with the sensing chain.
- **coupling** 2/5 — Every coordination decision crosses the air-ground boundary twice. fleet.statusOut, fleet.trackOut, fleet.admissionOut and fleet.directiveAckOut all run to groundCoordinator, and groundCoordinator.directiveOut runs back, so a sector handover between two adjacent drones is a round trip through the ground. SwarmMember carries twelve ports, most of them existing only to serve the coordinator. The one good decision is recallToFleet, which deliberately bypasses groundCoordinator so recall survives its loss — that is the right kind of boundary, and it is the exception.
- **realisability** 3/5 — Procurement is clean: four separately specifiable ground items plus one drone type, and the drones are simpler because the smarts are on the ground. The state machines are the better-built of the two — transitions are named and triggered (accept Common::RecallDirective, Common::AirspaceClearance), so RecallWins and GeofenceBreachEndsWatch are actually checkable. But the arithmetic does not hold: watchingMembers evaluates to 6.8, which gives 0.816 for areaUnderWatchFraction and 0.147 for coverageLossAfterMemberLossFraction against stated values of 0.78 and 0.16, so three asserted constraints are unsatisfiable and three measures score vacuous. Worse, the coverageUnderMeshJammingFraction basis says in so many words that 'the member-centred allocation is the worse case' — an estimate inherited from the layer above and never re-derived for an architecture whose decision path is the one being jammed. A ground-centred coordinator under half-jammed links is the worse case, not the better one, so 0.58 is a number this architecture cannot deliver.
- **evolvability** 3/5 — Policy change is cheap in the right direction: a new sector algorithm, a different rotation rule or a fleet of 24 is a change to GroundSwarmCoordinator alone, with no airframe re-qualification, and the richly typed member ports (directiveIn, directiveAckOut, admissionOut) give a stable interface to evolve against. The expensive direction is the one this programme is most likely to take. If the customer firms up the link-outage or jamming requirement into 'keep the watch when the ground path drops', six functions have to move from GroundSwarmCoordinator onto SwarmMember — that is a re-architecture and a new drone, not a change.
- **groundLinkLossResilience** 2/5 — SwarmCoordinatorModes states the outcome plainly: in FleetUnreachable 'each drone acts on its last assignment and its stand-alone rules'. Handover, rotation, redistribution, deconfliction and correlation all stop, because redistributeCoverage and its siblings are allocated only to groundCoordinator. The model then discharges Hazards::GroundCoordinatorSinglePointHazard and CoordinationConcentrationHazard onto fleet — but no coordination function is allocated to fleet, so the mitigation has nothing behind it. Members do hold reports on board (reportHoldWhileCutOffMinutes 40 min, past the 30 min target) and recallToFleet keeps the recall path alive, which is what lifts this off the floor.
- **groundNodeLossResilience** 2/5 — Lose groundCoordinator and coverage is not restored at all: redistribution after a member loss lives only there, so coverageLossAfterMemberLossFraction — already vacuous because the constraint contradicts the stated 0.16 — cannot be recovered from. Track correlation also stops, which starves groundTriage of the input it merges duplicates with, pushing alertsReachingOperatorPerHour further past its already-failed 24/h. What does survive is real and worth crediting: operatorConsole is a separate part wired straight to fleet, so recall and the status picture outlive the coordinator, and SwarmMemberStates gives Recovering → Landed and ReturnsWhenIsolated, so a controlled landing is assured. Controlled landing yes; coverage kept no.

### Alternative 2

- **cohesion** 2.5/5 — GroundStation is genuinely thin and single-purpose — tasking, priorities, recall, acknowledgement and the status picture, and its doc says it does not coordinate. That is the cleanest component in either alternative. The cost is SwarmMember, which now carries sensing, classification, reporting, recovery AND all eight coordination functions including member admission and track correlation; its own doc lists them. Admission distributed across the population is the worst of it — the deciding party and the party being judged are the same component type. AlertTriageUnit also doubles up: ranking/merging and keepDecisionRecords in one item, so losing the ranker loses the provenance record too, which Alternative 1 avoids. As in Alternative 1, the four rules are enforced by SwarmMemberStates alongside detection, with no independent monitor.
- **coupling** 4/5 — The boundary that actually breaks — air to ground — carries ten connections and nothing that the watch depends on: reports and tracks and status up, tasking, priorities, recall and receipts down. Coordination never crosses it. The deduction is that the peer boundary is under-modelled: eight coordination functions, including consensus-flavoured ones like redistributeCoverage, deconflictFlight and admitMember, are allocated to fleet but represented by a single unidirectional peerLink from memberA.meshOut to memberB.meshIn, with no return link (Alternative 1 models both directions) and no directive/acknowledgement pair. The coupling is not absent, it is hidden inside one opaque MeshPort.
- **realisability** 3/5 — Fewer items to procure — one drone type, GroundStation, AlertTriageUnit — but the drone is the hard one: a consensus stack for eight coordination functions on every one of twelve airframes, with onboardClassificationCostUsdPerMember already failing at 350 USD against 300, and that 350 is the figure whose own basis names 'the case in which the whole classification runs on the drone'. Coordination compute on top of that makes 350 look understated for this alternative specifically. Its single constraint is also unsatisfiable: 12 × (33.4/60) × 0.12 = 0.80 against the stated 0.78, so areaUnderWatchFraction scores vacuous — one bad constraint against Alternative 1's three. The state machines are weaker evidence: every transition in SwarmMemberModes and SwarmMemberStates is untriggered (Nominal -> Quarantined, Watching -> Recalled), so RecallWins and QuarantinedStaysOut are asserted over machines that do not say what causes the transition they depend on.
- **evolvability** 3.5/5 — The thin GroundStation can be replaced, re-hosted or duplicated without touching the watch, and adding operator-side capability (feedback into triage to lift acknowledgedReportsThatMatterFraction off 0.7, for instance) touches only AlertTriageUnit. The likely next requirement — hold the watch through a link outage — is already satisfied rather than being a re-architecture. The drag is that changing any coordination policy means new firmware on twelve airframes plus re-verification of distributed behaviour, and because all eight protocols run inside one untyped MeshPort, none of those changes are visible at this layer; there is no typed peer interface to evolve against.
- **groundLinkLossResilience** 4.5/5 — GroundStationModes states it: in LinkDown 'the station holds what it has and the swarm coordinates and holds reports on its own'. Handover, rotation, redistribution, deconfliction, correlation and admission all sit on fleet and keep running, so the watch is unaffected by the outage; reportHoldWhileCutOffMinutes of 40 min against the 30 min target covers the report backlog for a full sortie. What is genuinely lost is C2 — no tasking, no priority change, no recall, no status picture — and the model names that as GroundStationSinglePointHazard rather than hiding it. The half point off is for the recall gap: the operator cannot stop the swarm during the outage, and there is no direct recall path of the sort Alternative 1's recallToFleet provides.
- **groundNodeLossResilience** 4/5 — With GroundStation gone, coverage is kept and restored: redistributeCoverage, rotateRecharge and handOverSector are on fleet, so the 0.16 coverage loss after a member loss is recoverable by the members themselves, which is exactly what the coverage-restoration measure is asking about. Discharging GroundStationSinglePointHazard onto fleet is defensible here, unlike the same move in Alternative 1, because the functions really are allocated there, and SwarmMemberStates gives Recovering → Landed and OutsideClearance → Landed for the controlled-landing case. Two accepted costs: losing AlertTriageUnit takes triage and the decision record with it in one stroke, and with the station gone no one can recall.
