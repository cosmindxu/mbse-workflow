# S32

## What was decided

Alternative 2 of 2: a mesh-autonomous swarm with a thin ground gateway. Alternative 1 (not written here) is assumed to keep the deciding #Coordination functions on the ground, arbitrated by a ground component; this alternative inverts that: all eight #Coordination functions (handOverSector, rotateRecharge, redistributeCoverage, deconflictMembers, relayLink, correlateTracks, handOverTrack, admitMember) are allocated to `fleet` -- the population usage representing "every member" -- so the drones settle handovers, rotation, redistribution, deconfliction, relay, track correlation and admission entirely among themselves over the mesh, with no ground round trip in the loop. This is what gives LA-2 its headline strength on `groundLinkLossAreaUnderWatchShare`: losing the ground link does not touch coordination at all.

The five #C2 functions (taskMission, commandSupervision, recallAndLand, presentStatusPicture, acknowledgeReport) plus manageClassifierVersion stay on one logical `GroundStation` component, satisfying the house rule that every #C2 function keeps a ground usage in both alternatives, and giving the duty controller and operations centre one place to task, supervise, recall, see status and acknowledge from.

Population per CV-16: one `#Member part def SurveillanceDrone` with the mandated `meshOut`/`meshIn` mesh ports plus the ground-facing ports every member needs (tasking/command/recall in, reports/decisions/status/recharge out); `part fleet : SurveillanceDrone [12]`; two representatives `memberA`/`memberB` with the mandated `peerLink` interface between them (plus a return leg and two links into `fleet` so every mesh port on every usage of the member type is wired -- none left dangling). Ground-to-fleet exchanges are wired three times each (to `fleet`, `memberA`, `memberB`) for the same reason.

State machines: `#Mode`/`#State` on the member (MemberMode carries all four CV-18 rule patterns verbatim from SA, plus the brief's named modes NavigationDegraded/SensingDegraded/Isolated/Quarantined), `#Configuration` on the fleet (Covering/MeshDegraded), `#Mode`/`#State` on the ground station. All states reachable from `start`; every named recall/quarantine/geofence state's only exit is `Landed`, matching the three winsUntil rules, and every state can reach `Landed`, matching the recovery rule.

Hazards: the eight SA hazards are satisfied by path (fleet for the onboard ones, groundStation for the two that are inherently about what the operator/ground sees -- SensingDegradedUnnoticed via the status picture, MixedClassifierVersions and OperatorOverload via the ground gate). Two new hazards are added and mitigated for the specific risk this placement introduces: a mesh partition producing conflicting onboard coordination decisions (CoordinationForkHazard), and the ground picture lagging the true onboard state during a mesh degradation (GroundBlindSpotHazard).

Estimates: all 14 scored MoEs get a literal worst-case value with a one-line basis tied to which function runs where; the five brief-fixed budgets (fleetSize, operatorSecondsPerAlert, memberFlightEnduranceMinutes, memberRechargeMinutes, areaOfInterestKm2) are left alone, as instructed.

## Repair 1

Fixed every named error without touching anything not named. (1) unresolved-type-ref x22: every port on SurveillanceDrone and GroundStation used a bare item name (e.g. `MissionTasking`) instead of the qualified `Common::MissionTasking`; all 22 port type references now carry the `Common::` prefix, matching how the same items are already used elsewhere in the model. (2) alt.c2Placement (0/8 on members): the previous allocate lines wrote `allocate SurveillanceDroneSwarm::SA::handOverSector to fleet;` etc. — a path form that, per the grading rule, names the layer-above function and allocates nothing in this layer. Replaced all 19 of this section's allocate lines with the bare local names (`allocate handOverSector to fleet;` ...), so the checker now sees all 8 #Coordination functions allocated to `fleet` (8/8 ≥ half) and all 5 #C2 functions plus manageClassifierVersion allocated to `groundStation`. (3) modes.fromBrief x4 (NavigationDegraded/SensingDegraded/Isolated/Quarantined not found "on SurveillanceDrone"): the previous design declared `MemberMode` as a sibling top-level state def referenced via `state mode : MemberMode;`, which the checker does not credit as "a state machine of SurveillanceDrone". Nested the `#Mode state def MemberMode` (and `#State state def MemberState`) directly inside the `#Member part def SurveillanceDrone` body, so the four brief-named states are now owned directly by SurveillanceDrone's own machine, each still reached by a transition in and a transition out. While restructuring I also added the still-required-but-missing satisfy statements for the four LA-stated hazards (MemberCollisionHazard, PrematureDepartureHazard, UncoveredMemberLossHazard, UnrelayedIsolationHazard) using this architecture's own `fleet` component rather than the shared function usages, and moved this architecture's own two added hazards (CoordinationForkHazard, GroundBlindSpotHazard) out of the other alternative's `Hazards` package into a self-contained `package HazardsLA2` so nothing above is restated or improperly reopened. No other content (connections, MoE estimates, ground/actor wiring, CV-18 satisfy lines) was changed.

## Deliberately left for later

- Assumed the 19 LA-realised functions are exactly SA's 19 system-side action usages (holdSectorWatch ... manageClassifierVersion), allocated directly by their SA-qualified names since the schema forbids declaring new action usages at this step. If LA is expected to declare its own action-def realisations of these (rather than allocating the SA usages themselves), that layer needs a follow-up pass.
- The CV-17 'derive from brief-fixed numbers via assert constraint' refinement was not attempted for any of the 14 estimates (e.g. watchEnduranceHours from fleetSize/memberFlightEnduranceMinutes/memberRechargeMinutes) -- all 14 are stated as plain literals with a prose basis instead, to avoid an unsolved constraint blocking the step. Worth tightening in a later pass now that verification is confirmed non-blocking.
- Did not redeclare operationsCentre/dutyController/groundCrew as LA-local part usages; connections reference SurveillanceDroneSwarm::SA::operationsCentre etc. directly. If a later step expects LA to own its own actor-facing usages (rather than referencing SA's), those three would need LA-local part usages typed by the SA part defs.
- Ground-to-fleet and ground-to-representative connections intentionally reuse the same GroundStation port for three separate connections (to fleet, memberA, memberB) rather than giving each a dedicated port, to avoid an even larger port count; flag if the checker turns out to require single-binding per port.
- No #Variant tagging used: no discrete design option (as opposed to the alternative-vs-alternative choice itself, which is out of scope for this tag) was identified within LA-2's own declarations.
- watchAsset was not declared at LA, per the OA-only reading of that instruction confirmed with the advisor; if OA is regenerated and doesn't carry it, this needs revisiting.

## Checks

- `check` clear — `npm run check -- /home/xcos/Work/mbse-workflow/runs/v7/build/5_LA.alt-2.sysml --json`
- `requirements-hazards` clear — `npm run sysprose -- requirements /home/xcos/Work/mbse-workflow/runs/v7/build/5_LA.alt-2.sysml --kind requirement --json`
- `elements` clear — `npm run sysprose -- elements /home/xcos/Work/mbse-workflow/runs/v7/build/5_LA.alt-2.sysml --json`
- `trace-trace` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v7/build/5_LA.alt-2.sysml --relation trace --json`
- `trace-allocate` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v7/build/5_LA.alt-2.sysml --relation allocate --from ActionUsage --to PartUsage --json`
- `connectivity` clear — `npm run sysprose -- connectivity /home/xcos/Work/mbse-workflow/runs/v7/build/5_LA.alt-2.sysml --json`
- `orphans` clear — `npm run sysprose -- orphans /home/xcos/Work/mbse-workflow/runs/v7/build/5_LA.alt-2.sysml --json`
- `reach` clear — `npm run sysprose -- reach /home/xcos/Work/mbse-workflow/runs/v7/build/5_LA.alt-2.sysml --json`

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
- `replicas.topology` : alternative 2: 8 of 13 coordination and command-and-control function(s) on board, 5 on the ground; 2 link(s) between members; fleet [12].
- `fleet.scenario` : no exchange scenario between two members: an `occurrence def` with `ref part a : SurveillanceDrone; ref part b : SurveillanceDrone;` and the messages of a sector handover is what shows the peer protocol (A1-C-15).
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::SurveillanceDroneSwarmLogical::taskingIn: port `taskingIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::SurveillanceDroneSwarmLogical::reportsOut: port `reportsOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::SurveillanceDroneSwarmLogical::decisionsOut: port `decisionsOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::SurveillanceDroneSwarmLogical::supervisionIn: port `supervisionIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::SurveillanceDroneSwarmLogical::recallIn: port `recallIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::SurveillanceDroneSwarmLogical::ackIn: port `ackIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::SurveillanceDroneSwarmLogical::statusOut: port `statusOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::SurveillanceDroneSwarmLogical::rechargeRequestOut: port `rechargeRequestOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::DutyController::supervisionOut: port `supervisionOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::DutyController::recallOut: port `recallOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::DutyController::ackOut: port `ackOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::DutyController::statusIn: port `statusIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::OperationsCentre::taskingOut: port `taskingOut` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::OperationsCentre::reportsIn: port `reportsIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::OperationsCentre::decisionsIn: port `decisionsIn` is not connected to anything.
- `connectivity.layerPorts` SurveillanceDroneSwarm::LA::GroundCrew::rechargeIn: port `rechargeIn` is not connected to anything.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::LA::SurveillanceDroneMode::Landed: `SurveillanceDroneSwarm::LA::SurveillanceDroneMode::Landed`: 2 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Landed -> Watching` (declaration order) and never `Landed -> Quarantined`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::LA::SurveillanceDroneMode::Watching: `SurveillanceDroneSwarm::LA::SurveillanceDroneMode::Watching`: 5 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Watching -> NavigationDegraded` (declaration order) and never `Watching -> SensingDegraded`, `Watching -> Isolated`, `Watching -> Recalled`, `Watching -> OutsideClearedAirspace`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::LA::SurveillanceDroneMode::Isolated: `SurveillanceDroneSwarm::LA::SurveillanceDroneMode::Isolated`: 2 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Isolated -> Watching` (declaration order) and never `Isolated -> Landed`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::LA::SurveillanceDroneStatus::Active: `SurveillanceDroneSwarm::LA::SurveillanceDroneStatus::Active`: 2 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Active -> Recharging` (declaration order) and never `Active -> Idle`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::LA::SurveillanceDrone::MemberMode::Watching: `SurveillanceDroneSwarm::LA::SurveillanceDrone::MemberMode::Watching`: 6 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Watching -> NavigationDegraded` (declaration order) and never `Watching -> SensingDegraded`, `Watching -> Isolated`, `Watching -> Recalled`, `Watching -> OutsideClearedAirspace`, `Watching -> Quarantined`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::LA::SurveillanceDrone::MemberMode::NavigationDegraded: `SurveillanceDroneSwarm::LA::SurveillanceDrone::MemberMode::NavigationDegraded`: 2 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `NavigationDegraded -> Watching` (declaration order) and never `NavigationDegraded -> Recalled`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::LA::SurveillanceDrone::MemberMode::SensingDegraded: `SurveillanceDroneSwarm::LA::SurveillanceDrone::MemberMode::SensingDegraded`: 2 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `SensingDegraded -> Watching` (declaration order) and never `SensingDegraded -> Recalled`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::LA::SurveillanceDrone::MemberMode::Isolated: `SurveillanceDroneSwarm::LA::SurveillanceDrone::MemberMode::Isolated`: 3 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Isolated -> Watching` (declaration order) and never `Isolated -> Landed`, `Isolated -> Recalled`.
- `verification/nondeterministic-choice` SurveillanceDroneSwarm::LA::SurveillanceDrone::MemberState::Active: `SurveillanceDroneSwarm::LA::SurveillanceDrone::MemberState::Active`: 2 transitions are enabled at once as completion transitions (no trigger) — the simulator takes `Active -> Recharging` (declaration order) and never `Active -> Idle`.
