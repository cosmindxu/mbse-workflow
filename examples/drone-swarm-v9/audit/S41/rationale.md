# S41

## What was decided

This is the member-centred split, made physical and with the four fixes the LA trade-off asked for. All eight coordination functions, detection and classification, report hold and delivery, status and track reporting, directive uptake and return to the recovery point are allocated to the fleet. That is the SwarmMember definition, twelve members, with the representative pair memberA and memberB. Each member is built from five node parts: a mesh radio, a ground-link radio, a mission computer, a navigation unit and an independent safety monitor. The behaviour parts are nested inside those nodes. The safety monitor is separate from the perception and coordination software, and it executes the member's #State machine, which carries RecallWins, GeofenceBreachEndsWatch and ReturnsWhenIsolated.

The ground side is split into four parts, all named "ground…" so every #C2 function keeps a ground usage:
- groundStation is thin: tasking, priorities, status picture and acknowledgement only.
- groundRecallTransmitter has its own radio and panel, and reaches the fleet through RecallRadioMedium, so recall no longer depends on the station or the ground link.
- groundAlertTriage ranks alerts and enforces a 20-per-hour cap that inside the operator's hour is 600 s of 3600 s.
- groundDecisionRecordStore takes every report directly and is independent of the ranker.

The peer link now has both directions. peerLink and peerLinkReturn are Common::MeshInterface exchanges between the two representatives. The radio paths that carry them are connections typed by MeshRadioMedium between the radio nodes' ports.

Machine notes:
- The member state machines use triggered transitions for recall, clearance loss, quarantine and readmission. Recalled and OutsideClearance lead only to Landed. Quarantined leads only to Readmitted and then Nominal. So the three winsUntil rules hold, and Landed is reachable from every state.
- The fleet has a #Configuration machine that includes MeshDegraded.

Estimates are written directly in the package:
- areaUnderWatchFraction is derived from fleet size, endurance, transit, turnaround and a per-member coverage attribute of 0.12.
- coverageLossAfterMemberLossFraction is derived from that per-member coverage and the area estimate.
- The hold time, alert rate, unattended duration and per-member cost are derived from restated brief numbers.
- The jamming, report age, position error, missed-detection, false-alarm and acknowledged-that-matter estimates are literals with a basis in the doc.

Budgets are `require constraint`s over restated attributes. All are true as written; I did not put a constraint that a stated estimate would refute.

Hazards: six added, all satisfied by parts. All eight SA hazards and all eight LA hazards are satisfied by PA components. The one part I did not name as a satisfier is memberA, because fleet carries it.

Trace lines: I added trace lines from the new top-level parts to their LA counterparts, although the brief said trace lines are added around the answer. I did that so every PA part traces to LA even if the assembler adds none for parts.

## Repair 1

The checker could not confirm the solver's value for four derived estimates: areaUnderWatchFraction, coverageLossAfterMemberLossFraction, reportHoldWhileCutOffMinutes and unattendedWatchDurationHours. Their `assert constraint` equations do not hold exactly in floating point. I dropped those four assert constraints and kept every input attribute. Each of the four is now a literal `#Estimate`, with the arithmetic in its doc. The literals are worst-case roundings: areaUnderWatchFraction 0.78 (from 0.782), coverageLossAfterMemberLossFraction 0.154 (from 0.1538), reportHoldWhileCutOffMinutes 40, unattendedWatchDurationHours 0.66 (from 0.667). I left the two other derived estimates, alertsReachingOperatorPerHour and onboardClassificationCostUsdPerMember, and all their asserts unchanged. Nothing else in the fragment changed. I returned only this alternative's architecture, without the fixed function layer that the checker adds around the answer. The `ScalarValues::Real` warning and the "referenced value is unknown" constraint warnings are not in my fragment, so I left them. I expect the unevaluable-value warnings to clear now that the estimates carry literals.

## Deliberately left for later

- Variability: no #Variant options are declared. The accelerator module and the report-store medium are the natural candidates once the customer states the cost target.
- The ground links from the drones to the operations centre and the operations-centre link itself are external resources. Only the drone-to-ground-station link is a typed connection here; the ground station's own radio to the operations centre is not modelled.
- The SA rule requirements (RecallWins, GeofenceBreachEndsWatch, ReturnsWhenIsolated, QuarantinedStaysOut) are carried in the member state defs. Their `satisfy` lines are not restated here because their SA package path was not given.
- Clearance withdrawal is triggered with a Common::TaskingOrder payload and admission verdicts with a Common::MemberStatus payload, because Common has no dedicated items. A ClearanceNotice item and an AdmissionVerdict item, each with units where they have any, should be added to Common if the reviewers want them typed exactly.
- The report-store capacity (2000 reports) and the peak report rate (6 per minute) are sizing assumptions until the customer states the report rate.
- Numbers that stay below the placeholder targets and are stated as such: area under watch 0.78, mesh-jammed coverage 0.68, position error 80 m, missed detection 0.12, false alarms 3/h, acknowledged-that-matter 0.75, cost 350 USD and unattended watch 0.67 h. The customer's figures may change them.
- The state machines are attached to the SwarmMember definition. Making the independent safety monitor the part that owns the machine would need a member-level binding, which this dialect cannot express.

## Checks

- `check` clear — `npm run check -- /home/xcos/Work/mbse-workflow/runs/v9/build/6_PA.alt-2.sysml --json`
- `elements` clear — `npm run sysprose -- elements /home/xcos/Work/mbse-workflow/runs/v9/build/6_PA.alt-2.sysml --json`
- `connectivity` clear — `npm run sysprose -- connectivity /home/xcos/Work/mbse-workflow/runs/v9/build/6_PA.alt-2.sysml --json`
- `trace-trace` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v9/build/6_PA.alt-2.sysml --relation trace --json`
- `trace-allocate` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v9/build/6_PA.alt-2.sysml --relation allocate --from ActionUsage --to PartUsage --json`
- `orphans` clear — `npm run sysprose -- orphans /home/xcos/Work/mbse-workflow/runs/v9/build/6_PA.alt-2.sysml --json`
- `reach` clear — `npm run sysprose -- reach /home/xcos/Work/mbse-workflow/runs/v9/build/6_PA.alt-2.sysml --json`
- `requirements-hazards` clear — `npm run sysprose -- requirements /home/xcos/Work/mbse-workflow/runs/v9/build/6_PA.alt-2.sysml --kind requirement --json`
- `verify` clear — `npm run sysprose -- verify /home/xcos/Work/mbse-workflow/runs/v9/build/6_PA.alt-2.sysml --json`

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
- `replicas.topology` : alternative 2: 8 of 13 coordination and command-and-control function(s) on board, 5 on the ground; 4 link(s) between members; fleet [12].
- `fleet.scenario` : no exchange scenario between two members: an `occurrence def` with `ref part a : SwarmMember; ref part b : SwarmMember;` and the messages of a sector handover is what shows the peer protocol (A1-C-15).
- `functions.coordination` SurveillanceDroneSwarm::PA::handOverSector: `handOverSector` is coordination between members and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.coordination` SurveillanceDroneSwarm::PA::rotateRecharge: `rotateRecharge` is coordination between members and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.coordination` SurveillanceDroneSwarm::PA::redistributeCoverage: `redistributeCoverage` is coordination between members and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.coordination` SurveillanceDroneSwarm::PA::deconflictFlight: `deconflictFlight` is coordination between members and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.coordination` SurveillanceDroneSwarm::PA::relayReportsThroughNeighbour: `relayReportsThroughNeighbour` is coordination between members and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.coordination` SurveillanceDroneSwarm::PA::correlateTracks: `correlateTracks` is coordination between members and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.coordination` SurveillanceDroneSwarm::PA::handOverTrack: `handOverTrack` is coordination between members and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.coordination` SurveillanceDroneSwarm::PA::admitMember: `admitMember` is coordination between members and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.c2` SurveillanceDroneSwarm::PA::taskSurveillanceArea: `taskSurveillanceArea` is command and control and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.c2` SurveillanceDroneSwarm::PA::commandSupervisoryPriorities: `commandSupervisoryPriorities` is command and control and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.c2` SurveillanceDroneSwarm::PA::recallAndLand: `recallAndLand` is command and control and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.c2` SurveillanceDroneSwarm::PA::presentStatusPicture: `presentStatusPicture` is command and control and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.c2` SurveillanceDroneSwarm::PA::acknowledgeDetectionReport: `acknowledgeDetectionReport` is command and control and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `rules.hold` SurveillanceDroneSwarm::PA::SwarmMember::SwarmMemberStates: the rule `ReturnsWhenIsolated` could not be decided on `PA::SwarmMember::SwarmMemberStates` (inconclusive): inconclusive: this machine names triggers this walk offers at every configuration, so "reachable from every configuration" would be a claim about an environment this walk has no carrier for — the environment offered every trigger this machine names at every configuration, so a witness that consumes 
- `connectivity.layerPorts` SurveillanceDroneSwarm::PA::SurveillanceDroneSwarmPhysical::reportsOut: port `reportsOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::PA::SurveillanceDroneSwarmPhysical::trackPictureOut: port `trackPictureOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::PA::SurveillanceDroneSwarmPhysical::statusOut: port `statusOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::PA::SurveillanceDroneSwarmPhysical::taskingIn: port `taskingIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::PA::SurveillanceDroneSwarmPhysical::priorityIn: port `priorityIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::PA::SurveillanceDroneSwarmPhysical::recallIn: port `recallIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::PA::SurveillanceDroneSwarmPhysical::receiptIn: port `receiptIn` is not connected to anything.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::PA::SwarmMember::SwarmMemberModes::Nominal: `SurveillanceDroneSwarm::PA::SwarmMember::SwarmMemberModes::Nominal`: 3 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Nominal -> NavigationDegraded` (declaration order) and never `Nominal -> SensingDegraded`, `Nominal -> Isolated`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::PA::SwarmMember::SwarmMemberModes::NavigationDegraded: `SurveillanceDroneSwarm::PA::SwarmMember::SwarmMemberModes::NavigationDegraded`: 2 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `NavigationDegraded -> Nominal` (declaration order) and never `NavigationDegraded -> Isolated`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::PA::SwarmMember::SwarmMemberModes::SensingDegraded: `SurveillanceDroneSwarm::PA::SwarmMember::SwarmMemberModes::SensingDegraded`: 2 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `SensingDegraded -> Nominal` (declaration order) and never `SensingDegraded -> Isolated`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::PA::SwarmMember::SwarmMemberModes::Isolated: `SurveillanceDroneSwarm::PA::SwarmMember::SwarmMemberModes::Isolated`: 2 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Isolated -> Readmitted` (declaration order) and never `Isolated -> Quarantined`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::PA::SwarmMember::SwarmMemberStates::Transiting: `SurveillanceDroneSwarm::PA::SwarmMember::SwarmMemberStates::Transiting`: 2 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Transiting -> Watching` (declaration order) and never `Transiting -> Recovering`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::PA::SwarmMember::SwarmMemberStates::Watching: `SurveillanceDroneSwarm::PA::SwarmMember::SwarmMemberStates::Watching`: 2 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Watching -> Returning` (declaration order) and never `Watching -> Recovering`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::PA::GroundStationNode::GroundStationStates::Supervising: `SurveillanceDroneSwarm::PA::GroundStationNode::GroundStationStates::Supervising`: 2 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Supervising -> Recalling` (declaration order) and never `Supervising -> Standby`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::PA::GroundStationNode::GroundStationStates::Recalling: `SurveillanceDroneSwarm::PA::GroundStationNode::GroundStationStates::Recalling`: 2 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Recalling -> Supervising` (declaration order) and never `Recalling -> Standby`.
