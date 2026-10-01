# S10

## What was decided

Re-checked against the layers above it: a person kept this fragment as written.

## Checks

- `check` clear — `npm run check -- /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/3_OA.sysml --json`
- `elements` clear — `npm run sysprose -- elements /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/3_OA.sysml --json`
- `trace-allocate` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/3_OA.sysml --relation allocate --from ActionUsage --to PartUsage --json`
- `connectivity` clear — `npm run sysprose -- connectivity /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/3_OA.sysml --json`
- `reach` clear — `npm run sysprose -- reach /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/3_OA.sysml --json`

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
- `validation/constraint-violation` unattendedWatchDurationTarget: Constraint could not be evaluated ("unattendedWatchDurationHours >= 12.0"): Could not evaluate: unattendedWatchDurationHours has no value anywhere and nothing specialises it.
- `validation/constraint-violation` fleetSizeBudget: Constraint could not be evaluated ("fleetSizeMembers <= 12"): Could not evaluate: fleetSizeMembers has no value anywhere and nothing specialises it.
- `validation/constraint-violation` memberEnduranceBudget: Constraint could not be evaluated ("memberEnduranceMinutes <= 40.0"): Could not evaluate: memberEnduranceMinutes has no value anywhere and nothing specialises it.
- `validation/constraint-violation` groundTurnaroundBudget: Constraint could not be evaluated ("groundTurnaroundMinutes >= 20.0"): Could not evaluate: groundTurnaroundMinutes has no value anywhere and nothing specialises it.
- `validation/constraint-violation` cruiseSpeedBudget: Constraint could not be evaluated ("cruiseSpeedMetresPerSecond <= 18.0"): Could not evaluate: cruiseSpeedMetresPerSecond has no value anywhere and nothing specialises it.
- `validation/constraint-violation` instantaneousFootprintBudget: Constraint could not be evaluated ("instantaneousFootprintSquareKilometres <= 3.0"): Could not evaluate: instantaneousFootprintSquareKilometres has no value anywhere and nothing specialises it.
- `validation/constraint-violation` areaOfInterestBudget: Constraint could not be evaluated ("areaOfInterestSquareKilometres <= 25.0"): Could not evaluate: areaOfInterestSquareKilometres has no value anywhere and nothing specialises it.
- `validation/constraint-violation` operatorSecondsPerAlertBudget: Constraint could not be evaluated ("operatorSecondsPerAlert >= 30.0"): Could not evaluate: operatorSecondsPerAlert has no value anywhere and nothing specialises it.
- `validation/constraint-violation` trackStaleAfterBudget: Constraint could not be evaluated ("trackStaleAfterSeconds <= 120.0"): Could not evaluate: trackStaleAfterSeconds has no value anywhere and nothing specialises it.
