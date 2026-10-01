# S21

## What was decided

Re-checked against the layers above it: a person kept this fragment as written.

## Checks

- `check` clear — `npm run check -- /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/4_SA.sysml --json`
- `elements` clear — `npm run sysprose -- elements /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/4_SA.sysml --json`
- `trace-trace` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/4_SA.sysml --relation trace --json`
- `trace-allocate` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/4_SA.sysml --relation allocate --from ActionUsage --to PartUsage --json`
- `connectivity` clear — `npm run sysprose -- connectivity /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/4_SA.sysml --json`
- `reach` clear — `npm run sysprose -- reach /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/4_SA.sysml --json`
- `requirements` clear — `npm run sysprose -- requirements /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/4_SA.sysml --json`
- `requirements-hazards` clear — `npm run sysprose -- requirements /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/4_SA.sysml --kind requirement --json`
- `consistency` clear — `npm run sysprose -- consistency /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/4_SA.sysml --json`

## Reported

- `validation/constraint-violation` areaUnderWatchTarget: Constraint could not be evaluated ("areaUnderWatchFraction >= 0.9"): Could not evaluate: areaUnderWatchFraction has no value anywhere and nothing specialises it.
- `validation/constraint-violation` coverageLossAfterMemberLossTarget: Constraint could not be evaluated ("coverageLossAfterMemberLossFraction <= 0.25"): Could not evaluate: coverageLossAfterMemberLossFraction has no value anywhere and nothing specialises it.
- `validation/constraint-violation` coverageUnderMeshJammingTarget: Constraint could not be evaluated ("coverageUnderMeshJammingFraction >= 0.75"): Could not evaluate: coverageUnderMeshJammingFraction has no value anywhere and nothing specialises it.
- `validation/constraint-violation` reportAgeAtOperationsCentreTarget: Constraint could not be evaluated ("reportAgeAtOperationsCentreSeconds <= 60.0"): Could not evaluate: reportAgeAtOperationsCentreSeconds has no value anywhere and nothing specialises it.
- `validation/constraint-violation` positionErrorWithoutSatelliteTarget: Constraint could not be evaluated ("positionErrorWithoutSatelliteMetres <= 50.0"): Could not evaluate: positionErrorWithoutSatelliteMetres has no value anywhere and nothing specialises it.
- `validation/constraint-violation` reportHoldWhileCutOffTarget: Constraint could not be evaluated ("reportHoldWhileCutOffMinutes >= 30.0"): Could not evaluate: reportHoldWhileCutOffMinutes has no value anywhere and nothing specialises it.
- `validation/constraint-violation` missedDetectionTarget: Constraint could not be evaluated ("missedDetectionFraction <= 0.10"): Could not evaluate: missedDetectionFraction has no value anywhere and nothing specialises it.
- `validation/constraint-violation` falseAlarmsPerHourTarget: Constraint could not be evaluated ("falseAlarmsPerHour <= 2.0"): Could not evaluate: falseAlarmsPerHour has no value anywhere and nothing specialises it.
- `validation/constraint-violation` alertsReachingOperatorTarget: Constraint could not be evaluated ("alertsReachingOperatorPerHour <= 20.0"): Could not evaluate: alertsReachingOperatorPerHour has no value anywhere and nothing specialises it.
- `validation/constraint-violation` acknowledgedReportsThatMatterTarget: Constraint could not be evaluated ("acknowledgedReportsThatMatterFraction >= 0.8"): Could not evaluate: acknowledgedReportsThatMatterFraction has no value anywhere and nothing specialises it.
- `validation/constraint-violation` onboardClassificationCostTarget: Constraint could not be evaluated ("onboardClassificationCostUsdPerMember <= 300.0"): Could not evaluate: onboardClassificationCostUsdPerMember has no value anywhere and nothing specialises it.
- `validation/constraint-violation` fleetSizeBudget: Constraint could not be evaluated ("fleetSizeMembers <= 12"): Could not evaluate: fleetSizeMembers has no value anywhere and nothing specialises it.
- `validation/constraint-violation` memberEnduranceBudget: Constraint could not be evaluated ("memberEnduranceMinutes <= 40.0"): Could not evaluate: memberEnduranceMinutes has no value anywhere and nothing specialises it.
- `validation/constraint-violation` groundTurnaroundBudget: Constraint could not be evaluated ("groundTurnaroundMinutes >= 20.0"): Could not evaluate: groundTurnaroundMinutes has no value anywhere and nothing specialises it.
- `validation/constraint-violation` cruiseSpeedBudget: Constraint could not be evaluated ("cruiseSpeedMetresPerSecond <= 18.0"): Could not evaluate: cruiseSpeedMetresPerSecond has no value anywhere and nothing specialises it.
- `validation/constraint-violation` instantaneousFootprintBudget: Constraint could not be evaluated ("instantaneousFootprintSquareKilometres <= 3.0"): Could not evaluate: instantaneousFootprintSquareKilometres has no value anywhere and nothing specialises it.
- `validation/constraint-violation` areaOfInterestBudget: Constraint could not be evaluated ("areaOfInterestSquareKilometres <= 25.0"): Could not evaluate: areaOfInterestSquareKilometres has no value anywhere and nothing specialises it.
- `validation/constraint-violation` operatorSecondsPerAlertBudget: Constraint could not be evaluated ("operatorSecondsPerAlert >= 30.0"): Could not evaluate: operatorSecondsPerAlert has no value anywhere and nothing specialises it.
- `validation/constraint-violation` trackStaleAfterBudget: Constraint could not be evaluated ("trackStaleAfterSeconds <= 120.0"): Could not evaluate: trackStaleAfterSeconds has no value anywhere and nothing specialises it.
- `validation/constraint-violation` satellitePositioningOutageBudget: Constraint could not be evaluated ("satellitePositioningOutageMinutes == 10.0"): Could not evaluate: satellitePositioningOutageMinutes has no value anywhere and nothing specialises it.
- `validation/constraint-violation` meshLinksJammedBudget: Constraint could not be evaluated ("meshLinksJammedFraction == 0.5"): Could not evaluate: meshLinksJammedFraction has no value anywhere and nothing specialises it.
- `sa.chains` : no functional chain for ContinuousSectorWatch, MovingObjectDetectionAndClassification, ReportDeliveryAndReconciliation, SwarmSelfCoordination, OperatorSupervisionOfTheSwarm, AlertTriage, DecisionRecordKeeping, GracefulDegradationUnderLoss, AirspaceComplianceAndSafeRecovery, ClassifierVersionConsistency. A chain is `#Chain occurrence def <Capability>Chain { doc /* the functions, in order */ }` with `succession` lines between its functions; it is what a latency budget and an integration test attach to.
- `rules.hold` SurveillanceDroneSwarm::SA::SwarmMember::SwarmMemberStates: the rule `ReturnsWhenIsolated` could not be decided on `SA::SwarmMember::SwarmMemberStates` (inconclusive): inconclusive: this machine names triggers this walk offers at every configuration, so "reachable from every configuration" would be a claim about an environment this walk has no carrier for — the environment offered every trigger this machine names at every configuration, so a witness that consumes 
- `connectivity.layerPorts` SurveillanceDroneSwarm::SA::SwarmMember::meshOut: port `meshOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::SA::SwarmMember::meshIn: port `meshIn` is not connected to anything.
