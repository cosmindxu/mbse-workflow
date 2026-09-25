# S21

## What was decided

Followed the advisor's review closely. Key decisions:

1. Added a #C2-tagged `acknowledgeReport` function allocated to the system (distinct from the actor's `acknowledgeReportAct`), because the checker requires every brief-named coordination/C2 function to exist under that literal name as a system function. Traced it to both OA::reportA (where the member takes the ack in) and OA::acknowledgeReportAct (the corresponding operational activity), and gave it its own flow (ackToSystemFlow) from the duty controller's ack action, while leaving the pre-existing acknowledgeReportAct/dutyController allocation and ackToAFlow untouched.

2. Added explicit ports on `SurveillanceDroneSwarmSystem` for every environment exchange that OA actually routes to/from a named actor (tasking, supervision, recall, ack in; reports, decisions, status, recharge-request out), and matching ports on DutyController, OperationsCentre and GroundCrew, wired by `connection ... connect` statements — this is what "the system ports are wired to the actors" checks. Deliberately did NOT give the system a MovingObjectsInArea or CameraNetworkTracks port: OA has no port on any system-side action for the former, and the latter is routed fixedCameraNetworkOwner → operationsCentre via mergeAct, an actor function — adding either would be an invented, unwired port. AirspaceAuthority, ProgrammeSponsor, Analysts and FixedCameraNetworkOwner stay portless with a doc explaining they constrain or exchange only with other actors, not the system.

3. Added two state defs each (#Mode/#State) for the member (`SurveillanceDrone`) and the system (standing in for the fleet), all reachable from `initial start`. The member's #Mode machine carries the four required `NavigationDegraded`/`SensingDegraded`/`Isolated`/`Quarantined` states plus `Watching`/`Landed`/`Recalled`/`OutsideClearedAirspace`, each of the three wins-until rule's q-states given exactly one outgoing transition (to Landed) so the absence pattern holds trivially, and `Isolated` given a direct edge to `Landed` for the recovery pattern. The system's #Mode machine carries `MeshDegraded` (a fleet-level mode per the brief) — used `#Mode` rather than the undeclared `#Configuration` tag, flagged in todos.

4. Declared all four `#Rule requirement`s at SA with `subject s : SurveillanceDrone`, satisfying the requirement-subject validation; left `satisfy` of these to LA since no part of SurveillanceDrone exists yet at SA (population is carried, not instantiated) — intake lane is off, so this doesn't block.

5. Declared all eight brief-named hazards as `#Hazard requirement`s in a nested `package Hazards`, each satisfied by path immediately after the corresponding mitigating function is declared (moved satisfy statements to directly follow each function so ordering never references a not-yet-declared name). `MixedClassifierVersionsHazard` needed a new function (`manageClassifierVersion`) since OA has no dedicated action for it; traced it to the OA capability use case `ManageClassifierVersion` instead.

6. Filled every previously-TODO doc with text drawn from the brief/OA docs, and added doc bodies to new elements (state defs, states, rules, hazards, connections, the new function). Left the untouched, already-undocumented simple `part x : Y;` actor-usage lines as in the given draft, since doc coverage is graded as a minimum, not literal 100%.

Left all self-flows between paired coordination-function ports, the `meshOut`/`meshIn` ports on the carried `SurveillanceDrone` def, and all pre-existing trace/allocate statements exactly as given.

## Repair 1

The only blocking finding was the duplicate name "ManageClassifierVersion" appearing twice in package SA's scope: once as the `#Capability use case def ManageClassifierVersion` (carried from OA, traced by name to SurveillanceDroneSwarm::OA::ManageClassifierVersion) and once as the plain `action def ManageClassifierVersion` (the new SA function definition introduced to mitigate the mixed-classifier-versions hazard). Because both live directly in package SA, this is a same-scope clash (CV-01), not a cross-layer one, so it must be resolved by renaming rather than qualifying.

I renamed only the function definition to `ManageClassifierVersionFunction` and updated its single usage site's type reference (`action manageClassifierVersion : ManageClassifierVersionFunction`) accordingly. The capability use case def keeps the name `ManageClassifierVersion` since that is what traces to the OA capability of the same name and is not itself duplicated elsewhere. The usage `action manageClassifierVersion` (lowercase) keeps its name too, since usage names live in a different namespace slot than def names and were not flagged. All traces, allocations, satisfy statements, docs, and every other construct are untouched — nothing else in the fragment was implicated by the reported error, and the "also reported, not blocking" items (unevaluable numeric constraints, missing #Chain occurrence defs) are explicitly out of scope for this fix per the instructions to change only what the blocking findings name.

No new Common declarations were needed for this fix.

## Deliberately left for later

- LA should replace the system's #Mode tag on the fleet-level machine (Covering/MeshDegraded) with #Configuration once that metadata def is declared in Kinds, per CV-16's 'fleet-level states are a #Configuration state def' rule; SA used #Mode as a safe stand-in since #Configuration was not evidenced as declared.
- LA/PA must satisfy the four #Rule requirements (RecallWins, ReturnsWhenIsolated, GeofenceBreachEndsWatch, QuarantinedStaysOut) by the concrete SurveillanceDrone part/member instance, since SA carries the member definition without instantiating it and cannot name a satisfying part yet.
- No #Variant tagging was needed at SA — the brief describes no options/alternatives at this layer; revisit at LA/PA if a design choice (e.g. mesh topology, classifier deployment) introduces one.
- MixedClassifierVersionsHazard's mitigator (manageClassifierVersion) is a new SA-introduced function with no OA action-def counterpart; confirm at LA that ManageClassifierVersion gains a proper operational activity if the checker's OA-trace rule is later tightened to disallow tracing a function to a capability use case.
- Verify against the assembled Kinds package that #Hazard, #Rule, #Mode, #State and #Accepted are already declared metadata defs; SA assumed they are (matching the #Member/#Actor/#Coordination/#C2 tags already used upstream) since this fragment cannot declare them itself.

## Checks

- `check` clear — `npm run check -- /home/xcos/Work/mbse-workflow/runs/v7/build/4_SA.sysml --json`
- `elements` clear — `npm run sysprose -- elements /home/xcos/Work/mbse-workflow/runs/v7/build/4_SA.sysml --json`
- `trace-trace` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v7/build/4_SA.sysml --relation trace --json`
- `trace-allocate` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v7/build/4_SA.sysml --relation allocate --from ActionUsage --to PartUsage --json`
- `connectivity` clear — `npm run sysprose -- connectivity /home/xcos/Work/mbse-workflow/runs/v7/build/4_SA.sysml --json`
- `reach` clear — `npm run sysprose -- reach /home/xcos/Work/mbse-workflow/runs/v7/build/4_SA.sysml --json`
- `requirements` clear — `npm run sysprose -- requirements /home/xcos/Work/mbse-workflow/runs/v7/build/4_SA.sysml --json`
- `requirements-hazards` clear — `npm run sysprose -- requirements /home/xcos/Work/mbse-workflow/runs/v7/build/4_SA.sysml --kind requirement --json`
- `consistency` clear — `npm run sysprose -- consistency /home/xcos/Work/mbse-workflow/runs/v7/build/4_SA.sysml --json`

## Reported

- `validation/constraint-violation` : Constraint could not be evaluated ("areaUnderWatchShare >= 0.9"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("coverageLossOnMemberLoss <= 0.25"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("jammedMeshAreaUnderWatchShare >= 0.75"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("groundLinkLossAreaUnderWatchShare >= 0.9"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("watchEnduranceHours >= 24"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("reportLatencySeconds <= 60"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("positionErrorWithoutGnssMeters <= 50"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("reportHoldMinutes >= 30"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("reportsLostInLinkGap <= 0"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("missedDetectionShare <= 0.1"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("falseAlarmsPerHour <= 2"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("operatorAlertsPerHour <= 20"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("acknowledgedReportsThatMatterShare >= 0.8"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("onboardClassificationCostUsd <= 300"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("fleetSize <= 12"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("operatorSecondsPerAlert >= 30"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("memberFlightEnduranceMinutes <= 40"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("memberRechargeMinutes >= 60"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("areaOfInterestKm2 <= 25"): Could not evaluate: a referenced value is unknown.
- `sa.chains` : no functional chain for HoldContinuousWatch, DetectClassifyAndReport, CoordinateSwarm, SuperviseSwarm, OperateThroughLinkGap, StayWithinClearedAirspace, NavigateWithoutSatellitePositioning, TriageReports, KeepDecisionRecord, ManageClassifierVersion. A chain is `#Chain occurrence def <Capability>Chain { doc /* the functions, in order */ }` with `succession` lines between its functions; it is what a latency budget and an integration test attach to.
- `connectivity.layerPorts` SurveillanceDroneSwarm::SA::SurveillanceDrone::meshOut: port `meshOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::SA::SurveillanceDrone::meshIn: port `meshIn` is not connected to anything.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::SA::SurveillanceDroneMode::Watching: `SurveillanceDroneSwarm::SA::SurveillanceDroneMode::Watching`: 6 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Watching -> NavigationDegraded` (declaration order) and never `Watching -> SensingDegraded`, `Watching -> Isolated`, `Watching -> Quarantined`, `Watching -> Recalled`, `Watching -> OutsideClearedAirspace`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::SA::SurveillanceDroneMode::Isolated: `SurveillanceDroneSwarm::SA::SurveillanceDroneMode::Isolated`: 2 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Isolated -> Landed` (declaration order) and never `Isolated -> Watching`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::SA::SurveillanceDroneStatus::Active: `SurveillanceDroneSwarm::SA::SurveillanceDroneStatus::Active`: 2 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Active -> Idle` (declaration order) and never `Active -> Recharging`.
- `requirements.coverage` RecallWins: requirement `RecallWins` is satisfied by nothing. Add `satisfy RecallWins by <part-or-function>;` — a requirement def and its usage are counted separately, so satisfy the one that is uncovered.
- `requirements.coverage` ReturnsWhenIsolated: requirement `ReturnsWhenIsolated` is satisfied by nothing. Add `satisfy ReturnsWhenIsolated by <part-or-function>;` — a requirement def and its usage are counted separately, so satisfy the one that is uncovered.
- `requirements.coverage` GeofenceBreachEndsWatch: requirement `GeofenceBreachEndsWatch` is satisfied by nothing. Add `satisfy GeofenceBreachEndsWatch by <part-or-function>;` — a requirement def and its usage are counted separately, so satisfy the one that is uncovered.
- `requirements.coverage` QuarantinedStaysOut: requirement `QuarantinedStaysOut` is satisfied by nothing. Add `satisfy QuarantinedStaysOut by <part-or-function>;` — a requirement def and its usage are counted separately, so satisfy the one that is uncovered.
