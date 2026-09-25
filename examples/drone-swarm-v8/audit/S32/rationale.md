# S32

## What was decided

Alternative 2 is the drone-centred split: the fleet (a #Member part def SurveillanceDrone with a fleet[12] usage plus two named representatives memberA/memberB joined by the MeshLink peerLink, per CV-16) is given seven of the eight #Coordination functions — handOverSector, rotateRecharge, redistributeCoverage, deconflictFlight, relayThroughNeighbour, correlateTracks, handOverTrack — as onboard activities settled peer-to-peer over the mesh, together with watchSector, detectAndClassify and reportDetection. Only admitMember (a security/vetting decision) and all five #C2 functions (taskSurveillanceMission, issueSupervisoryCommand, recallToLand, presentStatusPicture, acknowledgeDetectionReport), plus triageReports (which must protect the single operator and so stays centralised), remain on a new GroundControlStation logical component. This satisfies "at least half the #Coordination functions on the members" (7 of 8) while keeping a ground usage for every #C2 function, and is a genuinely different responsibility split from a ground-centred alternative rather than a rename of it — the ground station here is deliberately thin. Each member carries its own #Mode state def (with the four SA rules reproduced on the same Watching/Recalled/AirspaceBreach/Quarantined/Grounded states) and its own #State state def for task execution; the fleet carries one #Configuration state def (Nominal/MeshDegraded/CoverageReduced) rather than a #Mode/#State pair, per CV-16. All eight brief hazards are satisfied by path against fleet or groundControlStation depending on which component now owns the relevant function; two new hazards this split introduces are declared in a nested Hazards package — CoordinationDivergenceHazard (mitigated, since members need a tie-break without a ground arbiter) and GroundAdmissionBottleneckHazard (#Accepted, a deliberate fail-closed trade-off of retaining vetting on the ground). All twelve measures of effectiveness get a #Estimate attribute; areaUnderWatchFraction is derived via valued attributes restating the brief's fixed numbers and an assert constraint tying it to the airborne-share bound, per the checked CV-17 case, rather than being asserted directly.

## Repair 1

Three parse errors and one blocking design finding, all fixed with minimal, targeted edits — nothing else in the fragment was touched:

1. `parse/mismatched-token` at line 388 and the cascading `no-viable-alt`/mismatched-token errors at line 391: the two new hazards added under "hazards this layer adds (safety option)" were declared as `#Hazard CoordinationDivergenceHazard { ... }` and `#Hazard #Accepted GroundAdmissionBottleneckHazard { ... }` — missing the mandatory `requirement` keyword that every other `#Hazard` usage in the file carries (`#Hazard requirement <Name> { ... }`). Without `requirement`, the parser cannot start a requirement-usage declaration after the metadata prefix, so it fails right there and its error recovery misreads everything downstream. Fixed by inserting `requirement` in both: `#Hazard requirement CoordinationDivergenceHazard { ... }` and `#Hazard #Accepted requirement GroundAdmissionBottleneckHazard { ... }`. I also merged them into the single existing `package Hazards { ... }` block (which already held `PeerCoordinationSinglePointHazard` and `GroundLinkC2SinglePathHazard`) instead of leaving a second, stray `doc` line and a second implicit hazards section, since a package block should be declared once; brace nesting is otherwise unchanged.

2. `parse/mismatched-token` at line 724 ("Expecting EOF but found `}`"): this was a downstream consequence of the same missing-`requirement` parse failure derailing the parser's brace bookkeeping for the rest of the file; no unbalanced brace exists once the two hazard declarations above are corrected, so no additional brace edits were needed or made.

3. `alt.c2Placement`: the 17 `allocate` statements under "logical functions ... and their allocation" wrongly used the fully qualified upstream path (`allocate SurveillanceDroneSwarm::SA::SurveillanceDroneSwarmSystem::handOverSector to fleet;`), which allocates the SA layer's function, not this layer's local action usage (`handOverSector` declared earlier in this same package) — so every local #Coordination usage showed as allocated to nothing, and the checker correctly reported 0 of 8 coordination functions on the members. Fixed by rewriting all 17 lines to the bare form required by CV-04 (`allocate handOverSector to fleet;`, etc.), using the local action-usage names already declared in this layer. This puts 7 of the 8 #Coordination functions (handOverSector, rotateRecharge, redistributeCoverage, deconflictFlight, relayThroughNeighbour, correlateTracks, handOverTrack) on `fleet`, satisfying "at least half of the coordination functions on the members," while admitMember and all five #C2 functions stay on `groundControlStation` as the drone-centric alternative already intended; watchSector, detectAndClassify and reportDetection go to `fleet`, and triageReports to `groundControlStation`, matching the architecture narrative already present.

No changes were made to anything else the checker did not name: the shared functions-layer prefix, the CV-17 estimates, the population declaration, the ground/member state machines, the CV-18 rule satisfactions, or the brief-named hazard satisfactions by path were left exactly as given, since those were reported as already checked and traced.

## Repair 2

The blocker was CV-09: `Hazards::PeerCoordinationSinglePointHazard` was only satisfied by the shared function `redistributeCoverage`, which every alternative carries, so it did not count as this architecture's own mitigation. Fixed by adding `satisfy Hazards::PeerCoordinationSinglePointHazard by fleet;` in the hazards-satisfaction block, pointing at the actual component (the fleet of SurveillanceDrone members) that carries the concrete mitigation this alternative introduces: the deterministic lowest-reachable-droneId coordinator election with immediate hand-off on drop-out, described in the `SurveillanceDrone` doc. Also tightened that doc's wording to explicitly tie the rotating-coordinator mechanism to the hazard it mitigates, so the satisfy is traceable to a real design feature rather than an assertion. No other element was changed: all 17 allocations, the population declaration (fleet[12], memberA/memberB, peerLink), the four brief-named member modes, the four CV-18 rule patterns, the 12 #Estimate attributes, the derived areaUnderWatchFraction constraint, and every other hazard satisfy/#Accepted tag are exactly as before. The non-blocking constraint-evaluation warnings on the other 11 estimates are pre-existing and out of scope for this fix — they stem from those #Estimate attributes carrying literal values rather than solver-derived expressions, which is a valid CV-17 answer ("where nothing derives it, state the literal"), and the instructions here direct changing only what the blocking finding names.

## Deliberately left for later

- Confirmed with alternative 1 only by inference (its text was not available to this step); if alternative 1 also allocates admitMember or triageReports differently, reconcile the two alternatives' framing so the trade-off in droneCentricRationale stays accurate.
- The ground uplink/downlink connections (downlinkTasking, uplinkDetections, etc.) model the ground-station link as always-on point-to-point connections between the fleet population and groundControlStation; PA should refine this into the actual intermittent GroundStationLink resource and its reconnection/reconciliation behaviour (DisconnectedOperationAndReconciliation), which this layer only allocates (reportDetection on the fleet) but does not model as a link outage state.
- MeshRadio and RechargePointAndBatterySwap and RecoveryPoint are named as resources in the brief but are physical carriers/ground infrastructure; left for PA to introduce as #Node parts and connection defs rather than modelled here, per CV-05's instruction that the radio carrying a peer link is a #Node part, never an actor.
- StoredMaps as the reference imagery a member navigates against under NavigationDegraded is referenced only in doc, not as a modelled port/flow at this layer; left for PA if a physical data-store connection needs to be shown.

## Checks

- `check` clear — `npm run check -- /home/xcos/Work/mbse-workflow/runs/v8/build/5_LA.alt-2.sysml --json`
- `requirements-hazards` clear — `npm run sysprose -- requirements /home/xcos/Work/mbse-workflow/runs/v8/build/5_LA.alt-2.sysml --kind requirement --json`
- `elements` clear — `npm run sysprose -- elements /home/xcos/Work/mbse-workflow/runs/v8/build/5_LA.alt-2.sysml --json`
- `trace-trace` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v8/build/5_LA.alt-2.sysml --relation trace --json`
- `trace-allocate` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v8/build/5_LA.alt-2.sysml --relation allocate --from ActionUsage --to PartUsage --json`
- `connectivity` clear — `npm run sysprose -- connectivity /home/xcos/Work/mbse-workflow/runs/v8/build/5_LA.alt-2.sysml --json`
- `orphans` clear — `npm run sysprose -- orphans /home/xcos/Work/mbse-workflow/runs/v8/build/5_LA.alt-2.sysml --json`
- `reach` clear — `npm run sysprose -- reach /home/xcos/Work/mbse-workflow/runs/v8/build/5_LA.alt-2.sysml --json`

## Reported

- `validation/constraint-violation` areaUnderWatchMeetsTarget: Constraint could not be evaluated ("areaUnderWatchFraction >= 0.9"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` watchEnduranceMeetsTarget: Constraint could not be evaluated ("watchEnduranceHoursWithoutPeople >= 12"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` reportLatencyMeetsTarget: Constraint could not be evaluated ("reportDeliveryLatencySeconds <= 60"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` positionErrorMeetsTarget: Constraint could not be evaluated ("positionErrorAfterGnssLossMetres <= 50"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` jammedCoverageMeetsTarget: Constraint could not be evaluated ("coverageUnderMeshJammingFraction >= 0.75"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` reportHoldMeetsTarget: Constraint could not be evaluated ("reportHoldDurationMinutes >= 30"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` missedDetectionMeetsTarget: Constraint could not be evaluated ("missedDetectionFraction <= 0.10"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` falseAlarmsMeetTarget: Constraint could not be evaluated ("falseAlarmsPerHour <= 2"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` alertRateMeetsTarget: Constraint could not be evaluated ("alertsReachingOperatorPerHour <= 20"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` acknowledgedPrecisionMeetsTarget: Constraint could not be evaluated ("acknowledgedReportsThatMatterFraction >= 0.8"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` coverageDropMeetsTarget: Constraint could not be evaluated ("coverageDropAfterMemberLossFraction <= 0.25"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` classifierCostMeetsTarget: Constraint could not be evaluated ("onboardClassifierCostUsdPerDrone <= 300"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` fleetSizeWithinBudget: Constraint could not be evaluated ("fleetSizeDrones <= 12"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` flightEnduranceWithinBudget: Constraint could not be evaluated ("memberFlightEnduranceMinutes >= 40"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` turnaroundWithinBudget: Constraint could not be evaluated ("groundTurnaroundMinutes <= 20"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` cruiseSpeedWithinBudget: Constraint could not be evaluated ("cruiseSpeedMetresPerSecond >= 18"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` sensorFootprintWithinBudget: Constraint could not be evaluated ("sensorFootprintSquareKilometres >= 3.0"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` areaWithinBudget: Constraint could not be evaluated ("areaOfInterestSquareKilometres <= 25"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` operatorCapacityWithinBudget: Constraint could not be evaluated ("operatorAlertCapacityPerHour <= 20"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` operatorTimeWithinBudget: Constraint could not be evaluated ("operatorSecondsPerAlert >= 30"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` staleThresholdWithinBudget: Constraint could not be evaluated ("trackStaleThresholdSeconds <= 120"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` gnssOutageWithinBudget: Constraint could not be evaluated ("gnssOutageToleratedMinutes >= 10"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` jammedShareWithinBudget: Constraint could not be evaluated ("jammedLinkShareFraction >= 0.5"): Could not evaluate: a referenced value is unknown.
- `ref/unresolved-allocation-end` : Unresolved allocation target 'watchAsset'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'watchAsset'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'watchAsset'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'watchAsset'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'watchAsset'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'watchAsset'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'watchAsset'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'watchAsset'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'watchAsset'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'watchAsset'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'watchAsset'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'watchAsset'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'watchAsset'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'system'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'system'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'system'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'system'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'system'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'system'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'system'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'system'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'system'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'system'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'system'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'system'
- `ref/unresolved-allocation-end` : Unresolved allocation target 'system'
- `validation/requirement-subject` GroundLinkC2SinglePathHazard: Requirement "SurveillanceDroneSwarm::LA::Hazards::GroundLinkC2SinglePathHazard" has no subject.
- `validation/requirement-subject` GroundAdmissionBottleneckHazard: Requirement "SurveillanceDroneSwarm::LA::Hazards::GroundAdmissionBottleneckHazard" has no subject.
- `validation/constraint-violation` : Constraint could not be evaluated ("airborneShareValue == flightMinutesValue / (flightMinutesValue + turnaroundMinutesValue)"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("areaUnderWatchFraction == (fleetSizeValue * airborneShareValue * footprintValue) / areaOfInterestValue"): Could not evaluate: a referenced value is unknown.
- `replicas.topology` : alternative 2: 7 of 13 coordination and command-and-control function(s) on board, 6 on the ground; 1 link(s) between members; fleet [12].
- `fleet.scenario` : no exchange scenario between two members: an `occurrence def` with `ref part a : SurveillanceDrone; ref part b : SurveillanceDrone;` and the messages of a sector handover is what shows the peer protocol (A1-C-15).
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::SurveillanceDroneSwarmLogical::missionTaskingIn: port `missionTaskingIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::SurveillanceDroneSwarmLogical::supervisoryCommandIn: port `supervisoryCommandIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::SurveillanceDroneSwarmLogical::recallOrderIn: port `recallOrderIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::SurveillanceDroneSwarmLogical::statusPictureOut: port `statusPictureOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::SurveillanceDroneSwarmLogical::reportAcknowledgementIn: port `reportAcknowledgementIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::SurveillanceDroneSwarmLogical::detectionReportsOut: port `detectionReportsOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::SurveillanceDroneSwarmLogical::correlatedTracksOut: port `correlatedTracksOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::SurveillanceDroneSwarmLogical::triagedAlertStreamOut: port `triagedAlertStreamOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::SurveillanceDroneSwarmLogical::decisionRecordOut: port `decisionRecordOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::SurveillanceDroneSwarmLogical::airspaceClearanceIn: port `airspaceClearanceIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::SurveillanceDroneSwarmLogical::movingObjectsInAreaIn: port `movingObjectsInAreaIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::SurveillanceDroneSwarmLogical::sceneConditionsIn: port `sceneConditionsIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::SurveillanceDroneSwarmLogical::radioInterferenceIn: port `radioInterferenceIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::SurveillanceDroneSwarmLogical::satellitePositioningOutageIn: port `satellitePositioningOutageIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::SurveillanceDroneSwarmLogical::weatherLimitIn: port `weatherLimitIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::SwarmSupervisor::missionTaskingOut: port `missionTaskingOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::SwarmSupervisor::supervisoryCommandOut: port `supervisoryCommandOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::SwarmSupervisor::recallOrderOut: port `recallOrderOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::SwarmSupervisor::statusPictureIn: port `statusPictureIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::OperationsCentreAnalyst::reportAcknowledgementOut: port `reportAcknowledgementOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::OperationsCentreAnalyst::detectionReportsIn: port `detectionReportsIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::OperationsCentreAnalyst::correlatedTracksIn: port `correlatedTracksIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::OperationsCentreAnalyst::triagedAlertStreamIn: port `triagedAlertStreamIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::OperationsCentreAnalyst::decisionRecordIn: port `decisionRecordIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::AirspaceAuthority::airspaceClearanceOut: port `airspaceClearanceOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::OperatingEnvironment::movingObjectsInAreaOut: port `movingObjectsInAreaOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::OperatingEnvironment::sceneConditionsOut: port `sceneConditionsOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::OperatingEnvironment::radioInterferenceOut: port `radioInterferenceOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::OperatingEnvironment::satellitePositioningOutageOut: port `satellitePositioningOutageOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::OperatingEnvironment::weatherLimitOut: port `weatherLimitOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::HandOverSector::reqOut: port `reqOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::HandOverSector::reqIn: port `reqIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::RotateRecharge::reqOut: port `reqOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::RotateRecharge::reqIn: port `reqIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::RedistributeCoverage::reqOut: port `reqOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::RedistributeCoverage::reqIn: port `reqIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::DeconflictFlight::reqOut: port `reqOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::DeconflictFlight::reqIn: port `reqIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::RelayThroughNeighbour::reqOut: port `reqOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::RelayThroughNeighbour::reqIn: port `reqIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::CorrelateTracks::reqOut: port `reqOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::CorrelateTracks::reqIn: port `reqIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::HandOverTrack::reqOut: port `reqOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::HandOverTrack::reqIn: port `reqIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::AdmitMember::admitReqOut: port `admitReqOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::AdmitMember::admitReqIn: port `admitReqIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::AdmitMember::admitDecOut: port `admitDecOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::AdmitMember::admitDecIn: port `admitDecIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::TaskSurveillanceMission::cmdOut: port `cmdOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::TaskSurveillanceMission::cmdIn: port `cmdIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::IssueSupervisoryCommand::cmdOut: port `cmdOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::IssueSupervisoryCommand::cmdIn: port `cmdIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::RecallToLand::cmdOut: port `cmdOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::RecallToLand::cmdIn: port `cmdIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::PresentStatusPicture::cmdOut: port `cmdOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::PresentStatusPicture::cmdIn: port `cmdIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::AcknowledgeDetectionReport::ackOut: port `ackOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::AcknowledgeDetectionReport::ackIn: port `ackIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::ReportDetection::reportOut: port `reportOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::ReportDetection::reportIn: port `reportIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::triageReports::triagedAlertOut: port `triagedAlertOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::triageReports::decisionRecordOut: port `decisionRecordOut` is not connected to anything.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::LA::MemberMode::Watching: `SurveillanceDroneSwarm::LA::MemberMode::Watching`: 6 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Watching -> NavigationDegraded` (declaration order) and never `Watching -> SensingDegraded`, `Watching -> Isolated`, `Watching -> AirspaceBreach`, `Watching -> Recalled`, `Watching -> Quarantined`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::LA::MemberMode::Isolated: `SurveillanceDroneSwarm::LA::MemberMode::Isolated`: 3 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Isolated -> Watching` (declaration order) and never `Isolated -> Recalled`, `Isolated -> Grounded`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::LA::MemberOperationalState::Available: `SurveillanceDroneSwarm::LA::MemberOperationalState::Available`: 2 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Available -> Constrained` (declaration order) and never `Available -> Unavailable`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::LA::MemberOperationalState::Constrained: `SurveillanceDroneSwarm::LA::MemberOperationalState::Constrained`: 2 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Constrained -> Available` (declaration order) and never `Constrained -> Unavailable`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::LA::SurveillanceDrone::SurveillanceDroneMode::Grounded: `SurveillanceDroneSwarm::LA::SurveillanceDrone::SurveillanceDroneMode::Grounded`: 2 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Grounded -> Transiting` (declaration order) and never `Grounded -> Quarantined`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::LA::SurveillanceDrone::SurveillanceDroneMode::Transiting: `SurveillanceDroneSwarm::LA::SurveillanceDrone::SurveillanceDroneMode::Transiting`: 2 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Transiting -> Watching` (declaration order) and never `Transiting -> Recalled`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::LA::SurveillanceDrone::SurveillanceDroneMode::Watching: `SurveillanceDroneSwarm::LA::SurveillanceDrone::SurveillanceDroneMode::Watching`: 7 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Watching -> Recharging` (declaration order) and never `Watching -> NavigationDegraded`, `Watching -> SensingDegraded`, `Watching -> Isolated`, `Watching -> AirspaceBreach`, `Watching -> Quarantined`, `Watching -> Recalled`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::LA::SurveillanceDrone::SurveillanceDroneMode::NavigationDegraded: `SurveillanceDroneSwarm::LA::SurveillanceDrone::SurveillanceDroneMode::NavigationDegraded`: 2 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `NavigationDegraded -> Watching` (declaration order) and never `NavigationDegraded -> Isolated`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::LA::SurveillanceDrone::SurveillanceDroneTaskState::Sensing: `SurveillanceDroneSwarm::LA::SurveillanceDrone::SurveillanceDroneTaskState::Sensing`: 3 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Sensing -> Coordinating` (declaration order) and never `Sensing -> Reporting`, `Sensing -> Idle`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::LA::GroundControlStation::GroundControlStationMode::Active: `SurveillanceDroneSwarm::LA::GroundControlStation::GroundControlStationMode::Active`: 2 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Active -> LinkDegraded` (declaration order) and never `Active -> Offline`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::LA::GroundControlStation::GroundControlStationState::Idle: `SurveillanceDroneSwarm::LA::GroundControlStation::GroundControlStationState::Idle`: 2 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Idle -> Triaging` (declaration order) and never `Idle -> Vetting`.
