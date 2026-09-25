# S21

## What was decided

The system is one black box with fourteen ports on the environment, and each port is wired by a connection to a port on the actor it faces. The twelve-drone population stays a carried #Member definition (no usage), as the brief requires at SA.

**Renamed functions.** I renamed the five C2 function usages to the brief's names: taskSurveillanceArea, commandSupervisoryPriorities, recallAndLand, presentStatusPicture and acknowledgeDetectionReport. The check asks for each C2 function under its brief name. Their allocations and traces to the OA issue*/present/acknowledge activities are kept, and the flows are rewritten to the new names.

**Added functions.** I added triageAlerts and keepDecisionRecords for the AlertTriage and DecisionRecordKeeping capabilities, which have no OA activity. The brief outputs TriagedAlerts and DecisionRecords need a function, and OperatorOverloadHazard needs a mitigator. Each traces to its OA capability use case and to OA::acknowledgeReports.

**State machines.** SwarmMember carries two state defs: SwarmMemberModes (#Mode) and SwarmMemberStates (#State). The fleet's MeshDegraded state is in a package-level #Configuration def, FleetConfiguration, since there is no fleet usage at SA.
- All five brief modes are states of their owner.
- I added two states to the OA machines. OutsideClearance gives GeofenceBreachEndsWatch a state to start from. Readmitted gives QuarantinedStaysOut an end state, so Nominal, the state where the drone coordinates, can be the forbidden state.
- The four rules are carried as PropertyPatterns. RecallWins, GeofenceBreachEndsWatch and ReturnsWhenIsolated sit in the state machine, and QuarantinedStaysOut sits in the mode machine. I checked by hand that Recalled, OutsideClearance and Quarantined each have a single exit, and that every state can reach Landed. The rules are stated once at SA as #Rule requirements, each satisfied by SwarmMember.

**Hazards.** The eight brief hazards are #Hazard requirements in SA::Hazards, each with a subject. Every one is satisfied by path, and so are the four OA hazards. MixedClassifierVersionsHazard is mitigated by admitMember, on the reading that admission checks the classifier version.

**Common.** The starting point's Common items, the OA exchange items and the existing item names (TaskingOrder, PriorityDirective, RecallDirective, ReportReceipt, MemberStatus and so on) are assumed to exist and are reused. I could not see Common, so I did not re-declare them. Ten new item defs come back in commonAdditions, for boundary items and trigger payloads that had no equivalent.

**New actor.** I added the actor MovingObjectsSource so the MovingObjectsInArea input has a wired source. It has no OA trace, since it is an environment source and not an OA entity.

**Actors with no ports.** The mesh radio, the ground link radio and the fixed-camera-network operator have no ports at SA and say so in their docs. They are media or have no exchange with the system at this level. The environment constraints with no sender, such as RadioInterference and weather, are carried in a #prose part.

## Deliberately left for later

- Numeric budgets (fleet 12, endurance 40 min, cruise 18 m/s, footprint 3.0 km2, area 25 km2, turnaround 20 min, 30 s per alert, 120 s stale, and the effectiveness targets) are not yet written as require constraint blocks; do this when the requirement layer for measures is available.
- The member mode machine is exclusive: a drone that is at once NavigationDegraded and Isolated, or SensingDegraded and Quarantined, cannot be expressed. Combined conditions need parallel or composite states at LA.
- Wind above moderate is only modelled as a Watching -> Returning transition; Transiting -> landing on wind is left to LA.
- Recall while Returning, Recovering or Landed is not a transition (the drone is already coming down or on the ground); revisit if a single-drone recall must change a Returning drone's destination.
- Whether classifier-version checking sits in admitMember (as chosen for MixedClassifierVersionsHazard) or in a separate version-consistency function is left for LA; the ClassifierVersionConsistency capability has no OA activity of its own.
- Where triageAlerts and keepDecisionRecords run (ground station or on board) and whether the ground station coordinates the swarm are the command-and-control architecture decision and belong to LA/PA.
- The ground station and ground link are kept as actors, as handed over from OA; whether the ground station becomes part of the system is decided when the ground-centred and member-centred architectures are split.
- The ports on the actors (batterySwap, recoveryPoint, groundCrew) carry only DroneArrival and DroneServiced items as a physical rendezvous; refine at PA.

## Checks

- `check` clear — `npm run check -- /home/xcos/Work/mbse-workflow/runs/v9/build/4_SA.sysml --json`
- `elements` clear — `npm run sysprose -- elements /home/xcos/Work/mbse-workflow/runs/v9/build/4_SA.sysml --json`
- `trace-trace` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v9/build/4_SA.sysml --relation trace --json`
- `trace-allocate` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v9/build/4_SA.sysml --relation allocate --from ActionUsage --to PartUsage --json`
- `connectivity` clear — `npm run sysprose -- connectivity /home/xcos/Work/mbse-workflow/runs/v9/build/4_SA.sysml --json`
- `reach` clear — `npm run sysprose -- reach /home/xcos/Work/mbse-workflow/runs/v9/build/4_SA.sysml --json`
- `requirements` clear — `npm run sysprose -- requirements /home/xcos/Work/mbse-workflow/runs/v9/build/4_SA.sysml --json`
- `requirements-hazards` clear — `npm run sysprose -- requirements /home/xcos/Work/mbse-workflow/runs/v9/build/4_SA.sysml --kind requirement --json`
- `consistency` clear — `npm run sysprose -- consistency /home/xcos/Work/mbse-workflow/runs/v9/build/4_SA.sysml --json`

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
- `sa.chains` : no functional chain for ContinuousSectorWatch, MovingObjectDetectionAndClassification, ReportDeliveryAndReconciliation, SwarmSelfCoordination, OperatorSupervisionOfTheSwarm, AlertTriage, DecisionRecordKeeping, GracefulDegradationUnderLoss, AirspaceComplianceAndSafeRecovery, ClassifierVersionConsistency. A chain is `#Chain occurrence def <Capability>Chain { doc /* the functions, in order */ }` with `succession` lines between its functions; it is what a latency budget and an integration test attach to.
- `rules.hold` SurveillanceDroneSwarm::SA::SwarmMember::SwarmMemberStates: the rule `ReturnsWhenIsolated` could not be decided on `SA::SwarmMember::SwarmMemberStates` (inconclusive): inconclusive: this machine names triggers this walk offers at every configuration, so "reachable from every configuration" would be a claim about an environment this walk has no carrier for — the environment offered every trigger this machine names at every configuration, so a witness that consumes 
- `connectivity.layerPorts` SurveillanceDroneSwarm::SA::SwarmMember::meshOut: port `meshOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::SA::SwarmMember::meshIn: port `meshIn` is not connected to anything.
