# S10

## What was decided

OA models the operation without the system: the actors (duty controller, analyst, airspace authority, ground crew, camera-network operator), the nodes (ground station, mesh radio, ground link, recharge point, recovery point, camera network) and the drone population. SwarmMember is declared once. watchAsset is the untagged entity the system takes over, typed by SwarmMember [12]. memberA and memberB are two representatives of it, not extra drones. Every activity is an action usage written at package level and allocated to its performer. None is nested in a part. The eight coordination functions and five C2 functions are tagged action defs with directional ports. Each coordination function has a usage per representative, joined by a flow in both directions over the mesh (16 flows), so no port is left connected to nothing. C2 tasking, priorities and recall flow from the duty controller's activities to each member's ApplySupervisoryDirectives. Detection reports flow to the analyst's acknowledgement, and receipts flow back. Status flows to the status picture, and tracks flow to the analyst's merge with the camera network's tracks. Every capability is a #Capability use case def with a subject, and the overall mission is a #Mission use case def. Modes and states use two state defs per element (member, and the population as a fleet). Every state is reachable from `initial start`. The brief's five modes are states NavigationDegraded, SensingDegraded, Isolated, Quarantined (member) and MeshDegraded (fleet). The CV-18 rules are stated at SA, not here. Hazards are OA's own, in `Hazards`, under names distinct from the brief's SA hazards. OA is the top layer and cannot reference SA, so the brief's eight hazards are not touched here. Each of my four hazards is satisfied by an activity. The Common item defs for environment flows (SurveillanceTasking and the others) were not visible to me, so I added OA item defs under new names instead of guessing.

## Deliberately left for later

- Relate the new Common items TaskingOrder, PriorityDirective, RecallDirective and ReportReceipt to the environment inputs SurveillanceTasking, SupervisoryCommand, RecallOrder and ReportAcknowledgement, or unify them if Common already declares those.
- The OA drone activities for classifier version consistency, decision records and alert triage are capabilities only. Their functions belong at SA/LA.
- The ProgrammeAcquirer stakeholder is not modelled as an operational entity, because it takes no part in the watch. The ground-centred versus member-centred command-and-control choice is a later-layer variant.
- The measures of effectiveness and fixed budgets (fleet size, endurance, cruise speed, footprint) are not written as OA constraints. Attach them to the requirements at SA.
- The status picture reaches the duty controller through the ground station only. A supervising activity on the controller's side is left to SA.
- The mesh and ground-link nodes carry no ports or connections at OA. Component exchanges and typed connections (Common::MeshPort, Common::MeshInterface) start at LA/PA.
- The brief's eight hazards and four rules are stated at SA and are not referenced from OA, because references point upward only.

## Checks

- `check` clear — `npm run check -- /home/xcos/Work/mbse-workflow/runs/v9/build/3_OA.sysml --json`
- `elements` clear — `npm run sysprose -- elements /home/xcos/Work/mbse-workflow/runs/v9/build/3_OA.sysml --json`
- `trace-allocate` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v9/build/3_OA.sysml --relation allocate --from ActionUsage --to PartUsage --json`
- `connectivity` clear — `npm run sysprose -- connectivity /home/xcos/Work/mbse-workflow/runs/v9/build/3_OA.sysml --json`
- `reach` clear — `npm run sysprose -- reach /home/xcos/Work/mbse-workflow/runs/v9/build/3_OA.sysml --json`

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
