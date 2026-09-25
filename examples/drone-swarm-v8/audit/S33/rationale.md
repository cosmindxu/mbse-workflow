# S33

## What was decided

Only one alternative was provided, so the recommendation is forced; what follows is a judgement of Alternative 2 on its own terms, and where a ground-centred rival would beat it.

The split itself is the right one. Two logical components carry everything that matters — `fleet : SurveillanceDrone[12]` and `groundControlStation : GroundControlStation` — joined by five named connections (tasking, command, recall down; detections, tracks up) plus `peerLink` on `MeshLink`. Seven of eight `#Coordination` functions (`handOverSector`, `rotateRecharge`, `redistributeCoverage`, `deconflictFlight`, `relayThroughNeighbour`, `correlateTracks`, `handOverTrack`) are allocated to `fleet`; all five `#C2` functions and `admitMember` stay on `groundControlStation`. That is a coherent locus of authority: the fleet owns self-management, the ground owns intent and vetting. The rotating-coordinator rule in `SurveillanceDrone`'s doc — lowest `droneId` among reachable peers, next-lowest takes over mid-exchange — is a real, buildable mechanism rather than a wish, and it is what actually earns the mitigation of `PeerCoordinationSinglePointHazard`. This is the version of the decision I would build.

But the model as written does not yet support the claim. Three specific defects a reviewer should not read past:

1. **The package contradicts itself about whether decomposition has happened.** `coordinationAllocationDecision` and `fleetFact` both state that all thirteen functions stay on `mainComponent`, "the single placeholder box", and that the fleet usage is "instantiated at the next step" — while the bottom of the same package instantiates `fleet[12]`, `memberA`, `memberB`, `groundControlStation` and allocates all seventeen functions to them. `mainComponent` is never declared; `SurveillanceDroneSwarmLogical` is an orphan part def. Worse, `MemberMode` and `MemberOperationalState` at package level are rival, unattached copies of `SurveillanceDroneMode` and `SurveillanceDroneTaskState` inside `SurveillanceDrone`, each carrying its own copy of the four `PropertyPattern` blocks. Two mode machines for the same member, with duplicated safety properties, will drift the first time `RecallWins` is touched.

2. **The boundary is narrow but incomplete, and the gaps are exactly on the operator's path.** `presentStatusPicture` is allocated to `groundControlStation`, which has no inbound port for member position, coverage or degradation — only `detectionReportIn` and `trackIn`. `acknowledgeDetectionReport` is allocated to the ground, but there is no acknowledgement port back down to `SurveillanceDrone`, so the 45-minute `reportHoldDurationMinutes` claim ("holds reports through a gap") has no closing handshake in the model. `admitMember` is the one function that must cross the boundary fail-closed, and neither component carries a `MembershipRequest`/`MembershipDecision` port. `triageReports` produces `triagedAlertOut` and `decisionRecordOut`, but `groundControlStation` has no port to `opsCentreAnalyst` and no connection to either actor exists. 62 unconnected ports is the symptom; the cause is that the ground-facing half of the interface was left to be discovered at PA.

3. **The headline measure does not survive its own constraint.** `areaUnderWatchFraction` is declared 0.90 with the basis "24 km² of 25 km², i.e. ~0.90" — 24/25 is 0.96, and the asserted constraint `(fleetSizeValue * airborneShareValue * footprintValue) / areaOfInterestValue` computes 0.96, not 0.90. The estimate and the constraint that is supposed to derive it disagree, which is presumably why it reads vacuous. Separately, both numbers count `Transiting` members — a state the model itself declares — as watching: airborne share is not on-station share, so the true figure sits below both. The measure the brief says an architecture is judged on first is the one number here that is not sound.

On the safety rules: `RecallWins`, `ReturnsWhenIsolated`, `GeofenceBreachEndsWatch` and `QuarantinedStaysOut` are all `satisfy ... by fleet` — enforced inside the same `SurveillanceDroneMode` machine that also sits in the component doing `detectAndClassify` and `reportDetection`. There is no separate monitor whose doc says what it overrides. That directly contradicts this model's own rationale, which cites SafetyAuthority requiring recall and geofence authority to stay "independent of onboard software". A ground-centred rival does not automatically fix this either, but here the contradiction is stated in the model and left standing, and it costs both cohesion and realisability.

On cost: the 280 USD `onboardClassifierCostUsdPerDrone` is justified solely against `detectAndClassify` and `ClassifierRelease`. This alternative also loads `correlateTracks`, `handOverTrack`, `redistributeCoverage`, `deconflictFlight` and `relayThroughNeighbour` onto the same onboard processor. `droneCentricRationale` admits this needs "more onboard compute per drone", then the estimate does not charge for it. Against a 300 USD ceiling multiplied by twelve, that is the number a ground-centred rival would attack first.

What it genuinely buys: with the ground link down, seven of eight coordination functions keep running on the mesh, reports buffer 45 minutes against a 30-minute floor, and `coverageUnderMeshJammingFraction` 0.80 against 0.75 is the discriminator this decision exists for — that claim is directionally sound even if the number is asserted rather than derived. With the ground node itself gone, `SurveillanceDrone`'s doc is admirably honest: the fleet "continues flying its last tasking and self-coordinating indefinitely, but cannot admit new members and cannot receive a fresh recall order." Coverage is kept and `coverageDropAfterMemberLossFraction` 0.20 still holds, so the coverage-restoration measure survives — but there is one `groundControlStation` part, no failover, `useGroundRelayFallback` defaults false, and there is no timeout that converts link silence into a controlled landing. `ReturnsWhenIsolated` is a recovery property (a member *can* reach `Grounded`), not a guarantee that it *will* within a bound. And `triageReports`, the decision record, and `MixedClassifierVersionsHazard`'s only mitigation all die with that single node — the operator loses the alert stream outright, which is beyond what `GroundLinkC2SinglePathHazard` accepts.

I would take Alternative 2 — it is the only one offered, and its split of responsibilities is the one I would defend — on condition that the placeholder/`mainComponent` residue is deleted, the duplicate `MemberMode` machines collapsed to one, ports added for status, acknowledgement, admission and the analyst feed, the `areaUnderWatchFraction` derivation reconciled with its constraint and corrected for transit, and the classifier cost re-based to cover the coordination compute this split puts on the drone.

## Checks

- `check` clear — `npm run check -- /home/xcos/Work/mbse-workflow/runs/v8/build/5_LA.sysml --json`
- `trace-trace` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v8/build/5_LA.sysml --relation trace --json`
- `verify` clear — `npm run sysprose -- verify /home/xcos/Work/mbse-workflow/runs/v8/build/5_LA.sysml --json`

## Reported

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
- `trace.closure` SurveillanceDroneSwarm::OA::alphaWatchSector: OA → SA: `alphaWatchSector` is not realised.
- `trace.closure` SurveillanceDroneSwarm::OA::alphaDetectAndClassify: OA → SA: `alphaDetectAndClassify` is not realised.
- `trace.closure` SurveillanceDroneSwarm::OA::alphaReportDetection: OA → SA: `alphaReportDetection` is not realised.
- `trace.closure` SurveillanceDroneSwarm::OA::bravoWatchSector: OA → SA: `bravoWatchSector` is not realised.
- `trace.closure` SurveillanceDroneSwarm::OA::bravoDetectAndClassify: OA → SA: `bravoDetectAndClassify` is not realised.
- `trace.closure` SurveillanceDroneSwarm::OA::bravoReportDetection: OA → SA: `bravoReportDetection` is not realised.
- `trace.closure` SurveillanceDroneSwarm::OA::supervisorTaskSurveillanceMission: OA → SA: `supervisorTaskSurveillanceMission` is not realised.
- `trace.closure` SurveillanceDroneSwarm::OA::supervisorIssueSupervisoryCommand: OA → SA: `supervisorIssueSupervisoryCommand` is not realised.
- `trace.closure` SurveillanceDroneSwarm::OA::supervisorRecallToLand: OA → SA: `supervisorRecallToLand` is not realised.
- `trace.closure` SurveillanceDroneSwarm::OA::supervisorPresentStatusPicture: OA → SA: `supervisorPresentStatusPicture` is not realised.
- `trace.closure` SurveillanceDroneSwarm::OA::analystReportDetection: OA → SA: `analystReportDetection` is not realised.
- `trace.closure` SurveillanceDroneSwarm::OA::analystAcknowledgeDetectionReport: OA → SA: `analystAcknowledgeDetectionReport` is not realised.
