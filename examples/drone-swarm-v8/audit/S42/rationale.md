# S42

## What was decided

Only one alternative was supplied — the prompt contains a single PA package ("Alternative 1", ground-centred) — so this is an absolute assessment, not a comparison; the recommendation is forced by that absence. The split is coherent as a ground-centred design: `localDeconflict` and `relay` are correctly left on board as the two latency-intolerant functions, the airframe is uniform and cheap to procure, and `GroundStationNode` is a clean procurement item. Its weakness is concentration. `groundStation.coordinator` bundles six unrelated concerns (sector handover, recharge rotation, coverage redistribution, track correlation, track handover, admission — fleet resource management, track fusion and security in one part), and `GroundStationNode` holds seven functions with no redundancy. The decisive finding: `coverageDropAfterMemberLossFraction = 0.125` is derived "before `redistributeCoverage` re-spreads the rest", and `redistributeCoverage` lives on `groundStation.coordinator` — the coverage-restoration measure is met only by the component whose loss the model names as `GroundCoordinatorSinglePointHazard`, which it then "satisfies by fleet" even though the allocation block puts nothing but `deconflictFlight` and `relayThroughNeighbour` on the fleet. That hazard is accepted, not mitigated, whatever the count says. The flight rules are satisfied `by fleet` and carried on `SurveillanceDrone`'s own state machines — the same article that holds `sense` and `classify` — with no independent monitor (`computeWatchdog` restarts crashed processes; its doc never says it overrides anything). Two estimates have bases the model contradicts: the $220 onboard cost is justified by keeping classification on the ground while `ClassifyFunction`, `detectAndClassify` and the `MisclassificationHazard` satisfy are all on board; and 0.96 coverage needs eight 3 km² footprints to be disjoint across 25 km² with no transit time charged against the 40-minute endurance.

## Checks

- `check` clear — `npm run check -- /home/xcos/Work/mbse-workflow/runs/v8/build/6_PA.sysml --json`
- `trace-trace` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v8/build/6_PA.sysml --relation trace --json`
- `verify` clear — `npm run sysprose -- verify /home/xcos/Work/mbse-workflow/runs/v8/build/6_PA.sysml --json`

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
- `validation/port-direction` groundLinkPort: Port "SurveillanceDroneSwarm::PA::SurveillanceDrone::groundLinkPort" has no direction (expected in/out/inout).
- `validation/port-direction` groundLinkPort: Port "SurveillanceDroneSwarm::PA::GroundStationNode::groundLinkPort" has no direction (expected in/out/inout).
- `ref/unresolved-allocation-end` : Unresolved allocation source 'SurveillanceDroneSwarm::LA::DetectionClassificationAndReporting'
- `ref/unresolved-allocation-end` : Unresolved allocation source 'SurveillanceDroneSwarm::LA::ReportTriageAndDecisionRecord'
- `ref/unresolved-allocation-end` : Unresolved allocation source 'SurveillanceDroneSwarm::LA::DisconnectedOperationAndReconciliation'
- `ref/unresolved-allocation-end` : Unresolved allocation source 'SurveillanceDroneSwarm::LA::GracefulDegradation'
- `ref/unresolved-allocation-end` : Unresolved allocation source 'SurveillanceDroneSwarm::LA::AirspaceComplianceAndSafeRecovery'
- `ref/unresolved-allocation-end` : Unresolved allocation source 'SurveillanceDroneSwarm::LA::SupervisedCommandAndControl'
- `ref/unresolved-allocation-end` : Unresolved allocation source 'SurveillanceDroneSwarm::LA::ContinuousAreaWatch'
- `validation/constraint-violation` : Constraint could not be evaluated ("airborneShareFraction == memberFlightEnduranceMinutes / (memberFlightEnduranceMinutes + groundTurnaroundMinutes)"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("numAirborneDrones == fleetSizeDrones * airborneShareFraction"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("areaUnderWatchFraction == numAirborneDrones * sensorFootprintSquareKilometres / areaOfInterestSquareKilometres"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("coverageUnderMeshJammingFraction == areaUnderWatchFraction * (1.0 - jammedLinkShareFraction * meshCoordinationDependencyFraction)"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("coverageDropAfterMemberLossFraction == 1.0 / numAirborneDrones"): Could not evaluate: a referenced value is unknown.
- `ref/unresolved-requirement` : Unresolved requirement 'SurveillanceDroneSwarm::SA::Rules::RecallWins'
- `ref/unresolved-requirement` : Unresolved requirement 'SurveillanceDroneSwarm::SA::Rules::ReturnsWhenIsolated'
- `ref/unresolved-requirement` : Unresolved requirement 'SurveillanceDroneSwarm::SA::Rules::GeofenceBreachEndsWatch'
- `ref/unresolved-requirement` : Unresolved requirement 'SurveillanceDroneSwarm::SA::Rules::QuarantinedStaysOut'
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
