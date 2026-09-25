# SurveillanceDroneSwarm — final audit

Model: `/home/xcos/Work/mbse-workflow/runs/v8/SurveillanceDroneSwarm.sysml` (3197 elements)
Sysprose: 2486d72
Run: autonomous mode, 32 model call(s), 21.45 USD, 10892 s of model time, over 6 legs

## Checked by the shipped CLI, not by this workflow

`npm run check -- /home/xcos/Work/mbse-workflow/runs/v8/SurveillanceDroneSwarm.sysml --json` → exit 0 (clean), 85 diagnostic(s)
`npm run sysprose -- requirements /home/xcos/Work/mbse-workflow/runs/v8/SurveillanceDroneSwarm.sysml --json` → 35/38 satisfied (92 %); all 3 unsatisfied are hazards accepted with their reason

## Realization chain

| From | To | Realised | Of |
|---|---|---|---|
| OA | SA | 26 | 38 |
| SA | LA | 17 | 17 |
| LA | PA | 17 | 17 |
| PA | EPBS | 4 | 6 |

## Every check this step ran

| Check | Verdict | Command |
|---|---|---|
| `check` | clear | `npm run check -- /home/xcos/Work/mbse-workflow/runs/v8/build/7_EPBS.sysml --json` |
| `stats` | clear | `npm run sysprose -- stats /home/xcos/Work/mbse-workflow/runs/v8/build/7_EPBS.sysml --json` |
| `trace-trace` | clear | `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v8/build/7_EPBS.sysml --relation trace --json` |
| `trace-allocate` | clear | `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v8/build/7_EPBS.sysml --relation allocate --from ActionUsage --to PartUsage --json` |
| `requirements` | clear | `npm run sysprose -- requirements /home/xcos/Work/mbse-workflow/runs/v8/build/7_EPBS.sysml --json` |
| `reach` | clear | `npm run sysprose -- reach /home/xcos/Work/mbse-workflow/runs/v8/build/7_EPBS.sysml --json` |
| `connectivity` | clear | `npm run sysprose -- connectivity /home/xcos/Work/mbse-workflow/runs/v8/build/7_EPBS.sysml --json` |
| `orphans` | clear | `npm run sysprose -- orphans /home/xcos/Work/mbse-workflow/runs/v8/build/7_EPBS.sysml --json` |
| `elements` | clear | `npm run sysprose -- elements /home/xcos/Work/mbse-workflow/runs/v8/build/7_EPBS.sysml --json` |
| `evidence-status` | clear | `npm run sysprose -- evidence-status /home/xcos/Work/mbse-workflow/runs/v8/build/7_EPBS.sysml --json` |

## Can a person review this?

| Layer | Elements | Documented | |
|---|---|---|---|
| Common | 59 | 59 | 100 % |
| OA | 99 | 99 | 100 % |
| SA | 59 | 59 | 100 % |
| LA | 68 | 66 | 97 % |
| PA | 88 | 84 | 95 % |
| EPBS | 38 | 38 | 100 % |

6 element(s) carry no doc and no realization link — a reader cannot ask why they exist:
- `SurveillanceDroneSwarm::LA::«ConstraintUsage»`
- `SurveillanceDroneSwarm::LA::«ConstraintUsage»`
- `SurveillanceDroneSwarm::PA::«ConstraintUsage»`
- `SurveillanceDroneSwarm::PA::«ConstraintUsage»`
- `SurveillanceDroneSwarm::PA::«ConstraintUsage»`
- `SurveillanceDroneSwarm::PA::«ConstraintUsage»`

| Step | Lines a reviewer read |
|---|---|
| S00 | 846 |
| S10 | 61 |
| S20 | 42 |
| S21 | 879 |
| S30 | 212 |
| S31 | 292 |
| S32 | 722 |
| S33 | 408 |
| S40 | 187 |
| S41 | 519 |
| S42 | 424 |
| S50 | 288 |

## Behaviour

Each state machine against the properties it states, or — for a machine written to come back to the state it opens at — that every reachable configuration can get back there. A machine with no transition back is a lifecycle and gets no default.

| Machine | Property | Verdict | Detail |
|---|---|---|---|
| `OA::WatchAssetOperatingMode` | recovery to Watching | holds | recoverable: `state Watching` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxCompleti |
| `OA::WatchAssetAvailabilityState` | recovery to Available | holds | recoverable: `state Available` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxComplet |
| `SA::SwarmOperatingMode` | carried | holds | pass — holds on every reachable configuration: `state Watching` never holds, between each `state Recalled` and the next `state Grounded`. ex |
| `SA::SwarmAvailabilityState` | recovery to Nominal | holds | recoverable: `state Nominal` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxCompletio |
| `LA::MemberMode` | carried | holds | pass — holds on every reachable configuration: `state Watching` never holds, between each `state Recalled` and the next `state Grounded`. ex |
| `LA::MemberOperationalState` | recovery to Available | holds | recoverable: `state Available` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxComplet |
| `LA::FleetConfiguration` | recovery to MeshNominal | holds | recoverable: `state MeshNominal` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxCompl |
| `LA::SurveillanceDrone::SurveillanceDroneMode` | carried | holds | pass — holds on every reachable configuration: `state Watching` never holds, between each `state Recalled` and the next `state Grounded`. ex |
| `LA::SurveillanceDrone::SurveillanceDroneTaskState` | recovery to Idle | holds | recoverable: `state Idle` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxCompletion 6 |
| `LA::GroundControlStation::GroundControlStationMode` | recovery to Active | holds | recoverable: `state Active` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxCompletion |
| `LA::GroundControlStation::GroundControlStationState` | recovery to Idle | holds | recoverable: `state Idle` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxCompletion 6 |
| `PA::SurveillanceDrone::MemberMode` | carried | holds | pass — holds on every reachable configuration: `state Nominal` never holds, between each `state Quarantined` and the next `state Readmitted` |
| `PA::SurveillanceDrone::MemberFlightState` | carried | holds | pass — holds on every reachable configuration: `state Watching` never holds, between each `state Recalled` and the next `state Landed`. exha |
| `PA::FleetConfiguration` | recovery to Nominal | holds | recoverable: `state Nominal` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxCompletio |
| `EPBS::CIOperationalMode` | recovery to InService | holds | recoverable: `state InService` is reachable from every reachable configuration, exhaustive under {maxConfigs 10000, maxDepth 200, maxComplet |
| `EPBS::CILifecycleState` | none | nothing to check |  |

Fault tree over the contracts: 38 contract(s), 0 with cut sets, 0 single point(s) of failure.

## What an edit costs

If a person edits one layer's fragment and resumes: the step that wrote it is re-checked (never re-authored), and every step built on it runs again. The cost is what those steps spent in this run — a guide, since a resume may repair less or more.

| Layer edited | Fragment lines | Re-checked | Runs again | Calls those steps made | USD |
|---|---|---|---|---|---|
| Kinds | 13 | S00 | S10…S60 (16) | 31 | 20.47 |
| Common | 940 | S00 | S10…S60 (16) | 31 | 20.47 |
| OA | 665 | S10 | S20…S60 (14) | 24 | 16.33 |
| SA | 593 | S21 | S30…S60 (11) | 18 | 13.03 |
| LA | 747 | S33 | S40…S60 (6) | 8 | 5.99 |
| PA | 564 | S42 | S50…S60 (2) | 1 | 0.64 |
| EPBS | 289 | S50 | — | 0 | 0.00 |

## Measures

The worst case over the `#Estimate` each layer's chosen architecture states. These are the architecture's own claims with their basis in the doc, checked for consistency by the solver — not measurements.

| Measure | Target | LA | PA |
|---|---|---|---|
| `areaUnderWatchFraction` | ≥ 0.9 | vacuous | 0.96 (derived) ✓ |
| `watchEnduranceHoursWithoutPeople` | ≥ 12 hours | 10 hours ✗ | 18 hours ✓ |
| `reportDeliveryLatencySeconds` | ≤ 60 seconds (placeholder) | 45 seconds ✓ | 45 seconds ✓ |
| `positionErrorAfterGnssLossMetres` | ≤ 50 metres (placeholder) | 40 metres ✓ | 35 metres ✓ |
| `coverageUnderMeshJammingFraction` | ≥ 0.75 (placeholder) | 0.8 ✓ | 0.816 (derived) ✓ |
| `reportHoldDurationMinutes` | ≥ 30 minutes (placeholder) | 45 minutes ✓ | 45 minutes ✓ |
| `missedDetectionFraction` | ≤ 0.1 (placeholder) | 0.08 ✓ | 0.08 ✓ |
| `falseAlarmsPerHour` | ≤ 2 alerts per hour (placeholder) | 1.5 alerts per hour ✓ | 1.5 alerts per hour ✓ |
| `alertsReachingOperatorPerHour` | ≤ 20 alerts per hour (placeholder) | 18 alerts per hour ✓ | 18 alerts per hour ✓ |
| `acknowledgedReportsThatMatterFraction` | ≥ 0.8 (placeholder) | 0.82 ✓ | 0.85 ✓ |
| `coverageDropAfterMemberLossFraction` | ≤ 0.25 | 0.2 ✓ | 0.125 (derived) ✓ |
| `onboardClassifierCostUsdPerDrone` | ≤ 300 USD (placeholder) | 280 USD ✓ | 220 USD ✓ |

### Every architecture compared meets these

They added the same to every alternative's score, so the choice was made by the rest. A target nobody misses is a question about the target: is it the customer's?

- `reportDeliveryLatencySeconds` ≤ 60 seconds (placeholder): met by 2/2 alternatives
- `positionErrorAfterGnssLossMetres` ≤ 50 metres (placeholder): met by 2/2 alternatives
- `coverageUnderMeshJammingFraction` ≥ 0.75 (placeholder): met by 2/2 alternatives
- `reportHoldDurationMinutes` ≥ 30 minutes (placeholder): met by 2/2 alternatives
- `missedDetectionFraction` ≤ 0.1 (placeholder): met by 2/2 alternatives
- `falseAlarmsPerHour` ≤ 2 alerts per hour (placeholder): met by 2/2 alternatives
- `alertsReachingOperatorPerHour` ≤ 20 alerts per hour (placeholder): met by 2/2 alternatives
- `acknowledgedReportsThatMatterFraction` ≥ 0.8 (placeholder): met by 2/2 alternatives
- `coverageDropAfterMemberLossFraction` ≤ 0.25: met by 2/2 alternatives
- `onboardClassifierCostUsdPerDrone` ≤ 300 USD (placeholder): met by 2/2 alternatives

9 of these 12 targets are placeholders in the brief, awaiting the customer's numbers: a ✓ against one says the design meets the placeholder, nothing more.

## The fleet

| Layer | Member definition | Fleet | Representatives | Links between members | Coordination and C2 on board |
|---|---|---|---|---|---|
| SA | yes | — | — | — | 0/13 |
| LA | yes | [12] | `memberA`, `memberB` | `peerLink` : MeshLink | 7/13 |
| PA | yes | [12] | `memberA`, `memberB` | `peerLink` : MeshRadioLink | 2/13 |
| EPBS | — | `fleetCi` [12], `onboardSoftwareCi` [12] | — | — | — |

Connectivity counts usages, not instances: a link between two representatives is one wired occurrence standing for every pair of members that exchange (CV-16).

### Where command and control sits at LA

One row per function definition. A definition is on board when every usage sits on a member or the fleet, on the ground when any usage sits elsewhere, and neither when only actors perform it.

| Function | Tag | Usages and where they are allocated | Where it sits |
|---|---|---|---|
| `HandOverSector` | Coordination | `handOverSector` → `fleet` | on board |
| `RotateRecharge` | Coordination | `rotateRecharge` → `fleet` | on board |
| `RedistributeCoverage` | Coordination | `redistributeCoverage` → `fleet` | on board |
| `DeconflictFlight` | Coordination | `deconflictFlight` → `fleet` | on board |
| `RelayThroughNeighbour` | Coordination | `relayThroughNeighbour` → `fleet` | on board |
| `CorrelateTracks` | Coordination | `correlateTracks` → `fleet` | on board |
| `HandOverTrack` | Coordination | `handOverTrack` → `fleet` | on board |
| `AdmitMember` | Coordination | `admitMember` → `groundControlStation` | ground |
| `TaskSurveillanceMission` | C2 | `taskSurveillanceMission` → `groundControlStation` | ground |
| `IssueSupervisoryCommand` | C2 | `issueSupervisoryCommand` → `groundControlStation` | ground |
| `RecallToLand` | C2 | `recallToLand` → `groundControlStation` | ground |
| `PresentStatusPicture` | C2 | `presentStatusPicture` → `groundControlStation` | ground |
| `AcknowledgeDetectionReport` | C2 | `acknowledgeDetectionReport` → `groundControlStation` | ground |

### Where command and control sits at PA

One row per function definition. A definition is on board when every usage sits on a member or the fleet, on the ground when any usage sits elsewhere, and neither when only actors perform it.

| Function | Tag | Usages and where they are allocated | Where it sits |
|---|---|---|---|
| `HandOverSector` | Coordination | `handOverSector` → `GroundStationNode::coordinator` | ground |
| `RotateRecharge` | Coordination | `rotateRecharge` → `GroundStationNode::coordinator` | ground |
| `RedistributeCoverage` | Coordination | `redistributeCoverage` → `GroundStationNode::coordinator` | ground |
| `DeconflictFlight` | Coordination | `deconflictFlight` → `fleet` | on board |
| `RelayThroughNeighbour` | Coordination | `relayThroughNeighbour` → `fleet` | on board |
| `CorrelateTracks` | Coordination | `correlateTracks` → `GroundStationNode::coordinator` | ground |
| `HandOverTrack` | Coordination | `handOverTrack` → `GroundStationNode::coordinator` | ground |
| `AdmitMember` | Coordination | `admitMember` → `GroundStationNode::coordinator` | ground |
| `TaskSurveillanceMission` | C2 | `taskSurveillanceMission` → `GroundStationNode::c2` | ground |
| `IssueSupervisoryCommand` | C2 | `issueSupervisoryCommand` → `GroundStationNode::c2` | ground |
| `RecallToLand` | C2 | `recallToLand` → `GroundStationNode::c2` | ground |
| `PresentStatusPicture` | C2 | `presentStatusPicture` → `GroundStationNode::statusPicture` | ground |
| `AcknowledgeDetectionReport` | C2 | `acknowledgeDetectionReport` → `GroundStationNode::c2` | ground |

## Hazards accepted, not mitigated

Each carries its reason in its doc; a reviewer should read them.

- `GroundLinkC2SinglePathHazard`
- `GroundAdmissionBottleneckHazard`
- `RechargePointPartObsolescenceHazard`

## Left as TODO

- `SurveillanceDroneSwarm::PA::SurveillanceDroneSwarmPhysical`
- `SurveillanceDroneSwarm::PA::SwarmSupervisor`
- `SurveillanceDroneSwarm::PA::OperationsCentreAnalyst`
- `SurveillanceDroneSwarm::PA::AirspaceAuthority`
- `SurveillanceDroneSwarm::PA::OperatingEnvironment`
- `SurveillanceDroneSwarm::PA::HandOverSector`
- `SurveillanceDroneSwarm::PA::RotateRecharge`
- `SurveillanceDroneSwarm::PA::RedistributeCoverage`
- `SurveillanceDroneSwarm::PA::DeconflictFlight`
- `SurveillanceDroneSwarm::PA::RelayThroughNeighbour`
- `SurveillanceDroneSwarm::PA::CorrelateTracks`
- `SurveillanceDroneSwarm::PA::HandOverTrack`
- `SurveillanceDroneSwarm::PA::AdmitMember`
- `SurveillanceDroneSwarm::PA::TaskSurveillanceMission`
- `SurveillanceDroneSwarm::PA::IssueSupervisoryCommand`
- `SurveillanceDroneSwarm::PA::RecallToLand`
- `SurveillanceDroneSwarm::PA::PresentStatusPicture`
- `SurveillanceDroneSwarm::PA::AcknowledgeDetectionReport`
- `SurveillanceDroneSwarm::PA::WatchSector`
- `SurveillanceDroneSwarm::PA::DetectAndClassify`
- `SurveillanceDroneSwarm::PA::ReportDetection`
- `SurveillanceDroneSwarm::PA::TriageReportsDefinition`

## Reported, not blocking

- `validation/constraint-violation` areaUnderWatchMeetsTarget: Constraint could not be evaluated ("areaUnderWatchFraction >= 0.9"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` watchEnduranceMeetsTarget: Constraint could not be evaluated ("watchEnduranceHoursWithoutPeople >= 12"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` reportLatencyMeetsTarget: Constraint could not be evaluated ("reportDeliveryLatencySeconds <= 60"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` positionErrorMeetsTarget: Constraint could not be evaluated ("positionErrorAfterGnssLossMetres <= 50"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` jammedCoverageMeetsTarget: Constraint could not be evaluated ("coverageUnderMeshJammingFraction >= 0.75"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` reportHoldMeetsTarget: Constraint could not be evaluated ("reportHoldDurationMinutes >= 30"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` missedDetectionMeetsTarget: Constraint could not be evaluated ("missedDetectionFraction <= 0.10"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` falseAlarmsMeetTarget: Constraint could not be evaluated ("falseAlarmsPerHour <= 2"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` alertRateMeetsTarget: Constraint could not be evaluated ("alertsReachingOperatorPerHour <= 20"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` acknowledgedPrecisionMeetsTarget: Constraint could not be evaluated ("acknowledgedReportsThatMatterFraction >= 0.8"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` coverageDropMeetsTarget: Constraint could not be evaluated ("coverageDropAfterMemberLossFraction <= 0.25"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` classifierCostMeetsTarget: Constraint could not be evaluated ("onboardClassifierCostUsdPerDrone <= 300"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` fleetSizeWithinBudget: Constraint could not be evaluated ("fleetSizeDrones <= 12"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` flightEnduranceWithinBudget: Constraint could not be evaluated ("memberFlightEnduranceMinutes >= 40"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` turnaroundWithinBudget: Constraint could not be evaluated ("groundTurnaroundMinutes <= 20"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` cruiseSpeedWithinBudget: Constraint could not be evaluated ("cruiseSpeedMetresPerSecond >= 18"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` sensorFootprintWithinBudget: Constraint could not be evaluated ("sensorFootprintSquareKilometres >= 3.0"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` areaWithinBudget: Constraint could not be evaluated ("areaOfInterestSquareKilometres <= 25"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` operatorCapacityWithinBudget: Constraint could not be evaluated ("operatorAlertCapacityPerHour <= 20"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` operatorTimeWithinBudget: Constraint could not be evaluated ("operatorSecondsPerAlert >= 30"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` staleThresholdWithinBudget: Constraint could not be evaluated ("trackStaleThresholdSeconds <= 120"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` gnssOutageWithinBudget: Constraint could not be evaluated ("gnssOutageToleratedMinutes >= 10"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` jammedShareWithinBudget: Constraint could not be evaluated ("jammedLinkShareFraction >= 0.5"): Could not evaluate: a referenced value is unknown.
- `ref/unresolved-allocation-end` : Unresolved allocation target 'watchAsset'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'watchAsset'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'watchAsset'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'watchAsset'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'watchAsset'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'watchAsset'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'watchAsset'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'watchAsset'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'watchAsset'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'watchAsset'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'watchAsset'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'watchAsset'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'watchAsset'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'system'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'system'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'system'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'system'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'system'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'system'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'system'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'system'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'system'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'system'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'system'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'system'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'system'
- `validation/requirement-subject` GroundLinkC2SinglePathHazard: Requirement "SurveillanceDroneSwarm::LA::Hazards::GroundLinkC2SinglePathHazard" has no subject.
- `validation/requirement-subject` GroundAdmissionBottleneckHazard: Requirement "SurveillanceDroneSwarm::LA::Hazards::GroundAdmissionBottleneckHazard" has no subject.
- `validation/constraint-violation` : Constraint could not be evaluated ("airborneShareValue == flightMinutesValue / (flightMinutesValue + turnaroundMinutesValue)"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("areaUnderWatchFraction == (fleetSizeValue * airborneShareValue * footprintValue) / areaOfInterestValue"): Could not evaluate: a referenced value is unknown.
- `validation/port-direction` groundLinkPort: Port "SurveillanceDroneSwarm::PA::SurveillanceDrone::groundLinkPort" has no direction (expected in/out/inout).
- `validation/port-direction` groundLinkPort: Port "SurveillanceDroneSwarm::PA::GroundStationNode::groundLinkPort" has no direction (expected in/out/inout).
- `ref/unresolved-allocation-end` : Unresolved allocation source 'SurveillanceDroneSwarm::LA::DetectionClassificationAndReporting'
- `ref/unresolved-allocation-end` : Unresolved allocation source 'SurveillanceDroneSwarm::LA::ReportTriageAndDecisionRecord'
- `ref/unresolved-allocation-end` : Unresolved allocation source 'SurveillanceDroneSwarm::LA::DisconnectedOperationAndReconciliation'
- `ref/unresolved-allocation-end` : Unresolved allocation source 'SurveillanceDroneSwarm::LA::GracefulDegradation'
- `ref/unresolved-allocation-end` : Unresolved allocation source 'SurveillanceDroneSwarm::LA::AirspaceComplianceAndSafeRecovery'

## Steps

| Step | Status | Repairs | Gate |
|---|---|---|---|
| S00 | done | 0 | auto |
| S01 | skipped | 0 | — |
| S02 | skipped | 0 | — |
| S10 | done | 0 | auto |
| S11 | done | 0 | — |
| S20 | done | 0 | — |
| S21 | done | 1 | auto |
| S22 | done | 0 | — |
| S30 | done | 0 | — |
| S31 | done | 1 | — |
| S32 | done | 3 | — |
| S33 | done | 0 | — |
| S34 | done | 0 | — |
| S40 | done | 0 | — |
| S41 | done | 3 | — |
| S42 | done | 0 | — |
| S43 | done | 0 | — |
| S50 | done | 0 | — |
| S60 | done | 0 | — |
| S70 | running | 0 | — |
