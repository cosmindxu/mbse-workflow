# S00

## What was decided

The environment reads cleanly into the four quadrants: tasking, supervisory command, recall and acknowledgement come in from the operations centre along with the objects moving through the area; reports, triaged alerts, one track per object, the status picture and the decision record go out; airspace clearance, interference, satellite outage, weather and deception, the fixed camera network that stays, and one operator's attention constrain it; twelve drones, the mesh, the intermittent ground link, the ground station and the 20-minute battery swap supply it. The mission sentence is those four read together, and the function sentence names the state change the whole model exists to make: a tasked area goes from unwatched and unreported to continuously watched and reported.

The system is a population, so the operational entity it takes over is one representative watch asset — the thing the duty controller assigns a sector to, hands a sector over from, re-spreads, deconflicts and relays through today. That is deliberate: those five hand-done activities become the coordination functions the members settle between themselves, and the controller's tasking, command, recall, status picture and acknowledgement become the C2 functions. Splitting them this way is what lets the two candidate architectures — coordination at the ground station, coordination on the drones — be compared on the same functions rather than on different ones.

The measures are the brief's numbers and nothing else. Every figure the brief marks a placeholder is carried as a placeholder so no report can claim the customer asked for it, and every figure the brief FIXES rather than asks the design to achieve — the fleet of twelve, the 40-minute endurance, the 20-minute turnaround, the 18 m/s cruise, the 3.0 km² footprint, the 25 km² area, the operator's 30 seconds, the 120-second stale threshold, and the two test conditions — is a budget: declared, constrained, never scored. The cruise speed matters most of these: with a 25 km² area and 40 minutes of flight, an architecture that puts its recharge point wrong can spend the whole budget on transit, and only a declared speed makes that visible. Only one target is invented — how long the watch holds before it needs people — and its doc says so, because a target nobody asked for can fail every architecture.

Common declares the flows, ports and interfaces in one place so the layers wire rather than invent: one MeshPort in the shape given, carrying a CoordinationMessage that every coordination item specialises, so one peer connection serves handover, rotation, redistribution, deconfliction, relay, correlation, track handover and admission; a member-to-ground port and an operations-centre port that keep the intermittent link and the operator boundary distinct, because one candidate architecture loads the first far more than the other; and clearance, scene and servicing ports so the constraining and supplying environment has somewhere to attach at OA and SA. DetectionReport and Track carry exactly the fields the brief lists, which is why the acknowledgement key sits beside a report rather than inside it.

## Checks

- `check` clear — `npm run check -- /home/xcos/Work/mbse-workflow/runs/v9/build/1_Common.sysml --json`
- `elements` clear — `npm run sysprose -- elements /home/xcos/Work/mbse-workflow/runs/v9/build/1_Common.sysml --json`

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
