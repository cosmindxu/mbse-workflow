# S33

## What was decided

Re-checked after a person edited the fragment.

## Checks

- `check` clear — `npm run check -- /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/5_LA.sysml --json`
- `trace-trace` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/5_LA.sysml --relation trace --json`
- `verify` clear — `npm run sysprose -- verify /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/5_LA.sysml --json`

## Reported

- `validation/constraint-violation` areaUnderWatchTarget: Constraint could not be evaluated ("areaUnderWatchFraction >= 0.9"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` coverageLossAfterMemberLossTarget: Constraint could not be evaluated ("coverageLossAfterMemberLossFraction <= 0.25"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` coverageUnderMeshJammingTarget: Constraint could not be evaluated ("coverageUnderMeshJammingFraction >= 0.75"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` reportAgeAtOperationsCentreTarget: Constraint could not be evaluated ("reportAgeAtOperationsCentreSeconds <= 60.0"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` positionErrorWithoutSatelliteTarget: Constraint could not be evaluated ("positionErrorWithoutSatelliteMetres <= 50.0"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` reportHoldWhileCutOffTarget: Constraint could not be evaluated ("reportHoldWhileCutOffMinutes >= 30.0"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` missedDetectionTarget: Constraint could not be evaluated ("missedDetectionFraction <= 0.10"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` falseAlarmsPerHourTarget: Constraint could not be evaluated ("falseAlarmsPerHour <= 2.0"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` alertsReachingOperatorTarget: Constraint could not be evaluated ("alertsReachingOperatorPerHour <= 20.0"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` acknowledgedReportsThatMatterTarget: Constraint could not be evaluated ("acknowledgedReportsThatMatterFraction >= 0.8"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` onboardClassificationCostTarget: Constraint could not be evaluated ("onboardClassificationCostUsdPerMember <= 300.0"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` unattendedWatchDurationTarget: Constraint could not be evaluated ("unattendedWatchDurationHours >= 12.0"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` fleetSizeBudget: Constraint could not be evaluated ("fleetSizeMembers <= 12"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` memberEnduranceBudget: Constraint could not be evaluated ("memberEnduranceMinutes <= 40.0"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` groundTurnaroundBudget: Constraint could not be evaluated ("groundTurnaroundMinutes >= 20.0"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` cruiseSpeedBudget: Constraint could not be evaluated ("cruiseSpeedMetresPerSecond <= 18.0"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` instantaneousFootprintBudget: Constraint could not be evaluated ("instantaneousFootprintSquareKilometres <= 3.0"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` areaOfInterestBudget: Constraint could not be evaluated ("areaOfInterestSquareKilometres <= 25.0"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` operatorSecondsPerAlertBudget: Constraint could not be evaluated ("operatorSecondsPerAlert >= 30.0"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` trackStaleAfterBudget: Constraint could not be evaluated ("trackStaleAfterSeconds <= 120.0"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` satellitePositioningOutageBudget: Constraint could not be evaluated ("satellitePositioningOutageMinutes >= 10.0"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` meshLinksJammedBudget: Constraint could not be evaluated ("meshLinksJammedFraction >= 0.5"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("areaUnderWatchFraction == fleetMemberCount * ((memberFlightMinutes - sectorTransitMinutes) / (memberFlightMinutes + memberTurnaroundMinutes)) * memberCoverageFraction"): Could not evaluate: a referenced value is unknown.
- `trace.closure` SurveillanceDroneSwarm::SA::mergeTracks: SA → LA: `mergeTracks` is not realised.
- `trace.closure` SurveillanceDroneSwarm::SA::provideCameraTracks: SA → LA: `provideCameraTracks` is not realised.
- `trace.closure` SurveillanceDroneSwarm::SA::swapBatteryAct: SA → LA: `swapBatteryAct` is not realised.
- `trace.closure` SurveillanceDroneSwarm::SA::recoverDroneAct: SA → LA: `recoverDroneAct` is not realised.
- `trace.closure` SurveillanceDroneSwarm::SA::grantClearanceAct: SA → LA: `grantClearanceAct` is not realised.
