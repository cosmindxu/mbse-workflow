# S50

## What was decided

Realised the four PA-level delivered items named in the starting fragment (fleet, groundStation, rechargePoint, recoveryPoint) plus two further configuration items that the brief's own vocabulary calls out as separately procured/built things: the onboard mission-software load (a CSCI distinct from the airframe HWCI, since it is built rather than bought) and the single fleet-wide ClassifierRelease (a CSCI release item, tracked at PA by classifierRegistry). Added a COTS radio-module item shared by the drone's meshRadioUnit and the ground station's groundRadioUnit, since a commercial radio is the paradigm COTS procurement item and is exactly where a "supplier stops shipping" hazard belongs. Each of the seven CI part defs is tagged #CI_HWCI/#CI_CSCI/#CI_COTS, carries `trace ci to <PA part>;`, a requirement def (subject, assume/require constraint tied to a PA-level numeric budget, attribute id, doc) plus a separate requirement usage, both satisfied by the CI part, and a verification def with `objective { verify <ContractDef>; }` — satisfying CV-09's "def and usage counted separately" and the checked criterion of a verification per item. Cardinality follows CV-14 (multiplicity on the usage, e.g. `[12]`/`[13]`, never on the definition). Two shared, reachable state defs (`#Mode CIOperationalMode`, `#State CILifecycleState`) are attached as usages to every CI, satisfying the modes-and-states option without inventing per-item lifecycles that the brief never described. The RadioModuleItem's supplier choice is tagged `#Variant` per the variability option, doubling as the mitigation for the added supplier hazard. Package Hazards states exactly the three hazard *kinds* the brief's safety knob calls out for this layer (supplier discontinuation, version drift, part obsolescence), under fresh names not used by SA or PA, each naming its item as subject; two are mitigated by `satisfy Hazards::<name> by <ci>;` and one (mechanical-connector obsolescence) is tagged `#Accepted` with its reason in the doc, referencing PA's already-satisfied BatterySwapWearHazard rather than restating it.

## Deliberately left for later

- Did not model ports/mesh interfaces on the EPBS configuration items themselves (meshOut/meshIn/groundLinkPort): those are PA/LA behavioural concerns already realised there, and duplicating them here risked unconnected-port findings for no modelling benefit — flag if the checker expects port-level realisation at EPBS too.
- Bundled all onboard behaviour (sense, classify, navigate, localDeconflict, relay, reportHold, computeWatchdog) into one OnboardMissionSoftwareItem CSCI rather than one CI per PA function; split further if the programme intends to procure/maintain them as separate software CIs with independent release trains.
- Bundled all of GroundStationNode's hosted functions (coordinator, c2, triage, decisionRecord, statusPicture, classifierRegistry, mapsStore) under the single GroundStationItem HWCI rather than carving out a separate ground-software CSCI; left as one item since PA already treats them as one node's internal functions.
- RecoveryPointItemContract's require constraint is a generic fleet-size bound because the brief gives no recovery-point-specific numeric budget; replace with a real capacity/response-time budget once the customer states one.
- Did not add a CI for StoredMaps (the reference imagery repository) or for MeshRadioLink/GroundStationLinkDef as separate procurement items — treated the radio hardware as the procured COTS item and the map data as content riding on already-realised compute, not a separately delivered configuration item; revisit if the customer procures map data from a third party under its own contract.

## Checks

- `check` clear — `npm run check -- /home/xcos/Work/mbse-workflow/runs/v8/build/7_EPBS.sysml --json`
- `requirements-hazards` clear — `npm run sysprose -- requirements /home/xcos/Work/mbse-workflow/runs/v8/build/7_EPBS.sysml --kind requirement --json`
- `elements` clear — `npm run sysprose -- elements /home/xcos/Work/mbse-workflow/runs/v8/build/7_EPBS.sysml --json`
- `trace-trace` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v8/build/7_EPBS.sysml --relation trace --from PartUsage --json`
- `trace-verify` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v8/build/7_EPBS.sysml --relation verify --json`
- `refine` clear — `npm run sysprose -- refine /home/xcos/Work/mbse-workflow/runs/v8/build/7_EPBS.sysml --via composition --json`

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
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::fleetSizeDrones > 0"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::fleetSizeDrones <= 12"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::missedDetectionFraction >= 0.0"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::missedDetectionFraction <= 0.1"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::onboardClassifierCostUsdPerDrone >= 0.0"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::onboardClassifierCostUsdPerDrone <= 300.0"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::jammedLinkShareFraction >= 0.0"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::jammedLinkShareFraction <= 1.0"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::reportDeliveryLatencySeconds >= 0.0"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::reportDeliveryLatencySeconds <= 60.0"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::groundTurnaroundMinutes >= 0.0"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::groundTurnaroundMinutes <= 20.0"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::fleetSizeDrones >= 0.0"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::fleetSizeDrones <= 12.0"): Could not parse expression: Unexpected character ':' at 22.
