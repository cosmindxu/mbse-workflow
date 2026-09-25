# S42

## What was decided

I would take alternative 2, on condition that its physical breakdown is filled in. The whole decision is where coordination lives. Alternative 1 puts all seven deciding coordination calls in groundStation.swarmCoordinator and formally accepts the consequence (GroundCoordinatorLossHazard): when the link or ground node is lost, drones fly their last assignment, rotation stops, and nothing plans a landing. Its own estimate of 0.55 coverage misses the 0.9 target, and it is optimistic, because with 40-minute flights and no recharge rotation coverage falls toward zero after one sortie. Alternative 2 moves those decisions onto the drones and gives each drone a real SafetyMonitor, separate from detection and classification. That keeps coverage and recall working through a ground outage. What still stops is admission, classifier-version control and any defined limit on flying unsupervised. Alternative 1 is the better model of hardware: missionComputer, reportStore, flightController and a ground ReportTriage can be bought and hosted, and its coverage-loss-per-drone figure (0.25) is honestly derived. Alternative 2 overclaims. Its 'on-board triage' behind the operator-workload estimates has no function or component, it has no compute or report store, and 1/12 coverage loss ignores that only about 4–5 drones are airborne at once. That is why alternative 2 scores low on realisability. Those gaps can be fixed by adding parts in the next layer. Alternative 1's weakness would mean re-architecting.

## Checks

- `check` clear — `npm run check -- /home/xcos/Work/mbse-workflow/runs/v7/build/6_PA.sysml --json`
- `trace-trace` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v7/build/6_PA.sysml --relation trace --json`
- `verify` clear — `npm run sysprose -- verify /home/xcos/Work/mbse-workflow/runs/v7/build/6_PA.sysml --json`

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
