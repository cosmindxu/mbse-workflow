# S00

## What was decided

The brief describes a population, not a single system: twelve identical drones that settle eight named matters with each other over a mesh that is deliberately independent of the ground link. That independence is the whole point of the architecture decision, so the mesh peer port and its interface are declared in Common in the mandated shape and every member is wired through them from LA down; collapsing the swarm into one instance would make the decision unaskable. The operational entity the system takes over is one representative watch asset — today a crewed sortie flown to a sector under a duty controller's hand-made plan — which is why the controller's eight coordination activities become the coordination functions and the operations centre's five become the C2 functions.

Hazards, rules, modes and items are exactly those the brief names and no more: the eight known hazards go to SA::Hazards once and are satisfied by path below; the four rules are all carried by one member's state machine, since each is about what a single drone does after recall, geofence breach, isolation or quarantine; MeshDegraded is the only fleet-level mode. DetectionReport and Track carry exactly the fields the brief lists and nothing else, so a layer cannot quietly add an identifier to make its own life easier — acknowledgement therefore carries its own reference field and is documented as doing so.

On the measures: every target that the brief states is taken from the brief, and every number it marks as awaiting the customer is flagged as a placeholder so no report can claim a design has met a customer requirement. Three numbers the brief fixes rather than asks for — the fleet of twelve, the operator's 20 alerts an hour and 30 seconds each — are budgets, declared and never scored. The cruise speed is declared as a budget because the brief gives it (18 m/s) and because endurance and area alone cannot say whether a drone reaches its sector and returns: transit out and back is paid from the same forty minutes as the watching, and a model without the speed would let an architecture spend its whole flight budget on the return leg. Only watchEnduranceHoursWithoutPeople has a target nobody asked for; its doc says so.

Common holds definitions only, so it declares no state machines and no hazards of its own: modes, states and layer hazards belong where there are parts to carry and mitigate them. The ports declared here are the ones the layers will actually wire — mesh, ground link, operations link, airspace, ground service, sensor feed and navigation feed — so that the interfaces check does not report a port that connects to nothing.

## Checks

- `check` clear — `npm run check -- /home/xcos/Work/mbse-workflow/runs/v8/build/1_Common.sysml --json`
- `elements` clear — `npm run sysprose -- elements /home/xcos/Work/mbse-workflow/runs/v8/build/1_Common.sysml --json`

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
