# SurveillanceDroneSwarm — final audit

Model: `/home/xcos/Work/mbse-workflow/runs/v7/SurveillanceDroneSwarm.sysml` (3278 elements)
Sysprose: 91cc4a5
Run: autonomous mode, 21 model call(s), 40.43 USD, 9033 s of model time, over 4 legs

## Checked by the shipped CLI, not by this workflow

`npm run check -- /home/xcos/Work/mbse-workflow/runs/v7/SurveillanceDroneSwarm.sysml --json` → exit 0 (clean), 29 diagnostic(s)
`npm run sysprose -- requirements /home/xcos/Work/mbse-workflow/runs/v7/SurveillanceDroneSwarm.sysml --json` → 30/32 satisfied (94 %); all 2 unsatisfied are hazards accepted with their reason

## Realization chain

| From | To | Realised | Of |
|---|---|---|---|
| OA | SA | 44 | 44 |
| SA | LA | 28 | 28 |
| LA | PA | 28 | 28 |
| PA | EPBS | 5 | 5 |

## Every check this step ran

| Check | Verdict | Command |
|---|---|---|
| `check` | clear | `npm run check -- /home/xcos/Work/mbse-workflow/runs/v7/build/7_EPBS.sysml --json` |
| `stats` | clear | `npm run sysprose -- stats /home/xcos/Work/mbse-workflow/runs/v7/build/7_EPBS.sysml --json` |
| `trace-trace` | clear | `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v7/build/7_EPBS.sysml --relation trace --json` |
| `trace-allocate` | clear | `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v7/build/7_EPBS.sysml --relation allocate --from ActionUsage --to PartUsage --json` |
| `requirements` | clear | `npm run sysprose -- requirements /home/xcos/Work/mbse-workflow/runs/v7/build/7_EPBS.sysml --json` |
| `reach` | clear | `npm run sysprose -- reach /home/xcos/Work/mbse-workflow/runs/v7/build/7_EPBS.sysml --json` |
| `connectivity` | clear | `npm run sysprose -- connectivity /home/xcos/Work/mbse-workflow/runs/v7/build/7_EPBS.sysml --json` |
| `orphans` | clear | `npm run sysprose -- orphans /home/xcos/Work/mbse-workflow/runs/v7/build/7_EPBS.sysml --json` |
| `elements` | clear | `npm run sysprose -- elements /home/xcos/Work/mbse-workflow/runs/v7/build/7_EPBS.sysml --json` |
| `evidence-status` | clear | `npm run sysprose -- evidence-status /home/xcos/Work/mbse-workflow/runs/v7/build/7_EPBS.sysml --json` |

## Can a person review this?

| Layer | Elements | Documented | |
|---|---|---|---|
| Common | 31 | 30 | 97 % |
| OA | 97 | 97 | 100 % |
| SA | 98 | 98 | 100 % |
| LA | 116 | 116 | 100 % |
| PA | 94 | 94 | 100 % |
| EPBS | 38 | 38 | 100 % |

Every element either says what it is for or is linked to something that does.

| Step | Lines a reviewer read |
|---|---|
| S00 | 242 |
| S10 | 413 |
| S20 | 366 |
| S21 | 427 |
| S30 | 0 |
| S31 | 324 |
| S32 | 973 |
| S33 | 521 |
| S40 | 320 |
| S41 | 678 |
| S42 | 417 |
| S50 | 356 |

## Behaviour

Each state machine against the properties it states, or — for a machine written to come back to the state it opens at — that every reachable configuration can get back there. A machine with no transition back is a lifecycle and gets no default.

| Machine | Property | Verdict | Detail |
|---|---|---|---|
| `OA::WatchAssetMode` | recovery to Watching | holds | recoverable: `state Watching` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxCompleti |
| `OA::WatchAssetStatus` | recovery to Idle | holds | recoverable: `state Idle` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxCompletion 6 |
| `SA::SurveillanceDroneSwarmMode` | recovery to Covering | holds | recoverable: `state Covering` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxCompleti |
| `SA::SurveillanceDroneSwarmStatus` | recovery to Idle | holds | recoverable: `state Idle` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxCompletion 6 |
| `SA::SurveillanceDroneMode` | carried | holds | pass — holds on every reachable configuration: `state Watching` never holds, between each `state Recalled` and the next `state Landed`. exha |
| `SA::SurveillanceDroneStatus` | recovery to Idle | holds | recoverable: `state Idle` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxCompletion 6 |
| `LA::SwarmMode` | recovery to Covering | holds | recoverable: `state Covering` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxCompleti |
| `LA::FleetConfiguration` | recovery to Covering | holds | recoverable: `state Covering` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxCompleti |
| `LA::SwarmStatus` | recovery to Idle | holds | recoverable: `state Idle` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxCompletion 6 |
| `LA::SurveillanceDroneMode` | carried | holds | pass — holds on every reachable configuration: `state Watching` never holds, between each `state Recalled` and the next `state Landed`. exha |
| `LA::SurveillanceDroneStatus` | recovery to Idle | holds | recoverable: `state Idle` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxCompletion 6 |
| `LA::SurveillanceDrone::MemberMode` | carried | holds | pass — holds on every reachable configuration: `state Watching` never holds, between each `state Recalled` and the next `state Landed`. exha |
| `LA::SurveillanceDrone::MemberState` | recovery to Idle | holds | recoverable: `state Idle` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxCompletion 6 |
| `LA::GroundStationMode` | recovery to Linked | holds | recoverable: `state Linked` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxCompletion |
| `LA::GroundStationStatus` | recovery to Idle | holds | recoverable: `state Idle` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxCompletion 6 |
| `PA::SurveillanceDrone::MemberState` | carried | holds | pass — holds on every reachable configuration: `state Watching` never holds, between each `state Recalled` and the next `state Landed`. exha |
| `PA::SurveillanceDrone::MemberMode` | carried | holds | pass — holds on every reachable configuration: `state Nominal` never holds, between each `state Quarantined` and the next `state Readmitted` |
| `PA::FleetConfiguration` | recovery to Nominal | holds | recoverable: `state Nominal` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxCompletio |
| `PA::GroundStation::GroundOperatingState` | recovery to Idle | holds | recoverable: `state Idle` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxCompletion 6 |
| `PA::GroundStation::GroundLinkMode` | recovery to LinkDown | holds | recoverable: `state LinkDown` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxCompleti |

Fault tree: not applicable. It computes which component contract failures break a top requirement, and no layer of this workflow writes component contracts that refine one — so there is nothing to cut, and no claim about single points of failure is made here.

## What an edit costs

If a person edits one layer's fragment and resumes: the step that wrote it is re-checked (never re-authored), and every step built on it runs again. The cost is what those steps spent in this run — a guide, since a resume may repair less or more.

| Layer edited | Fragment lines | Re-checked | Runs again | Calls those steps made | USD |
|---|---|---|---|---|---|
| Kinds | 15 | S00 | S10…S60 (16) | 20 | 38.86 |
| Common | 262 | S00 | S10…S60 (16) | 20 | 38.86 |
| OA | 414 | S10 | S20…S60 (14) | 18 | 32.59 |
| SA | 678 | S21 | S30…S60 (11) | 16 | 28.39 |
| LA | 981 | S33 | S40…S60 (6) | 8 | 11.80 |
| PA | 686 | S42 | S50…S60 (2) | 2 | 3.69 |
| EPBS | 357 | S50 | — | 0 | 0.00 |

## Measures

The worst case over the `#Estimate` each layer's chosen architecture states. These are the architecture's own claims with their basis in the doc, checked for consistency by the solver — not measurements.

| Measure | Target | LA | PA |
|---|---|---|---|
| `areaUnderWatchShare` | ≥ 0.9 | 0.92 ✓ | 0.92 ✓ |
| `coverageLossOnMemberLoss` | ≤ 0.25 | 0.18 ✓ | 0.08333333333333333 (derived) ✓ |
| `jammedMeshAreaUnderWatchShare` | ≥ 0.75 | 0.78 ✓ | 0.78 ✓ |
| `groundLinkLossAreaUnderWatchShare` | ≥ 0.9 | 0.92 ✓ | 0.91 ✓ |
| `watchEnduranceHours` | ≥ 24 h | 30 h ✓ | 48 h ✓ |
| `reportLatencySeconds` | ≤ 60 s | 50 s ✓ | 45 s ✓ |
| `positionErrorWithoutGnssMeters` | ≤ 50 m | 42 m ✓ | 35 m ✓ |
| `reportHoldMinutes` | ≥ 30 min | 34 min ✓ | 45 min ✓ |
| `reportsLostInLinkGap` | ≤ 0 | 0 ✓ | 0 ✓ |
| `missedDetectionShare` | ≤ 0.1 | 0.08 ✓ | 0.08 ✓ |
| `falseAlarmsPerHour` | ≤ 2 1/h | 1.6 1/h ✓ | 1.5 1/h ✓ |
| `operatorAlertsPerHour` | ≤ 20 1/h | 17 1/h ✓ | 16 1/h ✓ |
| `acknowledgedReportsThatMatterShare` | ≥ 0.8 | 0.81 ✓ | 0.83 ✓ |
| `onboardClassificationCostUsd` | ≤ 300 USD | 285 USD ✓ | 275 USD ✓ |

### Every architecture compared meets these

They added the same to every alternative's score, so the choice was made by the rest. A target nobody misses is a question about the target: is it the customer's?

- `areaUnderWatchShare` ≥ 0.9: met by 4/4 alternatives
- `coverageLossOnMemberLoss` ≤ 0.25: met by 4/4 alternatives
- `jammedMeshAreaUnderWatchShare` ≥ 0.75: met by 4/4 alternatives
- `reportLatencySeconds` ≤ 60 s: met by 4/4 alternatives
- `positionErrorWithoutGnssMeters` ≤ 50 m: met by 4/4 alternatives
- `reportHoldMinutes` ≥ 30 min: met by 4/4 alternatives
- `reportsLostInLinkGap` ≤ 0: met by 4/4 alternatives
- `missedDetectionShare` ≤ 0.1: met by 4/4 alternatives
- `falseAlarmsPerHour` ≤ 2 1/h: met by 4/4 alternatives
- `operatorAlertsPerHour` ≤ 20 1/h: met by 4/4 alternatives
- `acknowledgedReportsThatMatterShare` ≥ 0.8: met by 4/4 alternatives
- `onboardClassificationCostUsd` ≤ 300 USD: met by 4/4 alternatives

## The fleet

| Layer | Member definition | Fleet | Representatives | Links between members | Coordination and C2 on board |
|---|---|---|---|---|---|
| SA | yes | — | — | — | 0/13 |
| LA | yes | [12] | `memberA`, `memberB` | `peerLink` : MeshLink, `peerLinkReturn` : MeshLink | 8/13 |
| PA | yes | [12] | `memberA`, `memberB` | `peerLink` : MeshRadioLink, `peerLinkReturn` : MeshRadioLink | 7/13 |
| EPBS | — | `fleetCi` [12] | — | — | — |

Connectivity counts usages, not instances: a link between two representatives is one wired occurrence standing for every pair of members that exchange (CV-16).

### Where command and control sits at LA

One row per function definition. A definition is on board when every usage sits on a member or the fleet, on the ground when any usage sits elsewhere, and neither when only actors perform it.

| Function | Tag | Usages and where they are allocated | Where it sits |
|---|---|---|---|
| `PresentStatusPicture` | C2 | `presentStatusPicture` → `groundStation` | ground |
| `TaskMission` | C2 | `taskMission` → `groundStation`<br>`taskMissionAct` → `operationsCentre` | ground |
| `CommandSupervision` | C2 | `commandSupervision` → `groundStation`<br>`commandSupervisionAct` → `dutyController` | ground |
| `RecallAndLand` | C2 | `recallAndLand` → `groundStation`<br>`recallAndLandAct` → `dutyController` | ground |
| `AcknowledgeReport` | C2 | `acknowledgeReport` → `groundStation`<br>`acknowledgeReportAct` → `dutyController` | ground |
| `HandOverSector` | Coordination | `handOverSector` → `fleet` | on board |
| `RotateRecharge` | Coordination | `rotateRecharge` → `fleet` | on board |
| `RedistributeCoverage` | Coordination | `redistributeCoverage` → `fleet` | on board |
| `DeconflictMembers` | Coordination | `deconflictMembers` → `fleet` | on board |
| `RelayLink` | Coordination | `relayLink` → `fleet` | on board |
| `CorrelateTracks` | Coordination | `correlateTracks` → `fleet` | on board |
| `HandOverTrack` | Coordination | `handOverTrack` → `fleet` | on board |
| `AdmitMember` | Coordination | `admitMember` → `fleet` | on board |

### Where command and control sits at PA

One row per function definition. A definition is on board when every usage sits on a member or the fleet, on the ground when any usage sits elsewhere, and neither when only actors perform it.

| Function | Tag | Usages and where they are allocated | Where it sits |
|---|---|---|---|
| `PresentStatusPicture` | C2 | `presentStatusPicture` → `groundStation` | ground |
| `TaskMission` | C2 | `taskMission` → `groundStation`<br>`taskMissionAct` → `operationsCentre` | ground |
| `CommandSupervision` | C2 | `commandSupervision` → `groundStation`<br>`commandSupervisionAct` → `dutyController` | ground |
| `RecallAndLand` | C2 | `recallAndLand` → `groundStation`, `fleet`<br>`recallAndLandAct` → `dutyController` | ground |
| `AcknowledgeReport` | C2 | `acknowledgeReport` → `groundStation`<br>`acknowledgeReportAct` → `dutyController` | ground |
| `HandOverSector` | Coordination | `handOverSector` → `fleet` | on board |
| `RotateRecharge` | Coordination | `rotateRecharge` → `fleet` | on board |
| `RedistributeCoverage` | Coordination | `redistributeCoverage` → `fleet` | on board |
| `DeconflictMembers` | Coordination | `deconflictMembers` → `fleet` | on board |
| `RelayLink` | Coordination | `relayLink` → `fleet` | on board |
| `CorrelateTracks` | Coordination | `correlateTracks` → `fleet` | on board |
| `HandOverTrack` | Coordination | `handOverTrack` → `fleet` | on board |
| `AdmitMember` | Coordination | `admitMember` → `groundStation` | ground |

## Hazards accepted, not mitigated

Each carries its reason in its doc; a reviewer should read them.

- `SafetyMonitorSoleSourceHazard`
- `RechargePointSoleFacilityHazard`

## Left as TODO

- `SurveillanceDroneSwarm::PA::SurveillanceDroneSwarmPhysical`
- `SurveillanceDroneSwarm::PA::DutyController`
- `SurveillanceDroneSwarm::PA::Analysts`
- `SurveillanceDroneSwarm::PA::OperationsCentre`
- `SurveillanceDroneSwarm::PA::AirspaceAuthority`
- `SurveillanceDroneSwarm::PA::GroundCrew`
- `SurveillanceDroneSwarm::PA::FixedCameraNetworkOwner`
- `SurveillanceDroneSwarm::PA::ProgrammeSponsor`
- `SurveillanceDroneSwarm::PA::HoldSectorWatch`
- `SurveillanceDroneSwarm::PA::DetectAndClassifyObjects`
- `SurveillanceDroneSwarm::PA::NavigateAgainstStoredMaps`
- `SurveillanceDroneSwarm::PA::ReportDetections`
- `SurveillanceDroneSwarm::PA::RecordDecision`
- `SurveillanceDroneSwarm::PA::PresentStatusPicture`
- `SurveillanceDroneSwarm::PA::TaskMission`
- `SurveillanceDroneSwarm::PA::CommandSupervision`
- `SurveillanceDroneSwarm::PA::RecallAndLand`
- `SurveillanceDroneSwarm::PA::AcknowledgeReport`
- `SurveillanceDroneSwarm::PA::HandOverSector`
- `SurveillanceDroneSwarm::PA::RotateRecharge`
- `SurveillanceDroneSwarm::PA::RedistributeCoverage`
- `SurveillanceDroneSwarm::PA::DeconflictMembers`
- `SurveillanceDroneSwarm::PA::RelayLink`
- `SurveillanceDroneSwarm::PA::CorrelateTracks`
- `SurveillanceDroneSwarm::PA::HandOverTrack`
- `SurveillanceDroneSwarm::PA::AdmitMember`
- `SurveillanceDroneSwarm::PA::ManageClassifierVersionFunction`
- `SurveillanceDroneSwarm::PA::MergeWithCameraNetworkTracks`
- `SurveillanceDroneSwarm::PA::ViewStatusPicture`
- `SurveillanceDroneSwarm::PA::ServiceAndRecharge`
- `SurveillanceDroneSwarm::PA::ProvideCameraTracks`
- `SurveillanceDroneSwarm::PA::JudgeAlerts`

## Reported, not blocking

- `validation/constraint-violation` : Constraint could not be evaluated ("areaUnderWatchShare >= 0.9"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("coverageLossOnMemberLoss <= 0.25"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("jammedMeshAreaUnderWatchShare >= 0.75"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("groundLinkLossAreaUnderWatchShare >= 0.9"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("watchEnduranceHours >= 24"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("reportLatencySeconds <= 60"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("positionErrorWithoutGnssMeters <= 50"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("reportHoldMinutes >= 30"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("reportsLostInLinkGap <= 0"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("missedDetectionShare <= 0.1"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("falseAlarmsPerHour <= 2"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("operatorAlertsPerHour <= 20"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("acknowledgedReportsThatMatterShare >= 0.8"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("onboardClassificationCostUsd <= 300"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("fleetSize <= 12"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("operatorSecondsPerAlert >= 30"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("memberFlightEnduranceMinutes <= 40"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("memberRechargeMinutes >= 60"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("areaOfInterestKm2 <= 25"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("coverageLossOnMemberLoss == 1.0 / fleetSizeValue"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::fleetSizeValue <= 12"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::areaOfInterestBudget <= 25"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::fleetSizeValue <= 12"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::fleetSizeValue <= 12"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::fleetSizeValue <= 12"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::fleetSizeValue <= 12"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::areaOfInterestBudget <= 25"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::GroundStation::operatorAlertsPerHourBudget <= 20"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::RechargePoint::rechargeMinutesBudget <= 60"): Could not parse expression: Unexpected character ':' at 22.
- `trace.closure` SurveillanceDroneSwarm::PA::dutyController: PA → EPBS: `dutyController` is not realised.
- `trace.closure` SurveillanceDroneSwarm::PA::analysts: PA → EPBS: `analysts` is not realised.
- `trace.closure` SurveillanceDroneSwarm::PA::operationsCentre: PA → EPBS: `operationsCentre` is not realised.
- `trace.closure` SurveillanceDroneSwarm::PA::airspaceAuthority: PA → EPBS: `airspaceAuthority` is not realised.
- `trace.closure` SurveillanceDroneSwarm::PA::groundCrew: PA → EPBS: `groundCrew` is not realised.
- `trace.closure` SurveillanceDroneSwarm::PA::fixedCameraNetworkOwner: PA → EPBS: `fixedCameraNetworkOwner` is not realised.
- `trace.closure` SurveillanceDroneSwarm::PA::programmeSponsor: PA → EPBS: `programmeSponsor` is not realised.
- `final.todos` SurveillanceDroneSwarm::PA::SurveillanceDroneSwarmPhysical: `SurveillanceDroneSwarmPhysical` still carries a TODO from the transition skeleton.
- `final.todos` SurveillanceDroneSwarm::PA::DutyController: `DutyController` still carries a TODO from the transition skeleton.
- `final.todos` SurveillanceDroneSwarm::PA::Analysts: `Analysts` still carries a TODO from the transition skeleton.
- `final.todos` SurveillanceDroneSwarm::PA::OperationsCentre: `OperationsCentre` still carries a TODO from the transition skeleton.
- `final.todos` SurveillanceDroneSwarm::PA::AirspaceAuthority: `AirspaceAuthority` still carries a TODO from the transition skeleton.
- `final.todos` SurveillanceDroneSwarm::PA::GroundCrew: `GroundCrew` still carries a TODO from the transition skeleton.
- `final.todos` SurveillanceDroneSwarm::PA::FixedCameraNetworkOwner: `FixedCameraNetworkOwner` still carries a TODO from the transition skeleton.
- `final.todos` SurveillanceDroneSwarm::PA::ProgrammeSponsor: `ProgrammeSponsor` still carries a TODO from the transition skeleton.
- `final.todos` SurveillanceDroneSwarm::PA::HoldSectorWatch: `HoldSectorWatch` still carries a TODO from the transition skeleton.
- `final.todos` SurveillanceDroneSwarm::PA::DetectAndClassifyObjects: `DetectAndClassifyObjects` still carries a TODO from the transition skeleton.
- `final.todos` SurveillanceDroneSwarm::PA::NavigateAgainstStoredMaps: `NavigateAgainstStoredMaps` still carries a TODO from the transition skeleton.
- `final.todos` SurveillanceDroneSwarm::PA::ReportDetections: `ReportDetections` still carries a TODO from the transition skeleton.
- `final.todos` SurveillanceDroneSwarm::PA::RecordDecision: `RecordDecision` still carries a TODO from the transition skeleton.
- `final.todos` SurveillanceDroneSwarm::PA::PresentStatusPicture: `PresentStatusPicture` still carries a TODO from the transition skeleton.
- `final.todos` SurveillanceDroneSwarm::PA::TaskMission: `TaskMission` still carries a TODO from the transition skeleton.
- `final.todos` SurveillanceDroneSwarm::PA::CommandSupervision: `CommandSupervision` still carries a TODO from the transition skeleton.
- `final.todos` SurveillanceDroneSwarm::PA::RecallAndLand: `RecallAndLand` still carries a TODO from the transition skeleton.
- `final.todos` SurveillanceDroneSwarm::PA::AcknowledgeReport: `AcknowledgeReport` still carries a TODO from the transition skeleton.
- `final.todos` SurveillanceDroneSwarm::PA::HandOverSector: `HandOverSector` still carries a TODO from the transition skeleton.
- `final.todos` SurveillanceDroneSwarm::PA::RotateRecharge: `RotateRecharge` still carries a TODO from the transition skeleton.
- `final.todos` SurveillanceDroneSwarm::PA::RedistributeCoverage: `RedistributeCoverage` still carries a TODO from the transition skeleton.
- `final.todos` SurveillanceDroneSwarm::PA::DeconflictMembers: `DeconflictMembers` still carries a TODO from the transition skeleton.
- `final.todos` SurveillanceDroneSwarm::PA::RelayLink: `RelayLink` still carries a TODO from the transition skeleton.
- `final.todos` SurveillanceDroneSwarm::PA::CorrelateTracks: `CorrelateTracks` still carries a TODO from the transition skeleton.

## Steps

| Step | Status | Repairs | Gate |
|---|---|---|---|
| S00 | done | 0 | auto |
| S01 | skipped | 0 | — |
| S02 | skipped | 0 | — |
| S10 | done | 1 | — |
| S11 | done | 0 | — |
| S20 | done | 0 | — |
| S21 | done | 1 | — |
| S22 | done | 0 | — |
| S30 | done | 0 | — |
| S31 | done | 1 | — |
| S32 | done | 2 | — |
| S33 | done | 0 | — |
| S34 | done | 0 | — |
| S40 | done | 0 | — |
| S41 | done | 2 | — |
| S42 | done | 0 | — |
| S43 | done | 0 | — |
| S50 | done | 1 | — |
| S60 | done | 0 | — |
| S70 | running | 0 | auto |
