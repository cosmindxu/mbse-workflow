# S50

## What was decided

I could not see the PA layer, because the prompt left it out. I realised the physical design from the brief instead. It has 16 configuration items:
- Drone-borne hardware: airframe, sensor payload, on-board compute, battery pack and mesh radio.
- Ground hardware: ground station and ground link radio.
- Drone-borne software: flight, classifier and report store-and-forward.
- Coordination software, as two variants: a member-centred build on the drones and a ground-centred build on the ground station. Both are tagged #Variant, since the acquirer chooses between the two architectures.
- Ground software: alert triage, decision records, operator console and a fleet loader.

Each item is a tagged part def with a doc and carries its contract as a requirement def with a subject, an assume constraint and a require constraint. Each has a verification def whose objective verifies that contract. Each is realised by a fielded usage that carries the count as a multiplicity: 12 drone-borne, 1 ground, and 24 battery packs as one set in the drones and one at the recharge point. The numbers come from the brief's fixed budgets and its measures of effectiveness, kept as the brief states them. The placeholder numbers are marked as placeholders in the docs.

The layer adds three hazards, each naming its element and each mitigated by a satisfy:
- BatterySupplierStopsShippingHazard: mitigated by the pack contract, which requires two qualified sources.
- FleetFlightSoftwareVersionDriftHazard: mitigated by the fleet loader, which loads one signed baseline and verifies it before flight.
- SensorPayloadObsolescenceHazard: mitigated by the payload contract, which requires a standard interface and two sources.

The fleet loader, mesh radio and flight software also satisfy three SA hazards: MixedClassifierVersionsHazard, SpoofedMemberHazard and PositionDriftHazard. I did not restate any hazard.

## Repair 1

The two blocking errors were the subject name `classifier`, which the parser reads as a keyword, in DetectionClassifierSoftwareContract (line 283) and VerifyDetectionClassifierSoftware (line 392). I renamed it to `detector` in both places. In the contract I also updated the four references inside the assume and require constraints. Nothing else changed. The non-blocking `ScalarValues::Real` warning and the unevaluable-constraint warnings are left as they were, since you asked for changes only to what the checker names.

## Repair 2

The checker found seven PA usages with no realising configuration item: mainAssembly, fleet, memberA, memberB, groundRecallTransmitter, groundAlertTriage and groundDecisionRecordStore. The existing traces only reached the PA part definitions SwarmMember and GroundStation. I added `trace <ci> to SurveillanceDroneSwarm::PA::<usage>;` for each usage, using CIs that already exist, so no new contracts or verification cases were needed. DroneAirframe realises fleet, memberA, memberB and mainAssembly. MeshRadioModule also realises memberA and memberB, since they exchange traffic over the mesh. GroundStationEquipment and OperatorConsoleSoftware realise groundRecallTransmitter. GroundStationEquipment also realises mainAssembly. AlertTriageSoftware realises groundAlertTriage and DecisionRecordSoftware realises groundDecisionRecordStore. Nothing else changed. The non-blocking constraint warnings are attributes with no value, and the `ScalarValues::Real` warning is a type reference; I left both because they were not among the named faults.

## Deliberately left for later

- PA was not visible to me. I guessed two PA targets, SurveillanceDroneSwarm::PA::SwarmMember and SurveillanceDroneSwarm::PA::GroundStation, for every `trace`. If PA names its parts differently, or has more parts (for example a recovery point, recharge point or ground-link part), change the trace targets and add a CI for each PA part still without one. I left out a CI for the recovery point beacon and the recharge-point kit because I could not tell which PA part they would realise.
- The `trace <ci> to <paPart>;` form is written at package level with the part def name on the left. Reconcile it with the form the checker actually expects.
- Both coordination variants are fielded as usages, each realising a different PA part. The acquirer's choice of architecture (ground-centred or member-centred) is not made here. Drop the losing variant once the choice is made.
- The 24 battery packs are a sizing assumption (one set in the drones and one set at the recharge point), not a number from the brief. The acquirer should confirm it.
- No #Mode or #State definitions are given for these items, because a configuration item here has no behaviour of its own. The member modes and states (NavigationDegraded, SensingDegraded, Isolated, Quarantined) and the RecallWins, ReturnsWhenIsolated, GeofenceBreachEndsWatch and QuarantinedStaysOut rules stay on the LA/PA state machines.
- No ports or interfaces are declared, so nothing is left unconnected. The mesh port and peer interface (Common::MeshPort and Common::MeshInterface) stay with SwarmMember above.
- The measure attributes (positionErrorMetres, missedDetectionFraction, falseAlarmsPerHour, alertsReachingOperatorPerHour, unitCostUsd and the three coverage fractions) have no values. They are left for the solver and for verification results. The requirements use `Real` and `Boolean` without an import, so the checker must resolve them from its standard library.
- The satisfies of SA::Hazards::MixedClassifierVersionsHazard, SpoofedMemberHazard and PositionDriftHazard assume the path SurveillanceDroneSwarm::SA::Hazards::<name>, as the brief states. Remove them if that path does not resolve; the layers above should already satisfy those hazards.

## Checks

- `check` clear — `npm run check -- /home/xcos/Work/mbse-workflow/runs/v9/build/7_EPBS.sysml --json`
- `requirements-hazards` clear — `npm run sysprose -- requirements /home/xcos/Work/mbse-workflow/runs/v9/build/7_EPBS.sysml --kind requirement --json`
- `elements` clear — `npm run sysprose -- elements /home/xcos/Work/mbse-workflow/runs/v9/build/7_EPBS.sysml --json`
- `trace-trace` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v9/build/7_EPBS.sysml --relation trace --from PartUsage --json`
- `trace-verify` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v9/build/7_EPBS.sysml --relation verify --json`
- `refine` clear — `npm run sysprose -- refine /home/xcos/Work/mbse-workflow/runs/v9/build/7_EPBS.sysml --via composition --json`

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
- `validation/constraint-violation` : Constraint could not be evaluated ("alertsReachingOperatorPerHour == alertCapPerHour"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("onboardClassificationCostUsdPerMember == acceleratorModuleCostUsd + modelMemoryCostUsd + reportStoreFlashCostUsd + identityElementCostUsd"): Could not evaluate: a referenced value is unknown.
- `ref/unresolved-requirement` : Unresolved trace element 'SurveillanceDroneSwarm::PA::GroundStation'
- `ref/unresolved-requirement` : Unresolved trace element 'SurveillanceDroneSwarm::PA::GroundStation'
- `ref/unresolved-requirement` : Unresolved trace element 'SurveillanceDroneSwarm::PA::GroundStation'
- `ref/unresolved-requirement` : Unresolved trace element 'SurveillanceDroneSwarm::PA::GroundStation'
- `ref/unresolved-requirement` : Unresolved trace element 'SurveillanceDroneSwarm::PA::GroundStation'
- `ref/unresolved-requirement` : Unresolved trace element 'SurveillanceDroneSwarm::PA::GroundStation'
- `ref/unresolved-requirement` : Unresolved trace element 'SurveillanceDroneSwarm::PA::GroundStation'
- `validation/constraint-violation` : Constraint could not be evaluated ("compute.unitCostUsd <= 300 and compute.reportStorageHoldMinutes >= 30"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("software.positionErrorMetres <= 50 and software.landsWhenRecalledOrOutsideClearance == true and software.returnsToRecoveryPointWhenIsolated == true and software.signedBaseline == true"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("detector.missedDetectionFraction <= 0.1 and detector.falseAlarmsPerHour <= 2 and detector.reportsUnknownBelowThreshold == true and detector.stampsClassifierVersion == true"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("coordination.areaUnderWatchFraction >= 0.9 and coordination.coverageLossAfterMemberLossFraction <= 0.25 and coordination.coverageUnderMeshJammingFraction >= 0.75 and coordination.admitsOnlyAuthenticated == true"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("coordination.areaUnderWatchFraction >= 0.9 and coordination.coverageLossAfterMemberLossFraction <= 0.25 and coordination.coverageUnderMeshJammingFraction >= 0.75 and coordination.admitsOnlyAuthenticated == true"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("triage.alertsReachingOperatorPerHour <= 20 and triage.alertsReachingOperatorPerHour * triage.operatorSecondsPerAlert <= 3600 and triage.mergesDuplicates == true"): Could not evaluate: a referenced value is unknown.
