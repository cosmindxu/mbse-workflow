# PA architecture trade-off

**Chosen: alternative 2**

## Score

| Alternative | Total | Measures | Review | Structure | Resilience |
|---|---|---|---|---|---|
| 1 | 0.747 | 0.93 | 0.50 | 0.80 | 0.00 |
| 2 | 0.877 | 1.00 | 0.50 | 0.83 | 0.63 |

## Command and control

| Alternative | Coordination and C2 on board | Links between members | Fleet | Hazards accepted |
|---|---|---|---|---|
| 1 | 1/13 | 1 | [12] | 1 |
| 2 | 7/13 | 2 | [12] | 0 |

## Measured

| Alternative | Elements | Connections | Unconnected ports | Unused defs | Functions realised | Repairs | Hazards accepted |
|---|---|---|---|---|---|---|---|
| 1 | 1939 | 271 | 9 | 1 | 28/28 | 1 | 1 (structure −0.05) |
| 2 | 1898 | 273 | 9 | 1 | 28/28 | 2 | 0 |

## Measures of effectiveness

Each value is the worst case the solver finds over the alternative's own `#Estimate` — a claim the architecture makes, not a measurement.

| Alternative | Measure | Worst case | Target | Met |
|---|---|---|---|---|
| 1 | `areaUnderWatchShare` | 0.9 | ≥ 0.9 | yes |
| 1 | `coverageLossOnMemberLoss` | 0.25 (derived) | ≤ 0.25 | yes |
| 1 | `jammedMeshAreaUnderWatchShare` | 0.8 | ≥ 0.75 | yes |
| 1 | `groundLinkLossAreaUnderWatchShare` | 0.55 | ≥ 0.9 | no |
| 1 | `watchEnduranceHours` | 26 h | ≥ 24 h | yes |
| 1 | `reportLatencySeconds` | 45 s | ≤ 60 s | yes |
| 1 | `positionErrorWithoutGnssMeters` | 40 m | ≤ 50 m | yes |
| 1 | `reportHoldMinutes` | 35 min | ≥ 30 min | yes |
| 1 | `reportsLostInLinkGap` | 0 | ≤ 0 | yes |
| 1 | `missedDetectionShare` | 0.08 | ≤ 0.1 | yes |
| 1 | `falseAlarmsPerHour` | 1.5 1/h | ≤ 2 1/h | yes |
| 1 | `operatorAlertsPerHour` | 18 1/h | ≤ 20 1/h | yes |
| 1 | `acknowledgedReportsThatMatterShare` | 0.82 | ≥ 0.8 | yes |
| 1 | `onboardClassificationCostUsd` | 280 USD | ≤ 300 USD | yes |
| 2 | `areaUnderWatchShare` | 0.92 | ≥ 0.9 | yes |
| 2 | `coverageLossOnMemberLoss` | 0.08333333333333333 (derived) | ≤ 0.25 | yes |
| 2 | `jammedMeshAreaUnderWatchShare` | 0.78 | ≥ 0.75 | yes |
| 2 | `groundLinkLossAreaUnderWatchShare` | 0.91 | ≥ 0.9 | yes |
| 2 | `watchEnduranceHours` | 48 h | ≥ 24 h | yes |
| 2 | `reportLatencySeconds` | 45 s | ≤ 60 s | yes |
| 2 | `positionErrorWithoutGnssMeters` | 35 m | ≤ 50 m | yes |
| 2 | `reportHoldMinutes` | 45 min | ≥ 30 min | yes |
| 2 | `reportsLostInLinkGap` | 0 | ≤ 0 | yes |
| 2 | `missedDetectionShare` | 0.08 | ≤ 0.1 | yes |
| 2 | `falseAlarmsPerHour` | 1.5 1/h | ≤ 2 1/h | yes |
| 2 | `operatorAlertsPerHour` | 16 1/h | ≤ 20 1/h | yes |
| 2 | `acknowledgedReportsThatMatterShare` | 0.83 | ≥ 0.8 | yes |
| 2 | `onboardClassificationCostUsd` | 275 USD | ≤ 300 USD | yes |

## Review

I would take alternative 2, on condition that its physical breakdown is filled in. The whole decision is where coordination lives. Alternative 1 puts all seven deciding coordination calls in groundStation.swarmCoordinator and formally accepts the consequence (GroundCoordinatorLossHazard): when the link or ground node is lost, drones fly their last assignment, rotation stops, and nothing plans a landing. Its own estimate of 0.55 coverage misses the 0.9 target, and it is optimistic, because with 40-minute flights and no recharge rotation coverage falls toward zero after one sortie. Alternative 2 moves those decisions onto the drones and gives each drone a real SafetyMonitor, separate from detection and classification. That keeps coverage and recall working through a ground outage. What still stops is admission, classifier-version control and any defined limit on flying unsupervised. Alternative 1 is the better model of hardware: missionComputer, reportStore, flightController and a ground ReportTriage can be bought and hosted, and its coverage-loss-per-drone figure (0.25) is honestly derived. Alternative 2 overclaims. Its 'on-board triage' behind the operator-workload estimates has no function or component, it has no compute or report store, and 1/12 coverage loss ignores that only about 4–5 drones are airborne at once. That is why alternative 2 scores low on realisability. Those gaps can be fixed by adding parts in the next layer. Alternative 1's weakness would mean re-architecting.

### Alternative 1

- **cohesion** 4/5 — The drone is split into parts you could buy: missionComputer (with a classifierModule choice), sensorPod, mapMatchNavigator, flightController, reportStore, meshRadio and groundLinkRadio. On the ground, SwarmCoordinator, SupervisionConsole and ReportTriage each have one clear job. Two slips. manageClassifierVersion is put on SupervisionConsole, which is the operator's seat, not a place for configuration management. And there is no separate monitor for the safety rules: the rule-carrying machines sit directly on SurveillanceDrone, and FlightController 'carries the airborne side of RecallWins' while also flying the aircraft. At least the rules are not tied to the parts that detect or classify.
- **coupling** 2/5 — groundStation.swarmCoordinator makes all seven deciding coordination calls: handovers, rotation, redistribution, deconfliction, track correlation, track handover and admission. So every one of those calls has to go up the uplink and back down the downlink, over the one link the brief says is not always there. The mesh (a single one-way peerLink) only relays. The most time-critical traffic crosses the least reliable boundary.
- **realisability** 4/5 — It can be procured and hosted as drawn, and the estimates are mostly honest. coverageLossOnMemberLoss = 1/airborneMembersPA (0.25) is correctly derived from the 40-minute flight and 60-minute recharge. But areaUnderWatchShare = 0.9 is a nominal link-up figure sitting exactly on the target, not a worst case. The 26 h endurance only holds 'while the ground link holds'. And groundLinkLossAreaUnderWatchShare = 0.55 is optimistic: rotateRecharge stops during an outage, so with 40-minute flights coverage falls toward zero after one sortie, not to a steady 55%.
- **evolvability** 2/5 — The central SwarmCoordinator is the structural core. If the brief firms up the link-outage target, it cannot be patched: the seven allocations, both ground-link connections, GroundCoordinatorLossHazard and the drone BOM (no on-board coordination compute) all have to be redone. Swapping the classifier tier is easy thanks to the classifierModule variation, but that is not the change that is likely.
- **groundLinkLossResilience** 1/5 — When the link drops, only relayLink and each drone's own sensing and reportStore (35 min) keep running. Nothing new is decided on handover, rotation, redistribution, deconfliction or track handover. Quarantined drones cannot be readmitted (CentralAdmissionGapHazard, whose 'mitigation' is just staying quarantined), and tracks go stale because correlateTracks is on the ground. The model's own estimate, 0.55, misses the 0.9 target by a wide margin, and physically it is worse for any outage longer than one 40-minute sortie.
- **groundNodeLossResilience** 1/5 — GroundCoordinatorLossHazard is accepted rather than mitigated: members 'hold their last assignment and keep watching'. That is exactly 'members flying their last assignment'. The drone has no state for losing the ground (Isolated is about the mesh), so nothing defines a controlled landing, and nothing restores coverage because there is no rotation. Coverage decays until batteries force members down in an unplanned way.

### Alternative 2

- **cohesion** 3/5 — Good: SafetyMonitor is its own part in every SurveillanceDrone, and its doc says what it overrides (recall, geofence breach, quarantine), apart from detect/classify/decide. Weak: the drone has no mission computer, sensor, flight controller or report store, so classification, reporting, report buffering and all seven on-board coordination decisions are allocated to the bare 'fleet' usage with no component doing that job. GroundStation is a flat node with no console or triage part. The rule machines are still declared on SurveillanceDrone, not on SafetyMonitor.
- **coupling** 4/5 — Coordination runs peer-to-peer over two-way MeshRadioLinks: peerLink plus peerLinkReturn. Only C2, admitMember and manageClassifierVersion cross the ground link. The ground link is relayed through whichever member currently holds it. Mesh chatter per exchange rises under jamming (0.78 against 0.75, a thin margin), but a ground dropout no longer stalls the swarm.
- **realisability** 2/5 — Several claims lack a component to back them. falseAlarmsPerHour, operatorAlertsPerHour and acknowledgedReportsThatMatterShare all credit 'on-board triage', but no triage function or part exists anywhere, so the operator's filtering has no home. reportHoldMinutes = 45 has no store. The 275 USD classification cost has no compute part to price. coverageLossOnMemberLoss = 1/12 ignores that only about 4–5 of 12 drones are airborne given 40-minute flights and 60-minute recharges; the true figure is nearer 0.2–0.25. The 'lowest reachable id' tie-break creates forks in a partitioned mesh, yet CoordinationForkHazard is simply marked satisfied by fleet. QuarantinedStaysOut is checked against 'state Nominal' rather than coordination, and Recalled/OutsideClearance can only be entered from Watching (not from Launching).
- **evolvability** 3/5 — The hard, expensive choice (coordination on board) is already made, so a firmer link-outage target costs nothing structurally. But the missing on-board compute, report store and triage will have to be added in the next layer. That changes the drone BOM, the cost estimate and where the operator-workload functions are hosted, and the representative-A/B ground ports will need reworking for relay handoff.
- **groundLinkLossResilience** 4/5 — Handover, rotation, redistribution, deconfliction, relay, correlateTracks and handOverTrack all stay on board. recallAndLand is also allocated to fleet, so recall can be executed without the ground. Reports are held for 45 minutes. The 0.91 estimate is plausible for coordination. What stops: admitMember, so there is no readmission or spoofing gate; classifier-version control; and report buffering after 45 minutes, for which no hosting store is modelled.
- **groundNodeLossResilience** 3/5 — Coverage is kept, and rotation through rechargePoint carries on without the ground, which is the strongest showing against the coverage-restoration measure. But nothing on the drone detects that the ground is gone (GroundLinkMode exists only on GroundStation), and there is no limit on how long drones fly unsupervised and no controlled-landing policy. GroundLinkRadioFailureHazard is 'satisfied by fleet', which cannot cover failure of the ground station's own radio. Admission and classifier management stay frozen until the ground returns.
