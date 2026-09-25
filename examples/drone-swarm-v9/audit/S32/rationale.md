# S32

## What was decided

Alternative 2 is member-centred. All eight #Coordination functions (handOverSector, rotateRecharge, redistributeCoverage, deconflictFlight, relayReportsThroughNeighbour, correlateTracks, handOverTrack, admitMember) are allocated to the fleet, so every member performs them over the mesh. The ground component is thin: groundStation carries only the five #C2 functions (tasking, priorities, recall, status picture, acknowledgement) and does not coordinate. Alert triage and decision records sit in a separate triageUnit so that C2 stays thin and the operator-overload hazard has its own mitigating component. The population is one #Member SwarmMember, a fleet of 12, representatives memberA and memberB, and peerLink over Common::MeshInterface. Each member has a #Mode and a #State machine carrying the four rules and the brief's named states. The fleet has a #Configuration machine with MeshIntact, MeshDegraded and a MeshPartitioned state. The hazards this split adds are split coordination under a partitioned mesh, a lost hand-off between members, and the ground station and the triage unit as single points of failure. Each is satisfied by the fleet, whose members keep watching and hold their reports. The eight SA hazards are satisfied by path, seven by the fleet and operator overload by the triage unit. areaUnderWatchFraction is derived from the brief's numbers (12 drones, 40 min flying, 20 min on the ground, an assumed 6.6 min transit, 3.0 km2 of 25 km2) and comes to about 0.80. It is below the 0.9 target and is not stated larger. The other estimates are literals whose bases are assumptions in their docs.

## Repair 1

The checker reported that four LA hazards (CoordinationConcentrationHazard, SectorHandOffLostHazard, RelayedReportDroppedHazard, TrackHandOverGapHazard) were satisfied only by shared functions, not by a component of this architecture. I added `satisfy LA::Hazards::<name> by fleet;` for each, using the path the checker gave. In the distributed design the fleet holds all eight coordination functions, so no single component's loss stalls sector hand-off, relay or track hand-over. The rest of the fragment is unchanged. I left out the shared function layer and the orchestrator-restored allocate/trace lines, because repeating them would duplicate declarations. The non-blocking warnings are constraints with unknown values and an unresolved ScalarValues::Real, which I did not touch.

## Deliberately left for later

- The LA function names were not visible to me; I assumed each LA function is named as its SA action usage (handOverSector, detectAndClassifyObject, triageAlerts, keepDecisionRecords and so on) and allocated the twenty-one that are system functions. The actor-side SA functions (mergeTracks, provideCameraTracks, swapBatteryAct, recoverDroneAct, grantClearanceAct) are left for whatever actor allocation the layer already has. If LA has functions with other names they still need an allocation.
- Ports are typed by Common::TaskingOrder, PriorityDirective, RecallDirective, ReportReceipt, MemberStatus, TriagedAlerts and DecisionRecords, taken from the port types SA uses; I assumed they are declared in Common and added nothing to commonAdditions.
- No connections to the layer's actors (duty controller, analyst, airspace authority) are written because I could not see how the layer declares them; the operator-facing ends of the ground station and triage unit are left for that step.
- areaUnderWatchFraction depends on the assumed 6.6 min transit (a central recharge point, sectors up to 3.5 km away); check it at PA against the real recharge-point site. Its 0.80 is below the 0.9 target.
- Assumed figures behind the estimates (relay hop time, drift, storage, model quality, alert rate) are to be replaced by measured or chosen values at PA.
- The physical media (mesh radio, ground link) and the radio nodes that carry peerLink and the ground-station connections are left for PA, as are timing and guards on the transitions.
- The #Variant option of a lead member for track correlation, rather than fully peer-to-peer correlation, is not modelled.

## Checks

- `check` clear — `npm run check -- /home/xcos/Work/mbse-workflow/runs/v9/build/5_LA.alt-2.sysml --json`
- `requirements-hazards` clear — `npm run sysprose -- requirements /home/xcos/Work/mbse-workflow/runs/v9/build/5_LA.alt-2.sysml --kind requirement --json`
- `elements` clear — `npm run sysprose -- elements /home/xcos/Work/mbse-workflow/runs/v9/build/5_LA.alt-2.sysml --json`
- `trace-trace` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v9/build/5_LA.alt-2.sysml --relation trace --json`
- `trace-allocate` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v9/build/5_LA.alt-2.sysml --relation allocate --from ActionUsage --to PartUsage --json`
- `connectivity` clear — `npm run sysprose -- connectivity /home/xcos/Work/mbse-workflow/runs/v9/build/5_LA.alt-2.sysml --json`
- `orphans` clear — `npm run sysprose -- orphans /home/xcos/Work/mbse-workflow/runs/v9/build/5_LA.alt-2.sysml --json`
- `reach` clear — `npm run sysprose -- reach /home/xcos/Work/mbse-workflow/runs/v9/build/5_LA.alt-2.sysml --json`

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
- `replicas.topology` : alternative 2: 8 of 13 coordination and command-and-control function(s) on board, 5 on the ground; 1 link(s) between members; fleet [12].
- `fleet.scenario` : no exchange scenario between two members: an `occurrence def` with `ref part a : SwarmMember; ref part b : SwarmMember;` and the messages of a sector handover is what shows the peer protocol (A1-C-15).
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::LA::SwarmMember::SwarmMemberModes::Nominal: `SurveillanceDroneSwarm::LA::SwarmMember::SwarmMemberModes::Nominal`: 4 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Nominal -> NavigationDegraded` (declaration order) and never `Nominal -> SensingDegraded`, `Nominal -> Isolated`, `Nominal -> Quarantined`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::LA::SwarmMember::SwarmMemberStates::Transiting: `SurveillanceDroneSwarm::LA::SwarmMember::SwarmMemberStates::Transiting`: 4 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Transiting -> Watching` (declaration order) and never `Transiting -> Recalled`, `Transiting -> Recovering`, `Transiting -> OutsideClearance`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::LA::SwarmMember::SwarmMemberStates::Watching: `SurveillanceDroneSwarm::LA::SwarmMember::SwarmMemberStates::Watching`: 4 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Watching -> Returning` (declaration order) and never `Watching -> Recalled`, `Watching -> Recovering`, `Watching -> OutsideClearance`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::LA::GroundStation::GroundStationStates::Supervising: `SurveillanceDroneSwarm::LA::GroundStation::GroundStationStates::Supervising`: 2 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Supervising -> Recalling` (declaration order) and never `Supervising -> Standby`.
