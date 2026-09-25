# S33

## What was decided

I would take Alternative 2. Alternative 1 puts every deciding coordination function on groundControlStation, including deconflictMembers and relayLink, which only make sense on the mesh. The result is a ground-hosted catch-all component. The model's own documentation says coordination stops fleet-wide on link or station loss, and that members fly their last directive (localFallbackOnIsolation) with no controlled landing. It accepts that single point of failure as a hazard and misses two targets: groundLinkLoss 0.55 and endurance 20 h. Alternative 2 moves all eight coordination functions onto SurveillanceDrone, with a lowest-id coordinator election, and reduces GroundStation to a gateway for C2 and classifier versions. Coordination, correlation and report holding therefore survive a lost link. Its weaknesses are real and should be fixed at the next layer. The member is overloaded, and the four rules sit on the same MemberMode that detects and coordinates, with no independent monitor. If the ground station fails, the fleet keeps flying with no recall path and no landing policy. Recharge requests reach the ground crew only through groundStation, so the claims of 0.92 coverage with the ground down and 30 h endurance are overstated. coverageLossOnMemberLoss 0.18 is below the duty-cycle floor of about 0.21 and has no mechanism behind it. The two new hazards are 'satisfied' by the components that cause them, and the triple wiring (fleet, memberA, memberB) plus the ring 'so every mesh port is used' pads the model without adding architecture. Even so, Alternative 2's split of responsibilities is the one that survives the next layer.

## Checks

- `check` clear — `npm run check -- /home/xcos/Work/mbse-workflow/runs/v7/build/5_LA.sysml --json`
- `trace-trace` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v7/build/5_LA.sysml --relation trace --json`
- `verify` clear — `npm run sysprose -- verify /home/xcos/Work/mbse-workflow/runs/v7/build/5_LA.sysml --json`

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
