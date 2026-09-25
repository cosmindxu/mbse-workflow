# LA architecture trade-off

**Chosen: alternative 2**

## Score

| Alternative | Total | Measures | Review | Structure | Resilience |
|---|---|---|---|---|---|
| 1 | 0.665 | 0.86 | 0.28 | 0.78 | 0.19 |
| 2 | 0.901 | 1.00 | 0.56 | 0.84 | 0.63 |

## Command and control

| Alternative | Coordination and C2 on board | Links between members | Fleet | Hazards accepted |
|---|---|---|---|---|
| 1 | 0/13 | 1 | [12] | 1 |
| 2 | 8/13 | 2 | [12] | 0 |

## Measured

| Alternative | Elements | Connections | Unconnected ports | Unused defs | Functions realised | Repairs | Hazards accepted |
|---|---|---|---|---|---|---|---|
| 1 | 1463 | 198 | 16 | 3 | 28/28 | 2 | 1 (structure −0.05) |
| 2 | 1519 | 215 | 16 | 3 | 28/28 | 1 | 0 |

## Measures of effectiveness

Each value is the worst case the solver finds over the alternative's own `#Estimate` — a claim the architecture makes, not a measurement.

| Alternative | Measure | Worst case | Target | Met |
|---|---|---|---|---|
| 1 | `areaUnderWatchShare` | 0.9 | ≥ 0.9 | yes |
| 1 | `coverageLossOnMemberLoss` | 0.20833333333333334 (derived) | ≤ 0.25 | yes |
| 1 | `jammedMeshAreaUnderWatchShare` | 0.8 | ≥ 0.75 | yes |
| 1 | `groundLinkLossAreaUnderWatchShare` | 0.55 | ≥ 0.9 | no |
| 1 | `watchEnduranceHours` | 20 h | ≥ 24 h | no |
| 1 | `reportLatencySeconds` | 45 s | ≤ 60 s | yes |
| 1 | `positionErrorWithoutGnssMeters` | 40 m | ≤ 50 m | yes |
| 1 | `reportHoldMinutes` | 45 min | ≥ 30 min | yes |
| 1 | `reportsLostInLinkGap` | 0 | ≤ 0 | yes |
| 1 | `missedDetectionShare` | 0.08 | ≤ 0.1 | yes |
| 1 | `falseAlarmsPerHour` | 1.8 1/h | ≤ 2 1/h | yes |
| 1 | `operatorAlertsPerHour` | 15 1/h | ≤ 20 1/h | yes |
| 1 | `acknowledgedReportsThatMatterShare` | 0.82 | ≥ 0.8 | yes |
| 1 | `onboardClassificationCostUsd` | 280 USD | ≤ 300 USD | yes |
| 2 | `areaUnderWatchShare` | 0.92 | ≥ 0.9 | yes |
| 2 | `coverageLossOnMemberLoss` | 0.18 | ≤ 0.25 | yes |
| 2 | `jammedMeshAreaUnderWatchShare` | 0.78 | ≥ 0.75 | yes |
| 2 | `groundLinkLossAreaUnderWatchShare` | 0.92 | ≥ 0.9 | yes |
| 2 | `watchEnduranceHours` | 30 h | ≥ 24 h | yes |
| 2 | `reportLatencySeconds` | 50 s | ≤ 60 s | yes |
| 2 | `positionErrorWithoutGnssMeters` | 42 m | ≤ 50 m | yes |
| 2 | `reportHoldMinutes` | 34 min | ≥ 30 min | yes |
| 2 | `reportsLostInLinkGap` | 0 | ≤ 0 | yes |
| 2 | `missedDetectionShare` | 0.08 | ≤ 0.1 | yes |
| 2 | `falseAlarmsPerHour` | 1.6 1/h | ≤ 2 1/h | yes |
| 2 | `operatorAlertsPerHour` | 17 1/h | ≤ 20 1/h | yes |
| 2 | `acknowledgedReportsThatMatterShare` | 0.81 | ≥ 0.8 | yes |
| 2 | `onboardClassificationCostUsd` | 285 USD | ≤ 300 USD | yes |

## Review

I would take Alternative 2. Alternative 1 puts every deciding coordination function on groundControlStation, including deconflictMembers and relayLink, which only make sense on the mesh. The result is a ground-hosted catch-all component. The model's own documentation says coordination stops fleet-wide on link or station loss, and that members fly their last directive (localFallbackOnIsolation) with no controlled landing. It accepts that single point of failure as a hazard and misses two targets: groundLinkLoss 0.55 and endurance 20 h. Alternative 2 moves all eight coordination functions onto SurveillanceDrone, with a lowest-id coordinator election, and reduces GroundStation to a gateway for C2 and classifier versions. Coordination, correlation and report holding therefore survive a lost link. Its weaknesses are real and should be fixed at the next layer. The member is overloaded, and the four rules sit on the same MemberMode that detects and coordinates, with no independent monitor. If the ground station fails, the fleet keeps flying with no recall path and no landing policy. Recharge requests reach the ground crew only through groundStation, so the claims of 0.92 coverage with the ground down and 30 h endurance are overstated. coverageLossOnMemberLoss 0.18 is below the duty-cycle floor of about 0.21 and has no mechanism behind it. The two new hazards are 'satisfied' by the components that cause them, and the triple wiring (fleet, memberA, memberB) plus the ring 'so every mesh port is used' pads the model without adding architecture. Even so, Alternative 2's split of responsibilities is the one that survives the next layer.

### Alternative 1

- **cohesion** 2/5 — groundControlStation is a catch-all. It holds all five #C2 functions, manageClassifierVersion, triage and correlation, and every deciding #Coordination function. That includes relayLink and deconflictMembers, which are jobs for the airborne mesh, not for a ground node. The SurveillanceDrone member is cohesive, but the ground component has no single job. The four rules sit on MemberMode in the same member that detects, classifies and reports, with no separate monitor.
- **coupling** 2/5 — Every handover, rotation, redistribution, deconfliction, relay assignment, correlation, track handover and admission crosses the ground link as a directiveOut → fleet.directiveIn message. Raw detections, decision contributions and status all go up to be finished on the ground. peerLink is a single one-way link from memberA to memberB, so the model routes almost nothing member-to-member.
- **realisability** 2.5/5 — The ground station and the member can each be procured as separate items. But deconfliction and relay decided on the ground, with a ground-link round trip, cannot plausibly give safe separation between members sharing airspace. The author admits groundLinkLossAreaUnderWatchShare 0.55 and watchEnduranceHours 20, both below target, and that honesty counts for something. The claim of jammedMeshAreaUnderWatchShare 0.80 assumes every member has its own ground link, but the reportLatency basis says reports take 'a mesh hop to a ground-link-capable member'. Those two bases contradict each other.
- **evolvability** 2/5 — Coordination policy can be changed in one place, which helps. But any requirement for operation without the ground (link outage, ground-station failure, more members) forces coordination back onto SurveillanceDrone. That means new member ports, new modes and new hazard allocations, which is the whole of alternative 2's work. localFallbackOnIsolation is a stopgap, not a way to grow the design.
- **groundLinkLossResilience** 2/5 — While the link is down, watch, detection, classification, navigation, and report and decision-record holding carry on on board (reportsLostInLinkGap 0, hold 45 min). All re-planning stops fleet-wide, including deconfliction, and so does the triage the operator depends on. Members fly their last directive, and the model gives no time bound for how long that is safe. The model accepts GroundLinkSinglePointOfFailureHazard rather than mitigating it, and estimates 0.55 against a 0.9 target.
- **groundNodeLossResilience** 1.5/5 — The groundControlStation doc says that if the station fails, coordination 'stop[s] being decided anywhere' and there is no member-side fallback. Members fly their last assignment, with no redistribution, no recharge rotation and no deconfliction. Recall is also lost. No controlled landing on ground loss is modelled, and coverage is not restored until the station returns. The only thing the hazard does is state the risk and accept it.

### Alternative 2

- **cohesion** 3.5/5 — GroundStation has one clear job: a thin gateway for the five #C2 functions plus classifier-version management. SurveillanceDrone is overloaded. It does watch, sensing, navigation, reporting and all eight coordination functions, and also enforces RecallWins, GeofenceBreachEndsWatch and the other rules on the same MemberMode, with no separate monitor. That will have to be split at the next layer. On the plus side, recall arrives on its own recallIn port, and MemberMode adds Recalled transitions out of the degraded modes.
- **coupling** 3/5 — Only C2 traffic, reports, status and recharge requests cross the ground boundary. Coordination stays on the mesh (peerLink plus peerLinkReturn). The wiring is noisy, though. Each downlink and uplink is connected three times (to fleet, memberA and memberB), and fleetMeshDown and fleetMeshUp exist, in the author's words, 'so every mesh port is used'. That is model hygiene, not architecture, and it inflates the connection count.
- **realisability** 3/5 — The coordinator election (lowest reachable platform id) is concrete and can be built. Several estimates go beyond what their bases support. coverageLossOnMemberLoss 0.18 is below the duty-cycle floor of about 0.208 (1/(12·40/100)). That figure is the loss before redistribution, so faster onboard re-spread cannot lower it. groundLinkLossAreaUnderWatchShare 0.92 and watchEnduranceHours 30 ignore that rechargeRequestOut reaches the ground crew only through groundStation. CoordinationForkHazard and GroundBlindSpotHazard are 'satisfied' by the very components that create them, with no mechanism given for reconciling a partition.
- **evolvability** 3.5/5 — The ground gateway is thin, so it can be duplicated or replaced without touching the members. A policy for landing when the ground is lost, or for merging split partitions, would be a change to MemberMode and the coordination functions only. The risk is that the monolithic member makes each such change a change to the whole flight item.
- **groundLinkLossResilience** 4/5 — All eight coordination functions keep running on the mesh with no time limit stated. Reports and decision records queue on board, and correlation and de-duplication happen before reports leave the fleet, so the operator's sorting survives the gap. What stops is new tasking, supervision, acknowledgement, the status picture (the GroundBlindSpotHazard names this) and recall. Recharge requests to the ground crew are also cut off, which caps the 0.92 claim for longer outages.
- **groundNodeLossResilience** 3/5 — Coverage is kept: members re-elect and keep coordinating with no ground confirmation. But the SurveillanceDrone doc says the fleet keeps watching 'indefinitely' with no recall able to reach it. There is no controlled landing when the ground node is lost, recharge requests have nowhere to go, and nobody owns classifier versions. The fleet coordinates well but cannot be commanded, and its watch will run down once recharge slots are no longer booked.
