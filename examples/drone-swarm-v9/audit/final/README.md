# SurveillanceDroneSwarm — final audit

Model: `/home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/SurveillanceDroneSwarm.sysml` (3690 elements)
Sysprose: 2c9de31
Run: autonomous mode, 21 model call(s), 10.82 USD, 5356 s of model time, over 9 legs

## Checked by the shipped CLI, not by this workflow

`npm run check -- /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/SurveillanceDroneSwarm.sysml --json` → exit 0 (clean), 49 diagnostic(s)
`npm run sysprose -- requirements /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/SurveillanceDroneSwarm.sysml --json` → 49/49 satisfied (100 %)

## Realization chain

| From | To | Realised | Of |
|---|---|---|---|
| OA | SA | 38 | 38 |
| SA | LA | 21 | 26 |
| LA | PA | 21 | 21 |
| PA | EPBS | 7 | 7 |

## Every check this step ran

| Check | Verdict | Command |
|---|---|---|
| `check` | clear | `npm run check -- /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/7_EPBS.sysml --json` |
| `stats` | clear | `npm run sysprose -- stats /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/7_EPBS.sysml --json` |
| `trace-trace` | clear | `npm run sysprose -- trace /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/7_EPBS.sysml --relation trace --json` |
| `trace-allocate` | clear | `npm run sysprose -- trace /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/7_EPBS.sysml --relation allocate --from ActionUsage --to PartUsage --json` |
| `requirements` | clear | `npm run sysprose -- requirements /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/7_EPBS.sysml --json` |
| `reach` | clear | `npm run sysprose -- reach /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/7_EPBS.sysml --json` |
| `connectivity` | clear | `npm run sysprose -- connectivity /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/7_EPBS.sysml --json` |
| `orphans` | clear | `npm run sysprose -- orphans /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/7_EPBS.sysml --json` |
| `elements` | clear | `npm run sysprose -- elements /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/7_EPBS.sysml --json` |
| `evidence-status` | clear | `npm run sysprose -- evidence-status /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/7_EPBS.sysml --json` |

## Can a person review this?

| Layer | Elements | Documented | |
|---|---|---|---|
| Common | 93 | 93 | 100 % |
| OA | 103 | 103 | 100 % |
| SA | 113 | 98 | 87 % |
| LA | 69 | 57 | 83 % |
| PA | 115 | 113 | 98 % |
| EPBS | 64 | 64 | 100 % |

29 element(s) carry no doc and no realization link — a reader cannot ask why they exist:
- `SurveillanceDroneSwarm::SA::taskingLink`
- `SurveillanceDroneSwarm::SA::supervisoryLink`
- `SurveillanceDroneSwarm::SA::recallLink`
- `SurveillanceDroneSwarm::SA::acknowledgementLink`
- `SurveillanceDroneSwarm::SA::objectsLink`
- `SurveillanceDroneSwarm::SA::clearanceLink`
- `SurveillanceDroneSwarm::SA::servicedDroneLink`
- `SurveillanceDroneSwarm::SA::reportsLink`
- `SurveillanceDroneSwarm::SA::alertsLink`
- `SurveillanceDroneSwarm::SA::trackPictureLink`
- `SurveillanceDroneSwarm::SA::statusLink`
- `SurveillanceDroneSwarm::SA::decisionRecordsLink`
- `SurveillanceDroneSwarm::SA::rechargeArrivalLink`
- `SurveillanceDroneSwarm::SA::recoveryArrivalLink`
- `SurveillanceDroneSwarm::SA::cameraTracksLink`
- `SurveillanceDroneSwarm::LA::reportsFeed`
- `SurveillanceDroneSwarm::LA::trackPictureFeed`
- `SurveillanceDroneSwarm::LA::statusFeed`
- `SurveillanceDroneSwarm::LA::taskingFeed`
- `SurveillanceDroneSwarm::LA::priorityFeed`
- `SurveillanceDroneSwarm::LA::recallFeed`
- `SurveillanceDroneSwarm::LA::receiptFeed`
- `SurveillanceDroneSwarm::LA::recordReceiptFeed`
- `SurveillanceDroneSwarm::LA::alertsFeed`
- `SurveillanceDroneSwarm::LA::recordsFeed`
- `SurveillanceDroneSwarm::LA::«ConstraintUsage»`
- `SurveillanceDroneSwarm::LA::«ConstraintUsage»`
- `SurveillanceDroneSwarm::PA::«ConstraintUsage»`
- `SurveillanceDroneSwarm::PA::«ConstraintUsage»`

| Step | Lines a reviewer read |
|---|---|
| S00 | 868 |
| S10 | 482 |
| S20 | 339 |
| S21 | 614 |
| S30 | 335 |
| S31 | 696 |
| S32 | 578 |
| S33 | 440 |
| S40 | 158 |
| S41 | 592 |
| S42 | 507 |
| S50 | 998 |

## Behaviour

Each state machine against the properties it states, or — for a machine written to come back to the state it opens at — that every reachable configuration can get back there. A machine with no transition back is a lifecycle and gets no default.

| Machine | Property | Verdict | Detail |
|---|---|---|---|
| `OA::SwarmMemberModes` | recovery to Nominal | undecided | inconclusive: this machine names triggers this walk offers at every configuration, so "reachable from every configuration" would be a claim  |
| `OA::SwarmMemberStates` | recovery to Landed | undecided | inconclusive: this machine names triggers this walk offers at every configuration, so "reachable from every configuration" would be a claim  |
| `OA::FleetModes` | recovery to MeshIntact | undecided | inconclusive: this machine names triggers this walk offers at every configuration, so "reachable from every configuration" would be a claim  |
| `OA::FleetStates` | recovery to Grounded | undecided | inconclusive: this machine names triggers this walk offers at every configuration, so "reachable from every configuration" would be a claim  |
| `SA::SwarmMember::SwarmMemberModes` | carried | holds | pass — holds on every reachable configuration: `state Nominal` never holds, between each `state Quarantined` and the next `state Readmitted` |
| `SA::SwarmMember::SwarmMemberStates` | carried | undecided | pass — holds on every reachable configuration: `state Watching` never holds, between each `state Recalled` and the next `state Landed`. exha |
| `SA::FleetConfiguration` | recovery to MeshIntact | undecided | inconclusive: this machine names triggers this walk offers at every configuration, so "reachable from every configuration" would be a claim  |
| `LA::FleetConfiguration` | recovery to MeshIntact | holds | recoverable: `state MeshIntact` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxComple |
| `LA::SwarmMember::SwarmMemberModes` | carried | holds | pass — holds on every reachable configuration: `state Nominal` never holds, between each `state Quarantined` and the next `state Readmitted` |
| `LA::SwarmMember::SwarmMemberStates` | carried | holds | pass — holds on every reachable configuration: `state Watching` never holds, between each `state Recalled` and the next `state Landed`. exha |
| `LA::GroundStation::GroundStationModes` | recovery to LinkUp | holds | recoverable: `state LinkUp` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxCompletion |
| `LA::GroundStation::GroundStationStates` | recovery to Standby | holds | recoverable: `state Standby` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxCompletio |
| `PA::SwarmMember::SwarmMemberModes` | carried | holds | pass — holds on every reachable configuration: `state Nominal` never holds, between each `state Quarantined` and the next `state Readmitted` |
| `PA::SwarmMember::SwarmMemberStates` | carried | undecided | pass — holds on every reachable configuration: `state Watching` never holds, between each `state Recalled` and the next `state Landed`. exha |
| `PA::GroundStationNode::GroundStationModes` | recovery to LinkUp | holds | recoverable: `state LinkUp` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxCompletion |
| `PA::GroundStationNode::GroundStationStates` | recovery to Standby | holds | recoverable: `state Standby` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxCompletio |
| `PA::FleetConfiguration` | recovery to MeshIntact | holds | recoverable: `state MeshIntact` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxComple |

Fault tree: not applicable. It computes which component contract failures break a top requirement, and no layer of this workflow writes component contracts that refine one — so there is nothing to cut, and no claim about single points of failure is made here.

## What an edit costs

If a person edits one layer's fragment and resumes: the step that wrote it is re-checked (never re-authored), and every step built on it runs again. The cost is what those steps spent in this run — a guide, since a resume may repair less or more.

| Layer edited | Fragment lines | Re-checked | Runs again | Calls those steps made | USD |
|---|---|---|---|---|---|
| Kinds | 15 | S00 | S10…S60 (16) | 20 | 9.44 |
| Common | 890 | S00 | S10…S60 (16) | 20 | 9.44 |
| OA | 483 | S10 | S20…S60 (14) | 19 | 8.90 |
| SA | 708 | S21 | S30…S60 (11) | 18 | 8.23 |
| LA | 589 | S33 | S40…S60 (6) | 11 | 4.58 |
| PA | 617 | S42 | S50…S60 (2) | 7 | 1.96 |
| EPBS | 499 | S50 | — | 0 | 0.00 |

## Measures

The worst case over the `#Estimate` each layer's chosen architecture states. These are the architecture's own claims with their basis in the doc, checked for consistency by the solver — not measurements.

| Measure | Target | LA | PA |
|---|---|---|---|
| `areaUnderWatchFraction` | ≥ 0.9 | 0.78216 (derived) ✗ | 0.78216 (derived) ✗ |
| `coverageLossAfterMemberLossFraction` | ≤ 0.25 | 0.153421 (derived) ✓ | 0.153421 (derived) ✓ |
| `coverageUnderMeshJammingFraction` | ≥ 0.75 (placeholder) | 0.66216 (derived) — missed a placeholder | 0.66216 (derived) — missed a placeholder |
| `reportAgeAtOperationsCentreSeconds` | ≤ 60 s (placeholder) | 40 s ✓ | 40 s ✓ |
| `positionErrorWithoutSatelliteMetres` | ≤ 50 m (placeholder) | 80 m — missed a placeholder | 80 m — missed a placeholder |
| `reportHoldWhileCutOffMinutes` | ≥ 30 min (placeholder) | 40 min ✓ | 40 min ✓ |
| `missedDetectionFraction` | ≤ 0.1 (placeholder) | 0.12 — missed a placeholder | 0.12 — missed a placeholder |
| `falseAlarmsPerHour` | ≤ 2 1/h (placeholder) | 3 1/h — missed a placeholder | 3 1/h — missed a placeholder |
| `alertsReachingOperatorPerHour` | ≤ 20 1/h (placeholder) | 24 1/h — missed a placeholder | 20 1/h ✓ |
| `acknowledgedReportsThatMatterFraction` | ≥ 0.8 (placeholder) | 0.7 — missed a placeholder | 0.75 — missed a placeholder |
| `onboardClassificationCostUsdPerMember` | ≤ 300 USD (placeholder) | 350 USD — missed a placeholder | 350 USD — missed a placeholder |
| `unattendedWatchDurationHours` | — | 0.666667 h (derived) | 0.666667 h (derived) |

### No architecture compared meets these

Every alternative at every layer missed the target. That is a question about the target or the brief — revisit the number, or what the brief fixes (a fleet size, a duty cycle) — not a reason to prefer one design.

- `positionErrorWithoutSatelliteMetres` ≤ 50 m (placeholder): missed by 4/4 alternatives
- `missedDetectionFraction` ≤ 0.1 (placeholder): missed by 4/4 alternatives
- `falseAlarmsPerHour` ≤ 2 1/h (placeholder): missed by 4/4 alternatives
- `acknowledgedReportsThatMatterFraction` ≥ 0.8 (placeholder): missed by 4/4 alternatives
- `onboardClassificationCostUsdPerMember` ≤ 300 USD (placeholder): missed by 4/4 alternatives

### Every architecture compared meets these

They added the same to every alternative's score, so the choice was made by the rest. A target nobody misses is a question about the target: is it the customer's?

- `reportAgeAtOperationsCentreSeconds` ≤ 60 s (placeholder): met by 4/4 alternatives
- `reportHoldWhileCutOffMinutes` ≥ 30 min (placeholder): met by 4/4 alternatives

9 of these 11 targets are placeholders in the brief, awaiting the customer's numbers: a ✓ against one says the design meets the placeholder, nothing more, and a miss is a number to take to the customer, not a failure of the design.

`unattendedWatchDurationHours`: the brief states no number, so there is no target. Each layer's estimate is shown, nothing is met or missed, and the trade-offs did not score it.

## The fleet

| Layer | Member definition | Fleet | Representatives | Links between members | Coordination and C2 on board |
|---|---|---|---|---|---|
| SA | yes | — | — | — | 0/13 |
| LA | yes | [12] | `memberA`, `memberB` | `peerLink` : MeshInterface | 8/13 |
| PA | yes | [12] | `memberA`, `memberB` | `peerLink` : MeshInterface, `peerLinkReturn` : MeshInterface, `meshRadioLinkAB` : MeshRadioMedium, `meshRadioLinkBA` : MeshRadioMedium | 8/13 |
| EPBS | — | `DroneAirframe` [1] | — | — | — |

Connectivity counts usages, not instances: a link between two representatives is one wired occurrence standing for every pair of members that exchange (CV-16).

### Where command and control sits at LA

One row per function definition. A definition is on board when every usage sits on a member or the fleet, on the ground when any usage sits elsewhere, and neither when only actors perform it.

| Function | Tag | Usages and where they are allocated | Where it sits |
|---|---|---|---|
| `HandOverSector` | Coordination | `handOverSector` → `fleet` | on board |
| `RotateRecharge` | Coordination | `rotateRecharge` → `fleet` | on board |
| `RedistributeCoverage` | Coordination | `redistributeCoverage` → `fleet` | on board |
| `DeconflictFlight` | Coordination | `deconflictFlight` → `fleet` | on board |
| `RelayReportsThroughNeighbour` | Coordination | `relayReportsThroughNeighbour` → `fleet` | on board |
| `CorrelateTracks` | Coordination | `correlateTracks` → `fleet` | on board |
| `HandOverTrack` | Coordination | `handOverTrack` → `fleet` | on board |
| `AdmitMember` | Coordination | `admitMember` → `fleet` | on board |
| `TaskSurveillanceArea` | C2 | `taskSurveillanceArea` → `groundStation` | ground |
| `CommandSupervisoryPriorities` | C2 | `commandSupervisoryPriorities` → `groundStation` | ground |
| `RecallAndLand` | C2 | `recallAndLand` → `groundStation` | ground |
| `PresentStatusPicture` | C2 | `presentStatusPicture` → `groundStation` | ground |
| `AcknowledgeDetectionReport` | C2 | `acknowledgeDetectionReport` → `groundStation` | ground |

### Where command and control sits at PA

One row per function definition. A definition is on board when every usage sits on a member or the fleet, on the ground when any usage sits elsewhere, and neither when only actors perform it.

| Function | Tag | Usages and where they are allocated | Where it sits |
|---|---|---|---|
| `HandOverSector` | Coordination | `handOverSector` → `fleet` | on board |
| `RotateRecharge` | Coordination | `rotateRecharge` → `fleet` | on board |
| `RedistributeCoverage` | Coordination | `redistributeCoverage` → `fleet` | on board |
| `DeconflictFlight` | Coordination | `deconflictFlight` → `fleet` | on board |
| `RelayReportsThroughNeighbour` | Coordination | `relayReportsThroughNeighbour` → `fleet` | on board |
| `CorrelateTracks` | Coordination | `correlateTracks` → `fleet` | on board |
| `HandOverTrack` | Coordination | `handOverTrack` → `fleet` | on board |
| `AdmitMember` | Coordination | `admitMember` → `fleet` | on board |
| `TaskSurveillanceArea` | C2 | `taskSurveillanceArea` → `groundStation` | ground |
| `CommandSupervisoryPriorities` | C2 | `commandSupervisoryPriorities` → `groundStation` | ground |
| `RecallAndLand` | C2 | `recallAndLand` → `groundRecallTransmitter` | ground |
| `PresentStatusPicture` | C2 | `presentStatusPicture` → `groundStation` | ground |
| `AcknowledgeDetectionReport` | C2 | `acknowledgeDetectionReport` → `groundStation` | ground |

## Reported, not blocking

- `validation/constraint-violation` areaUnderWatchTarget: Constraint could not be evaluated ("areaUnderWatchFraction >= 0.9"): Could not evaluate: areaUnderWatchFraction has no value here; evaluated per specialisation: LA::areaUnderWatchFraction, PA::areaUnderWatchFraction.
- `validation/constraint-violation` coverageLossAfterMemberLossTarget: Constraint could not be evaluated ("coverageLossAfterMemberLossFraction <= 0.25"): Could not evaluate: coverageLossAfterMemberLossFraction has no value here; evaluated per specialisation: LA::coverageLossAfterMemberLossFraction, PA::coverageLossAfterMemberLossFraction.
- `validation/constraint-violation` coverageUnderMeshJammingTarget: Constraint could not be evaluated ("coverageUnderMeshJammingFraction >= 0.75"): Could not evaluate: coverageUnderMeshJammingFraction has no value here; evaluated per specialisation: LA::coverageUnderMeshJammingFraction, PA::coverageUnderMeshJammingFraction.
- `validation/constraint-violation` reportAgeAtOperationsCentreTarget: Constraint could not be evaluated ("reportAgeAtOperationsCentreSeconds <= 60.0"): Could not evaluate: reportAgeAtOperationsCentreSeconds has no value here; evaluated per specialisation: LA::reportAgeAtOperationsCentreSeconds, PA::reportAgeAtOperationsCentreSeconds.
- `validation/constraint-violation` positionErrorWithoutSatelliteTarget: Constraint could not be evaluated ("positionErrorWithoutSatelliteMetres <= 50.0"): Could not evaluate: positionErrorWithoutSatelliteMetres has no value here; evaluated per specialisation: LA::positionErrorWithoutSatelliteMetres, PA::positionErrorWithoutSatelliteMetres.
- `validation/constraint-violation` reportHoldWhileCutOffTarget: Constraint could not be evaluated ("reportHoldWhileCutOffMinutes >= 30.0"): Could not evaluate: reportHoldWhileCutOffMinutes has no value here; evaluated per specialisation: LA::reportHoldWhileCutOffMinutes, PA::reportHoldWhileCutOffMinutes.
- `validation/constraint-violation` missedDetectionTarget: Constraint could not be evaluated ("missedDetectionFraction <= 0.10"): Could not evaluate: missedDetectionFraction has no value here; evaluated per specialisation: LA::missedDetectionFraction, PA::missedDetectionFraction.
- `validation/constraint-violation` falseAlarmsPerHourTarget: Constraint could not be evaluated ("falseAlarmsPerHour <= 2.0"): Could not evaluate: falseAlarmsPerHour has no value here; evaluated per specialisation: LA::falseAlarmsPerHour, PA::falseAlarmsPerHour.
- `validation/constraint-violation` alertsReachingOperatorTarget: Constraint could not be evaluated ("alertsReachingOperatorPerHour <= 20.0"): Could not evaluate: alertsReachingOperatorPerHour has no value here; evaluated per specialisation: LA::alertsReachingOperatorPerHour, PA::alertsReachingOperatorPerHour.
- `validation/constraint-violation` acknowledgedReportsThatMatterTarget: Constraint could not be evaluated ("acknowledgedReportsThatMatterFraction >= 0.8"): Could not evaluate: acknowledgedReportsThatMatterFraction has no value here; evaluated per specialisation: LA::acknowledgedReportsThatMatterFraction, PA::acknowledgedReportsThatMatterFraction.
- `validation/constraint-violation` onboardClassificationCostTarget: Constraint could not be evaluated ("onboardClassificationCostUsdPerMember <= 300.0"): Could not evaluate: onboardClassificationCostUsdPerMember has no value here; evaluated per specialisation: LA::onboardClassificationCostUsdPerMember, PA::onboardClassificationCostUsdPerMember.
- `validation/constraint-violation` fleetSizeBudget: Constraint could not be evaluated ("fleetSizeMembers <= 12"): Could not evaluate: fleetSizeMembers has no value anywhere and nothing specialises it.
- `validation/constraint-violation` memberEnduranceBudget: Constraint could not be evaluated ("memberEnduranceMinutes <= 40.0"): Could not evaluate: memberEnduranceMinutes has no value anywhere and nothing specialises it.
- `validation/constraint-violation` groundTurnaroundBudget: Constraint could not be evaluated ("groundTurnaroundMinutes >= 20.0"): Could not evaluate: groundTurnaroundMinutes has no value anywhere and nothing specialises it.
- `validation/constraint-violation` cruiseSpeedBudget: Constraint could not be evaluated ("cruiseSpeedMetresPerSecond <= 18.0"): Could not evaluate: cruiseSpeedMetresPerSecond has no value anywhere and nothing specialises it.
- `validation/constraint-violation` instantaneousFootprintBudget: Constraint could not be evaluated ("instantaneousFootprintSquareKilometres <= 3.0"): Could not evaluate: instantaneousFootprintSquareKilometres has no value anywhere and nothing specialises it.
- `validation/constraint-violation` areaOfInterestBudget: Constraint could not be evaluated ("areaOfInterestSquareKilometres <= 25.0"): Could not evaluate: areaOfInterestSquareKilometres has no value anywhere and nothing specialises it.
- `validation/constraint-violation` operatorSecondsPerAlertBudget: Constraint could not be evaluated ("operatorSecondsPerAlert >= 30.0"): Could not evaluate: operatorSecondsPerAlert has no value anywhere and nothing specialises it.
- `validation/constraint-violation` trackStaleAfterBudget: Constraint could not be evaluated ("trackStaleAfterSeconds <= 120.0"): Could not evaluate: trackStaleAfterSeconds has no value anywhere and nothing specialises it.
- `validation/constraint-violation` satellitePositioningOutageBudget: Constraint could not be evaluated ("satellitePositioningOutageMinutes == 10.0"): Could not evaluate: satellitePositioningOutageMinutes has no value anywhere, no asserted equation, and nothing specialises it.
- `validation/constraint-violation` meshLinksJammedBudget: Constraint could not be evaluated ("meshLinksJammedFraction == 0.5"): Could not evaluate: meshLinksJammedFraction has no value anywhere, no asserted equation, and nothing specialises it.
- `validation/target-by-specialisation` areaUnderWatchFraction: LA::areaUnderWatchFraction = 0.78216 misses Common::areaUnderWatchTarget (areaUnderWatchFraction >= 0.9)
- `validation/target-by-specialisation` coverageLossAfterMemberLossFraction: LA::coverageLossAfterMemberLossFraction = 0.153421 meets Common::coverageLossAfterMemberLossTarget (coverageLossAfterMemberLossFraction <= 0.25)
- `validation/target-by-specialisation` coverageUnderMeshJammingFraction: LA::coverageUnderMeshJammingFraction = 0.66216 misses Common::coverageUnderMeshJammingTarget (coverageUnderMeshJammingFraction >= 0.75) — missed a placeholder, not the customer's number
- `validation/target-by-specialisation` reportAgeAtOperationsCentreSeconds: LA::reportAgeAtOperationsCentreSeconds = 40 meets Common::reportAgeAtOperationsCentreTarget (reportAgeAtOperationsCentreSeconds <= 60.0)
- `validation/target-by-specialisation` positionErrorWithoutSatelliteMetres: LA::positionErrorWithoutSatelliteMetres = 80 misses Common::positionErrorWithoutSatelliteTarget (positionErrorWithoutSatelliteMetres <= 50.0) — missed a placeholder, not the customer's number
- `validation/target-by-specialisation` reportHoldWhileCutOffMinutes: LA::reportHoldWhileCutOffMinutes = 40 meets Common::reportHoldWhileCutOffTarget (reportHoldWhileCutOffMinutes >= 30.0)
- `validation/target-by-specialisation` missedDetectionFraction: LA::missedDetectionFraction = 0.12 misses Common::missedDetectionTarget (missedDetectionFraction <= 0.10) — missed a placeholder, not the customer's number
- `validation/target-by-specialisation` falseAlarmsPerHour: LA::falseAlarmsPerHour = 3 misses Common::falseAlarmsPerHourTarget (falseAlarmsPerHour <= 2.0) — missed a placeholder, not the customer's number
- `validation/target-by-specialisation` alertsReachingOperatorPerHour: LA::alertsReachingOperatorPerHour = 24 misses Common::alertsReachingOperatorTarget (alertsReachingOperatorPerHour <= 20.0) — missed a placeholder, not the customer's number
- `validation/target-by-specialisation` acknowledgedReportsThatMatterFraction: LA::acknowledgedReportsThatMatterFraction = 0.7 misses Common::acknowledgedReportsThatMatterTarget (acknowledgedReportsThatMatterFraction >= 0.8) — missed a placeholder, not the customer's number
- `validation/target-by-specialisation` onboardClassificationCostUsdPerMember: LA::onboardClassificationCostUsdPerMember = 350 misses Common::onboardClassificationCostTarget (onboardClassificationCostUsdPerMember <= 300.0) — missed a placeholder, not the customer's number
- `validation/target-by-specialisation` areaUnderWatchFraction: PA::areaUnderWatchFraction = 0.78216 misses Common::areaUnderWatchTarget (areaUnderWatchFraction >= 0.9)
- `validation/target-by-specialisation` coverageLossAfterMemberLossFraction: PA::coverageLossAfterMemberLossFraction = 0.153421 meets Common::coverageLossAfterMemberLossTarget (coverageLossAfterMemberLossFraction <= 0.25)
- `validation/target-by-specialisation` coverageUnderMeshJammingFraction: PA::coverageUnderMeshJammingFraction = 0.66216 misses Common::coverageUnderMeshJammingTarget (coverageUnderMeshJammingFraction >= 0.75) — missed a placeholder, not the customer's number
- `validation/target-by-specialisation` reportAgeAtOperationsCentreSeconds: PA::reportAgeAtOperationsCentreSeconds = 40 meets Common::reportAgeAtOperationsCentreTarget (reportAgeAtOperationsCentreSeconds <= 60.0)
- `validation/target-by-specialisation` positionErrorWithoutSatelliteMetres: PA::positionErrorWithoutSatelliteMetres = 80 misses Common::positionErrorWithoutSatelliteTarget (positionErrorWithoutSatelliteMetres <= 50.0) — missed a placeholder, not the customer's number
- `validation/target-by-specialisation` reportHoldWhileCutOffMinutes: PA::reportHoldWhileCutOffMinutes = 40 meets Common::reportHoldWhileCutOffTarget (reportHoldWhileCutOffMinutes >= 30.0)
- `validation/target-by-specialisation` missedDetectionFraction: PA::missedDetectionFraction = 0.12 misses Common::missedDetectionTarget (missedDetectionFraction <= 0.10) — missed a placeholder, not the customer's number
- `validation/target-by-specialisation` falseAlarmsPerHour: PA::falseAlarmsPerHour = 3 misses Common::falseAlarmsPerHourTarget (falseAlarmsPerHour <= 2.0) — missed a placeholder, not the customer's number
- `validation/target-by-specialisation` alertsReachingOperatorPerHour: PA::alertsReachingOperatorPerHour = 20 meets Common::alertsReachingOperatorTarget (alertsReachingOperatorPerHour <= 20.0)
- `validation/target-by-specialisation` acknowledgedReportsThatMatterFraction: PA::acknowledgedReportsThatMatterFraction = 0.75 misses Common::acknowledgedReportsThatMatterTarget (acknowledgedReportsThatMatterFraction >= 0.8) — missed a placeholder, not the customer's number
- `validation/target-by-specialisation` onboardClassificationCostUsdPerMember: PA::onboardClassificationCostUsdPerMember = 350 misses Common::onboardClassificationCostTarget (onboardClassificationCostUsdPerMember <= 300.0) — missed a placeholder, not the customer's number
- `validation/constraint-violation` : Constraint could not be evaluated ("compute.unitCostUsd <= 300 and compute.reportStorageHoldMinutes >= 30"): Could not evaluate: compute.unitCostUsd has no value: OnboardComputeModule::unitCostUsd is declared without one and nothing specialises it.
- `validation/constraint-violation` : Constraint could not be evaluated ("software.positionErrorMetres <= 50 and software.landsWhenRecalledOrOutsideClearance == true and software.returnsToRecoveryPointWhenIsolated == true and software.signedBaseline == true"): Could not evaluate: software.positionErrorMetres has no value: DroneFlightSoftware::positionErrorMetres is declared without one and nothing specialises it.
- `validation/constraint-violation` : Constraint could not be evaluated ("detector.missedDetectionFraction <= 0.1 and detector.falseAlarmsPerHour <= 2 and detector.reportsUnknownBelowThreshold == true and detector.stampsClassifierVersion == true"): Could not evaluate: detector.missedDetectionFraction has no value: DetectionClassifierSoftware::missedDetectionFraction is declared without one and nothing specialises it; detector.falseAlarmsPerHour has no value: DetectionClassifierSoftware::falseAlarmsPerHour is declared without one and nothing specialises it.
- `validation/constraint-violation` : Constraint could not be evaluated ("coordination.areaUnderWatchFraction >= 0.9 and coordination.coverageLossAfterMemberLossFraction <= 0.25 and coordination.coverageUnderMeshJammingFraction >= 0.75 and coordination.admitsOnlyAuthenticated == true"): Could not evaluate: coordination.areaUnderWatchFraction has no value: MemberCoordinationSoftware::areaUnderWatchFraction is declared without one and nothing specialises it; coordination.coverageLossAfterMemberLossFraction has no value: MemberCoordinationSoftware::coverageLossAfterMemberLossFraction is declared without one and nothing specialises it; coordination.coverageUnderMeshJammingFraction has no value: MemberCoordinationSoftware::coverageUnderMeshJammingFraction is declared without one and nothing specialises it.
- `validation/constraint-violation` : Constraint could not be evaluated ("coordination.areaUnderWatchFraction >= 0.9 and coordination.coverageLossAfterMemberLossFraction <= 0.25 and coordination.coverageUnderMeshJammingFraction >= 0.75 and coordination.admitsOnlyAuthenticated == true"): Could not evaluate: coordination.areaUnderWatchFraction has no value: GroundCoordinationSoftware::areaUnderWatchFraction is declared without one and nothing specialises it; coordination.coverageLossAfterMemberLossFraction has no value: GroundCoordinationSoftware::coverageLossAfterMemberLossFraction is declared without one and nothing specialises it; coordination.coverageUnderMeshJammingFraction has no value: GroundCoordinationSoftware::coverageUnderMeshJammingFraction is declared without one and nothing specialises it.
- `validation/constraint-violation` : Constraint could not be evaluated ("triage.alertsReachingOperatorPerHour <= 20 and triage.alertsReachingOperatorPerHour * triage.operatorSecondsPerAlert <= 3600 and triage.mergesDuplicates == true"): Could not evaluate: triage.alertsReachingOperatorPerHour has no value: AlertTriageSoftware::alertsReachingOperatorPerHour is declared without one and nothing specialises it.

## Steps

| Step | Status | Repairs | Gate |
|---|---|---|---|
| S00 | done | 0 | auto |
| S01 | skipped | 0 | — |
| S02 | skipped | 0 | — |
| S10 | done | 0 | — |
| S11 | done | 0 | — |
| S20 | done | 0 | — |
| S21 | done | 0 | — |
| S22 | done | 0 | — |
| S30 | done | 0 | — |
| S31 | done | 1 | — |
| S32 | done | 1 | — |
| S33 | done | 0 | — |
| S34 | done | 0 | — |
| S40 | done | 0 | — |
| S41 | done | 1 | — |
| S42 | done | 0 | — |
| S43 | done | 0 | — |
| S50 | done | 0 | auto |
| S60 | done | 0 | — |
| S70 | running | 0 | auto |
