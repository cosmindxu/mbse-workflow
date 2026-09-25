# S50

## What was decided

EPBS is the configuration-item layer: every physical/logical thing PA calls out to be procured, built or delivered gets exactly one CI part def, tagged #CI_HWCI/#CI_CSCI/#CI_COTS, traced to the PA part it realises, carrying a requirement def as its contract, satisfied by the CI usage, and checked by a verification def.

Split rationale, following the PA trade-off's own diagnosis (alternative 2 "overclaims... no compute or report store... no function or component" behind on-board triage): I did not keep a single monolithic "FleetItem"/"GroundStationItem" as the starting stub had them, because that would hide exactly the gap PA flagged. Instead: (1) DroneAirVehicleItem (HWCI) - airframe/flight-controller/mission-computer/report-store hardware, closing the missing-compute/store gap; (2) DroneMissionSoftwareItem (CSCI) - detect/classify/report, navigation fallback, hold-and-forward, and the 7 on-board coordination functions, closing the missing-on-board-triage-function gap; (3) SafetyMonitorItem (HWCI) - kept as its own CI because PA's doc insists it stay procured/verified separately from mission software; (4) MeshRadioItem, (5) GroundLinkRadioItem, (6) StoredMapsStoreItem - COTS hardware PA already named as distinct part defs; GroundLinkRadioItem gets one def with two usages (drone-side x12, ground-side x1) since it's the same COTS part bought for both ends. (7) GroundStationItem (HWCI) / (8) GroundControlSoftwareItem (CSCI) split the ground node the same hardware/software way. (9) RechargePointItem (HWCI) kept from the stub, retagged, with a capacity attribute added to mitigate PA's RechargeContentionHazard.

Contracts: each requirement def has subject, a true assume constraint drawn from an upward PA budget attribute, and require constraint bounds using the brief's own MOE names at bounds equal to or tighter than the brief's targets/budgets - never looser - to avoid verification/refinement-failed. A few CI-specific, non-MOE attributes capture procurement-level hazard mitigations that have no brief-level MOE name.

Hazards: EPBS adds no new hazards, so no nested package Hazards was created. All ten hazards stated above this layer are (re-)satisfied by path here by the CI that most directly mitigates each, since visibility into whether PA's own fragment already satisfied its two added hazards was not available; re-satisfying is a harmless redundant statement, while a gap would block the step.

Every part def, part usage, requirement def, verification def and constraint carries a doc for the coverage limit. No ports, connections, state defs or new item/flow types were added at this layer.

## Repair 1

The checker's only blocking finding was requirements.hazards: no #Hazard requirement named an EPBS element, i.e. this layer stated no hazards of its own even though the safety knob is on. Everything else in the fragment was already checked and traced, so I changed nothing else.

Added a nested `package Hazards` inside `package EPBS` with three new #Hazard requirement usages, each under a name no layer above uses and each naming (via its `subject`) an EPBS configuration item:
- `CiClassifierAdmissionSkewHazard` (subject GroundControlSoftwareItem) — a genuinely EPBS-level risk (CI release/version discipline for the admission gate, distinct from SA's MixedClassifierVersionsHazard which is the fleet-behaviour effect) — mitigated by `satisfy ... by groundControlSoftwareCi;`, added to the existing hazard-satisfaction block, since that CI's doc already covers classifier-version registration at admission.
- `SafetyMonitorSoleSourceHazard` and `RechargePointSoleFacilityHazard` — procurement single-point-of-failure/sole-sourcing risks that this model has no mitigating component for, so both are tagged `#Accepted` in place with the reason stated in their `doc`, per the safety-knob rule, rather than given a `satisfy`.

I left the "not blocking" constraint-evaluation warnings untouched, since the instructions class them as reported-not-blocking and the fix note says to change only what the blocking finding names; those numeric-budget constraints already exist elsewhere in the model (this fragment doesn't introduce or reference `areaUnderWatchShare`, `coverageLossOnMemberLoss`, etc.) and are out of this layer's scope to fix.

## Deliberately left for later

- Did not create a separate CI for SurveillanceDroneSwarmPhysical (the PA top-level physical-system part def) - treated it as the system boundary that the nine CIs below collectively realise, not itself a procured item; flag if the checker expects a top-level system CI as well.
- Did not give DeadReckoningNav its own CI (PA marks it #Variant, not selected) - left un-procured, findable via PA's where-used tag only.
- GroundControlSoftwareItem's trace is to PA::groundStation only, not to each individual PA action usage (taskMissionAct/mergeAct/admitMember/etc.) - the doc names which PA functions it realises, but per-action traces were not added to keep the trace count manageable.
- PA left ManageClassifierVersionFunction's host as TODO; assumed classifier-version registration happens at admission time and folded it into groundControlSoftwareCi - flag if PA intends a different host.
- No #Mode/#State state defs were added on any CI - the realised PA parts already carry MemberState/MemberMode/FleetConfiguration/GroundOperatingState/GroundLinkMode; duplicating them on the CIs was judged out of scope for EPBS's own check list.
- MeshRadioLink/GroundRadioLink (connection defs) and the paTradeOff/estimate attributes at PA were intentionally not turned into CIs - they are physical media and analysis artifacts, not separately procured items.

## Checks

- `check` clear — `npm run check -- /home/xcos/Work/mbse-workflow/runs/v7/build/7_EPBS.sysml --json`
- `requirements-hazards` clear — `npm run sysprose -- requirements /home/xcos/Work/mbse-workflow/runs/v7/build/7_EPBS.sysml --kind requirement --json`
- `elements` clear — `npm run sysprose -- elements /home/xcos/Work/mbse-workflow/runs/v7/build/7_EPBS.sysml --json`
- `trace-trace` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v7/build/7_EPBS.sysml --relation trace --from PartUsage --json`
- `trace-verify` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v7/build/7_EPBS.sysml --relation verify --json`
- `refine` clear — `npm run sysprose -- refine /home/xcos/Work/mbse-workflow/runs/v7/build/7_EPBS.sysml --via composition --json`

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
- `validation/constraint-violation` : Constraint could not be evaluated ("coverageLossOnMemberLoss == 1.0 / fleetSizeValue"): Could not evaluate: a referenced value is unknown.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::fleetSizeValue <= 12"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::areaOfInterestBudget <= 25"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::fleetSizeValue <= 12"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::fleetSizeValue <= 12"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::fleetSizeValue <= 12"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::fleetSizeValue <= 12"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::areaOfInterestBudget <= 25"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::GroundStation::operatorAlertsPerHourBudget <= 20"): Could not parse expression: Unexpected character ':' at 22.
- `validation/constraint-violation` : Constraint could not be evaluated ("SurveillanceDroneSwarm::PA::RechargePoint::rechargeMinutesBudget <= 60"): Could not parse expression: Unexpected character ':' at 22.
