# S33

## What was decided

Re-checked after a person edited the fragment.

## Checks

- `check` clear — `npm run check -- /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/5_LA.sysml --json`
- `trace-trace` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/5_LA.sysml --relation trace --json`
- `verify` clear — `npm run sysprose -- verify /home/xcos/Work/mbse-workflow-public/examples/drone-swarm-v9/build/5_LA.sysml --json`

## Reported

- `validation/constraint-violation` areaUnderWatchTarget: Constraint could not be evaluated ("areaUnderWatchFraction >= 0.9"): Could not evaluate: areaUnderWatchFraction has no value here; evaluated per specialisation: LA::areaUnderWatchFraction.
- `validation/constraint-violation` coverageLossAfterMemberLossTarget: Constraint could not be evaluated ("coverageLossAfterMemberLossFraction <= 0.25"): Could not evaluate: coverageLossAfterMemberLossFraction has no value here; evaluated per specialisation: LA::coverageLossAfterMemberLossFraction.
- `validation/constraint-violation` coverageUnderMeshJammingTarget: Constraint could not be evaluated ("coverageUnderMeshJammingFraction >= 0.75"): Could not evaluate: coverageUnderMeshJammingFraction has no value here; evaluated per specialisation: LA::coverageUnderMeshJammingFraction.
- `validation/constraint-violation` reportAgeAtOperationsCentreTarget: Constraint could not be evaluated ("reportAgeAtOperationsCentreSeconds <= 60.0"): Could not evaluate: reportAgeAtOperationsCentreSeconds has no value here; evaluated per specialisation: LA::reportAgeAtOperationsCentreSeconds.
- `validation/constraint-violation` positionErrorWithoutSatelliteTarget: Constraint could not be evaluated ("positionErrorWithoutSatelliteMetres <= 50.0"): Could not evaluate: positionErrorWithoutSatelliteMetres has no value here; evaluated per specialisation: LA::positionErrorWithoutSatelliteMetres.
- `validation/constraint-violation` reportHoldWhileCutOffTarget: Constraint could not be evaluated ("reportHoldWhileCutOffMinutes >= 30.0"): Could not evaluate: reportHoldWhileCutOffMinutes has no value here; evaluated per specialisation: LA::reportHoldWhileCutOffMinutes.
- `validation/constraint-violation` missedDetectionTarget: Constraint could not be evaluated ("missedDetectionFraction <= 0.10"): Could not evaluate: missedDetectionFraction has no value here; evaluated per specialisation: LA::missedDetectionFraction.
- `validation/constraint-violation` falseAlarmsPerHourTarget: Constraint could not be evaluated ("falseAlarmsPerHour <= 2.0"): Could not evaluate: falseAlarmsPerHour has no value here; evaluated per specialisation: LA::falseAlarmsPerHour.
- `validation/constraint-violation` alertsReachingOperatorTarget: Constraint could not be evaluated ("alertsReachingOperatorPerHour <= 20.0"): Could not evaluate: alertsReachingOperatorPerHour has no value here; evaluated per specialisation: LA::alertsReachingOperatorPerHour.
- `validation/constraint-violation` acknowledgedReportsThatMatterTarget: Constraint could not be evaluated ("acknowledgedReportsThatMatterFraction >= 0.8"): Could not evaluate: acknowledgedReportsThatMatterFraction has no value here; evaluated per specialisation: LA::acknowledgedReportsThatMatterFraction.
- `validation/constraint-violation` onboardClassificationCostTarget: Constraint could not be evaluated ("onboardClassificationCostUsdPerMember <= 300.0"): Could not evaluate: onboardClassificationCostUsdPerMember has no value here; evaluated per specialisation: LA::onboardClassificationCostUsdPerMember.
- `validation/constraint-violation` unattendedWatchDurationTarget: Constraint could not be evaluated ("unattendedWatchDurationHours >= 12.0"): Could not evaluate: unattendedWatchDurationHours has no value here; evaluated per specialisation: LA::unattendedWatchDurationHours.
- `validation/constraint-violation` fleetSizeBudget: Constraint could not be evaluated ("fleetSizeMembers <= 12"): Could not evaluate: fleetSizeMembers has no value anywhere and nothing specialises it.
- `validation/constraint-violation` memberEnduranceBudget: Constraint could not be evaluated ("memberEnduranceMinutes <= 40.0"): Could not evaluate: memberEnduranceMinutes has no value anywhere and nothing specialises it.
- `validation/constraint-violation` groundTurnaroundBudget: Constraint could not be evaluated ("groundTurnaroundMinutes >= 20.0"): Could not evaluate: groundTurnaroundMinutes has no value anywhere and nothing specialises it.
- `validation/constraint-violation` cruiseSpeedBudget: Constraint could not be evaluated ("cruiseSpeedMetresPerSecond <= 18.0"): Could not evaluate: cruiseSpeedMetresPerSecond has no value anywhere and nothing specialises it.
- `validation/constraint-violation` instantaneousFootprintBudget: Constraint could not be evaluated ("instantaneousFootprintSquareKilometres <= 3.0"): Could not evaluate: instantaneousFootprintSquareKilometres has no value anywhere and nothing specialises it.
- `validation/constraint-violation` areaOfInterestBudget: Constraint could not be evaluated ("areaOfInterestSquareKilometres <= 25.0"): Could not evaluate: areaOfInterestSquareKilometres has no value anywhere and nothing specialises it.
- `validation/constraint-violation` operatorSecondsPerAlertBudget: Constraint could not be evaluated ("operatorSecondsPerAlert >= 30.0"): Could not evaluate: operatorSecondsPerAlert has no value anywhere and nothing specialises it.
- `validation/constraint-violation` trackStaleAfterBudget: Constraint could not be evaluated ("trackStaleAfterSeconds <= 120.0"): Could not evaluate: trackStaleAfterSeconds has no value anywhere and nothing specialises it.
- `validation/target-by-specialisation` areaUnderWatchFraction: LA::areaUnderWatchFraction = 0.78216 misses Common::areaUnderWatchTarget (areaUnderWatchFraction >= 0.9)
- `validation/target-by-specialisation` coverageLossAfterMemberLossFraction: LA::coverageLossAfterMemberLossFraction = 0.153421 meets Common::coverageLossAfterMemberLossTarget (coverageLossAfterMemberLossFraction <= 0.25)
- `validation/target-by-specialisation` coverageUnderMeshJammingFraction: LA::coverageUnderMeshJammingFraction = 0.58662 misses Common::coverageUnderMeshJammingTarget (coverageUnderMeshJammingFraction >= 0.75) — missed a placeholder, not the customer's number
- `validation/target-by-specialisation` reportAgeAtOperationsCentreSeconds: LA::reportAgeAtOperationsCentreSeconds = 40 meets Common::reportAgeAtOperationsCentreTarget (reportAgeAtOperationsCentreSeconds <= 60.0)
- `validation/target-by-specialisation` positionErrorWithoutSatelliteMetres: LA::positionErrorWithoutSatelliteMetres = 80 misses Common::positionErrorWithoutSatelliteTarget (positionErrorWithoutSatelliteMetres <= 50.0) — missed a placeholder, not the customer's number
- `validation/target-by-specialisation` reportHoldWhileCutOffMinutes: LA::reportHoldWhileCutOffMinutes = 40 meets Common::reportHoldWhileCutOffTarget (reportHoldWhileCutOffMinutes >= 30.0)
- `validation/target-by-specialisation` missedDetectionFraction: LA::missedDetectionFraction = 0.12 misses Common::missedDetectionTarget (missedDetectionFraction <= 0.10) — missed a placeholder, not the customer's number
- `validation/target-by-specialisation` falseAlarmsPerHour: LA::falseAlarmsPerHour = 3 misses Common::falseAlarmsPerHourTarget (falseAlarmsPerHour <= 2.0) — missed a placeholder, not the customer's number
- `validation/target-by-specialisation` alertsReachingOperatorPerHour: LA::alertsReachingOperatorPerHour = 24 misses Common::alertsReachingOperatorTarget (alertsReachingOperatorPerHour <= 20.0) — missed a placeholder, not the customer's number
- `validation/target-by-specialisation` acknowledgedReportsThatMatterFraction: LA::acknowledgedReportsThatMatterFraction = 0.7 misses Common::acknowledgedReportsThatMatterTarget (acknowledgedReportsThatMatterFraction >= 0.8) — missed a placeholder, not the customer's number
- `validation/target-by-specialisation` onboardClassificationCostUsdPerMember: LA::onboardClassificationCostUsdPerMember = 350 misses Common::onboardClassificationCostTarget (onboardClassificationCostUsdPerMember <= 300.0) — missed a placeholder, not the customer's number
- `validation/target-by-specialisation` unattendedWatchDurationHours: LA::unattendedWatchDurationHours = 0.666667 misses Common::unattendedWatchDurationTarget (unattendedWatchDurationHours >= 12.0) — missed a placeholder, not the customer's number
- `trace.closure` SurveillanceDroneSwarm::SA::mergeTracks: SA → LA: `mergeTracks` is not realised.
- `trace.closure` SurveillanceDroneSwarm::SA::provideCameraTracks: SA → LA: `provideCameraTracks` is not realised.
- `trace.closure` SurveillanceDroneSwarm::SA::swapBatteryAct: SA → LA: `swapBatteryAct` is not realised.
- `trace.closure` SurveillanceDroneSwarm::SA::recoverDroneAct: SA → LA: `recoverDroneAct` is not realised.
- `trace.closure` SurveillanceDroneSwarm::SA::grantClearanceAct: SA → LA: `grantClearanceAct` is not realised.
