# S33

## What was decided

This comparison exists to place command and control, and the two alternatives differ exactly there: Alternative 1 puts sector handover, rotation, redistribution, deconfliction, track correlation and admission inside one GroundSwarmCoordinator; Alternative 2 puts all eight on SwarmMember and leaves a thin GroundStation holding only tasking, priorities, recall, acknowledgement and the status picture. I would take Alternative 2. The deciding evidence is the two components' own state machines. SwarmCoordinatorModes.FleetUnreachable says each drone 'acts on its last assignment' — coverage then decays as endurance runs out, and Alternative 1 discharges its own GroundCoordinatorSinglePointHazard and CoordinationConcentrationHazard onto fleet while allocating no coordination function to fleet, so that mitigation is unbacked. GroundStationModes.LinkDown says the members coordinate and hold reports on their own, and the allocations back it. Alternative 1 is also the weaker model on its own arithmetic: watchingMembers evaluates to 6.8, contradicting the stated 0.78 and 0.16, so three measures score vacuous against Alternative 2's one, and its coverageUnderMeshJammingFraction basis literally blames 'the member-centred allocation' for a worst case that belongs to a ground-centred decision path. Alternative 1 is not without merit and two of its choices should be carried across: recallToFleet, which keeps recall alive when the coordinator dies — Alternative 2 has no equivalent and its operator cannot stop the swarm with the station gone; and the split of GroundDecisionRecordStore from GroundAlertTriage, which Alternative 2 collapses into one AlertTriageUnit so that losing the ranker loses the provenance record. Alternative 1's triggered transitions are also the better basis for checking RecallWins and QuarantinedStaysOut than Alternative 2's untriggered ones. Before PA, Alternative 2 needs four fixes: a direct recall path to fleet, records split out of AlertTriageUnit, triggers and a return direction on the peer link (one unidirectional MeshPort cannot be the whole evidence for eight coordination functions, least of all distributed admitMember), and a rule monitor separate from the component that detects and classifies — neither alternative has one today.

## Checks

- `check` clear — `npm run check -- /home/xcos/Work/mbse-workflow/runs/v9/build/5_LA.sysml --json`
- `trace-trace` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v9/build/5_LA.sysml --relation trace --json`
- `verify` clear — `npm run sysprose -- verify /home/xcos/Work/mbse-workflow/runs/v9/build/5_LA.sysml --json`

## Reported

- `ref/unresolved-specialization` : Unresolved reference 'ScalarValues::Real'
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
- `ref/unresolved-allocation-end` : Unresolved allocation target 'dutyController'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'dutyController'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'dutyController'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'operationsCentreAnalyst'
- `validation/constraint-violation` : Constraint violated: areaUnderWatchFraction == fleetMemberCount * ((memberFlightMinutes - sectorTransitMinutes) / (memberFlightMinutes + memberTurnaroundMinutes)) * memberCoverageFraction
- `trace.closure` SurveillanceDroneSwarm::SA::mergeTracks: SA → LA: `mergeTracks` is not realised.
- `trace.closure` SurveillanceDroneSwarm::SA::provideCameraTracks: SA → LA: `provideCameraTracks` is not realised.
- `trace.closure` SurveillanceDroneSwarm::SA::swapBatteryAct: SA → LA: `swapBatteryAct` is not realised.
- `trace.closure` SurveillanceDroneSwarm::SA::recoverDroneAct: SA → LA: `recoverDroneAct` is not realised.
- `trace.closure` SurveillanceDroneSwarm::SA::grantClearanceAct: SA → LA: `grantClearanceAct` is not realised.
