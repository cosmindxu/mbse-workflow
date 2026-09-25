# S31

## What was decided

The fragment is functions-only, as this step requires. 21 logical functions are declared as action defs that specialise the SA function they realise. The 8 coordination functions are tagged #Coordination and the 5 command-and-control functions are tagged #C2, so none is lost. The other 8 realise sensing, reporting, status, track, recovery, triage and record functions. Every function has a usage that is allocated to one placeholder component, LogicalSystem/logicalSystem. Where coordination and C2 sit (ground, representative member or fleet) is left to the next step. That choice is not made here. I did not realise the SA functions whose docs give them to actors: MergeSwarmTracks, ProvideCameraTracks, SwapBattery, RecoverReturnedDrone and GrantAirspaceClearance.

The population follows CV-16. There is one #Member part def SwarmMember with meshOut/meshIn, `part fleet : SwarmMember [12]`, and representatives memberA and memberB. They are joined by peerLink, and I added peerLinkReturn in the other direction so no member port is left unconnected. Members carry a #Mode state def (Nominal, NavigationDegraded, SensingDegraded, Isolated, Quarantined, Readmitted) and a #State state def (Landed, Transiting, Watching, Returning, Recalled, Recovering, OutsideClearance). The four CV-18 rules are carried as PropertyPattern metadata with the same q/r/p states as SA. The fleet has a #Configuration state def with MeshIntact and MeshDegraded. I used anonymous `transition a -> b;` so no trigger item types outside Common are needed. Every state is reachable from the initial state, and Landed is reachable from every sortie state.

The 8 brief hazards are satisfied by path from SA::Hazards, and none is restated. The functions that mitigate them are:
- MeshJamming: relay.
- Misclassification: detectAndClassify.
- SensingDegradedUnnoticed: reportMemberStatus.
- StaleTrack: reportTrackPicture.
- SpoofedMember and MixedClassifierVersions: admitMember.
- OperatorOverload: triageAlerts.
- PositionDrift: the fleet, through its NavigationDegraded mode.

The 4 rules are satisfied by `fleet`. The layer adds four hazards of its own, each about the split: CoordinationConcentrationHazard, SectorHandOffLostHazard, RelayedReportDroppedHazard and TrackHandOverGapHazard. Each is mitigated by a function.

Estimates are stated for the 12 scored measures. Each is a worst case taken across both allocations, and its basis is in the doc. Several miss their targets: area under watch, jamming coverage, position error, missed detections, alerts per hour, onboard cost and unattended duration. The fixed budgets are not estimated, as instructed.

## Repair 1

The checker said this step writes functions only. I removed the components LogicalSystem, logicalSystem, fleet, memberA and memberB. I also removed peerLink and peerLinkReturn, because they connected the removed representatives. The placeholder is restored as `part def SurveillanceDroneSwarmLogical` and `part mainComponent : SurveillanceDroneSwarmLogical`. All 21 function usages are now allocated to mainComponent. The hazard subject that named LogicalSystem now names SurveillanceDroneSwarmLogical. The satisfy lines that pointed at `fleet` (PositionDriftHazard, RecallWins, ReturnsWhenIsolated, GeofenceBreachEndsWatch, QuarantinedStaysOut) now point at mainComponent. I kept the SwarmMember definition with its modes, states and ports, and the FleetConfiguration state machine. Nothing was added to Common. The 'not blocking' items (ScalarValues::Real and the unevaluable constraints) come from Common or the layers above and are outside this fragment, so I left them. The counted fleet usage of 12 and the two peer representatives with their interface are gone from this layer. I could not put them back without breaking the functions-only rule, so the next step has to place them again (CV-16). I kept the orchestrator's carried block of allocations and traces at the end. It repeats 16 of the mainComponent allocations, and I left it unchanged.

## Deliberately left for later

- The skeleton placeholder component was not visible to me (the starting point was left out of the prompt). I declared LogicalSystem/logicalSystem myself and allocated every function to it; rename or merge with the skeleton's placeholder if it differs.
- Trace to SA is written as specialisation (`action def X :> SurveillanceDroneSwarm::SA::X`); switch to the project's own trace relation if it differs.
- Decide the allocation of the #Coordination and #C2 functions (ground-centred versus member-centred) in the next step. Tag the options #Variant there, and re-state the estimates for each option.
- watchAsset is an OA-level operational entity and is not re-declared at LA.
- Actor-owned SA functions (MergeSwarmTracks, ProvideCameraTracks, SwapBattery, RecoverReturnedDrone, GrantAirspaceClearance) are deliberately not realised at LA.
- Transitions are anonymous, without triggers or effects. Add named accept-transitions once the trigger items are in Common.
- The fixed budgets (fleet size, endurance, turnaround, cruise speed, footprint, area, operator seconds, stale threshold, outage minutes, jammed fraction) could be written as `require constraint` for a solver. That is left for a later step.
- The estimate figures are engineering guesses on placeholders. Replace them with the customer's numbers, and check the units of the Common measure attributes.

## Checks

- `check` clear — `npm run check -- /home/xcos/Work/mbse-workflow/runs/v9/build/5_LA.sysml --json`
- `requirements-hazards` clear — `npm run sysprose -- requirements /home/xcos/Work/mbse-workflow/runs/v9/build/5_LA.sysml --kind requirement --json`
- `elements` clear — `npm run sysprose -- elements /home/xcos/Work/mbse-workflow/runs/v9/build/5_LA.sysml --json`
- `trace-trace` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v9/build/5_LA.sysml --relation trace --json`
- `trace-allocate` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v9/build/5_LA.sysml --relation allocate --from ActionUsage --to PartUsage --json`

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
- `ref/unresolved-allocation-end` : Unresolved allocation target 'groundStation'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'operationsCentreAnalyst'
- `functions.coordination` SurveillanceDroneSwarm::LA::handOverSector: `handOverSector` is coordination between members and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.coordination` SurveillanceDroneSwarm::LA::rotateRecharge: `rotateRecharge` is coordination between members and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.coordination` SurveillanceDroneSwarm::LA::redistributeCoverage: `redistributeCoverage` is coordination between members and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.coordination` SurveillanceDroneSwarm::LA::deconflictFlight: `deconflictFlight` is coordination between members and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.coordination` SurveillanceDroneSwarm::LA::relayReportsThroughNeighbour: `relayReportsThroughNeighbour` is coordination between members and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.coordination` SurveillanceDroneSwarm::LA::correlateTracks: `correlateTracks` is coordination between members and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.coordination` SurveillanceDroneSwarm::LA::handOverTrack: `handOverTrack` is coordination between members and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.coordination` SurveillanceDroneSwarm::LA::admitMember: `admitMember` is coordination between members and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.c2` SurveillanceDroneSwarm::LA::taskSurveillanceArea: `taskSurveillanceArea` is command and control and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.c2` SurveillanceDroneSwarm::LA::commandSupervisoryPriorities: `commandSupervisoryPriorities` is command and control and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.c2` SurveillanceDroneSwarm::LA::recallAndLand: `recallAndLand` is command and control and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.c2` SurveillanceDroneSwarm::LA::presentStatusPicture: `presentStatusPicture` is command and control and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.c2` SurveillanceDroneSwarm::LA::acknowledgeDetectionReport: `acknowledgeDetectionReport` is command and control and nothing flows into or out of it. What does it receive, and what does it decide for whom?
