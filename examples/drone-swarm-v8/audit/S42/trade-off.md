# PA architecture trade-off

**Chosen: alternative 1**

## Score

| Alternative | Total | Measures | Review | Structure | Resilience |
|---|---|---|---|---|---|
| 1 | 0.817 | 1.00 | 0.50 | 0.86 | 0.19 |

## Command and control

| Alternative | Coordination and C2 on board | Links between members | Fleet | Hazards accepted |
|---|---|---|---|---|
| 1 | 2/13 | 1 | [12] | 0 |

## Measured

| Alternative | Elements | Connections | Unconnected ports | Unused defs | Functions realised | Repairs | Hazards accepted |
|---|---|---|---|---|---|---|---|
| 1 | 2009 | 197 | 37 | 4 | 17/17 | 1 | 0 |

## Measures of effectiveness

Each value is the worst case the solver finds over the alternative's own `#Estimate` — a claim the architecture makes, not a measurement.

| Alternative | Measure | Worst case | Target | Met |
|---|---|---|---|---|
| 1 | `areaUnderWatchFraction` | 0.96 (derived) | ≥ 0.9 | yes |
| 1 | `watchEnduranceHoursWithoutPeople` | 18 hours | ≥ 12 hours | yes |
| 1 | `reportDeliveryLatencySeconds` | 45 seconds | ≤ 60 seconds | yes |
| 1 | `positionErrorAfterGnssLossMetres` | 35 metres | ≤ 50 metres | yes |
| 1 | `coverageUnderMeshJammingFraction` | 0.816 (derived) | ≥ 0.75 | yes |
| 1 | `reportHoldDurationMinutes` | 45 minutes | ≥ 30 minutes | yes |
| 1 | `missedDetectionFraction` | 0.08 | ≤ 0.1 | yes |
| 1 | `falseAlarmsPerHour` | 1.5 alerts per hour | ≤ 2 alerts per hour | yes |
| 1 | `alertsReachingOperatorPerHour` | 18 alerts per hour | ≤ 20 alerts per hour | yes |
| 1 | `acknowledgedReportsThatMatterFraction` | 0.85 | ≥ 0.8 | yes |
| 1 | `coverageDropAfterMemberLossFraction` | 0.125 (derived) | ≤ 0.25 | yes |
| 1 | `onboardClassifierCostUsdPerDrone` | 220 USD | ≤ 300 USD | yes |

## Review

Only one alternative was supplied — the prompt contains a single PA package ("Alternative 1", ground-centred) — so this is an absolute assessment, not a comparison; the recommendation is forced by that absence. The split is coherent as a ground-centred design: `localDeconflict` and `relay` are correctly left on board as the two latency-intolerant functions, the airframe is uniform and cheap to procure, and `GroundStationNode` is a clean procurement item. Its weakness is concentration. `groundStation.coordinator` bundles six unrelated concerns (sector handover, recharge rotation, coverage redistribution, track correlation, track handover, admission — fleet resource management, track fusion and security in one part), and `GroundStationNode` holds seven functions with no redundancy. The decisive finding: `coverageDropAfterMemberLossFraction = 0.125` is derived "before `redistributeCoverage` re-spreads the rest", and `redistributeCoverage` lives on `groundStation.coordinator` — the coverage-restoration measure is met only by the component whose loss the model names as `GroundCoordinatorSinglePointHazard`, which it then "satisfies by fleet" even though the allocation block puts nothing but `deconflictFlight` and `relayThroughNeighbour` on the fleet. That hazard is accepted, not mitigated, whatever the count says. The flight rules are satisfied `by fleet` and carried on `SurveillanceDrone`'s own state machines — the same article that holds `sense` and `classify` — with no independent monitor (`computeWatchdog` restarts crashed processes; its doc never says it overrides anything). Two estimates have bases the model contradicts: the $220 onboard cost is justified by keeping classification on the ground while `ClassifyFunction`, `detectAndClassify` and the `MisclassificationHazard` satisfy are all on board; and 0.96 coverage needs eight 3 km² footprints to be disjoint across 25 km² with no transit time charged against the 40-minute endurance.

### Alternative 1

- **cohesion** 3/5 — Node/function nesting is clean and most member parts have exactly one job (`sense`, `navigate`, `reportHold`, `relay`). But `GroundCoordinatorFunction` is a six-concern bundle — fleet resource management (`handOverSector`, `rotateRecharge`, `redistributeCoverage`), track fusion (`correlateTracks`, `handOverTrack`) and admission/security (`admitMember`) in one part — and `GroundC2Function` puts safety-critical `recallToLand` alongside routine `taskSurveillanceMission` and `acknowledgeDetectionReport`. The four never-broken rules are satisfied `by fleet`, i.e. by `SurveillanceDrone`'s own `MemberFlightState`/`MemberMode`, the same article that detects and classifies; there is no separate monitor whose doc states what it overrides.
- **coupling** 2.5/5 — Eleven of thirteen coordination/C2 functions are on the ground, so every sector handover, recharge rotation, coverage redistribution, track correlation and admission decision crosses `groundLinkConn` — the boundary the model itself documents as "not always available". The mesh, the more available link in a contested setting, carries only deconfliction and relay. Topology is under-modelled: one `groundLinkConn` to a multiplicity-12 `fleet`, one `peerLink` between `memberA`/`memberB` which sit outside `fleet[12]`, and 37 unconnected ports. `QuarantinedStaysOut` is cross-boundary coupled — `Quarantined → Readmitted` cannot fire without `groundStation.coordinator.admitMember`.
- **realisability** 3/5 — The procurement split is genuinely buildable as two items: one replicable airframe and one fixed ground installation. Against that: the $220 onboard-classifier basis describes classification authority on the ground while the model allocates `ClassifyFunction`, `detectAndClassify` and `MisclassificationHazard` mitigation on board; 0.96 coverage requires 24 km² of footprint to fall essentially disjoint across 25 km² with no transit charged against endurance, leaving no margin over the 0.9 target; `meshCoordinationDependencyFraction = 0.3` is an asserted constant, not derived; `watchEnduranceHoursWithoutPeople = 18` claims battery swaps are the only human touch in an architecture that routes all C2 through an attended ground station. `SurveillanceDroneSwarmPhysical` still says "TODO: decompose" and all seventeen action defs carry "TODO: how X is realised at PA".
- **evolvability** 3.5/5 — Centralisation pays here: decision logic, reporting threshold and `classifierRegistry` change in one place with no fleet-wide software campaign, and `MixedClassifierVersionsHazard` has a real owner. Triage rules can be retuned without touching an airframe. The cost is asymmetric: any requirement for longer link-outage tolerance or contested comms forces six functions off `groundStation.coordinator` onto members whose compute is costed as a "lightweight feature extractor", and growing the population past twelve concentrates further on one coordinator and one modelled ground link.
- **groundLinkLossResilience** 2/5 — What survives an outage: `sense`, `classify`, `navigate`, `localDeconflict`, `relay`, and `reportHold` at 45 minutes against the 30-minute target — data is genuinely not lost, and `MemberFlightState`'s `Recovering → Landed` plus `ReturnsWhenIsolated` keep it safe. What stops: all six deciding coordination functions and all five C2 functions. Members fly their last assignment; no re-tasking, no track correlation, no admission, no recall from the ground, and `rotateRecharge` — the function that sustains the eight-airborne steady state behind the 0.96 figure — has no onboard fallback. `MemberMode` has an `Isolated` state but no degraded coordination behind it; `FleetConfiguration::MeshDegraded` answers mesh loss with "largely from the ground" and offers no symmetric answer. `GroundLinkRadioDropHazard` is mitigated by `relay`, which covers one member's radio failing, not the ground link going down.
- **groundNodeLossResilience** 1.5/5 — Losing `GroundStationNode` takes `coordinator`, `c2`, `triage`, `decisionRecord`, `statusPicture`, `classifierRegistry` and `mapsStore` simultaneously; the model instantiates exactly one `groundStation` with one `groundRadioUnit` and no standby. Held against the coverage-restoration measure it fails outright: `redistributeCoverage`, the basis for `coverageDropAfterMemberLossFraction = 0.125`, is inside the lost node, so after the ground goes, a subsequent member loss is never re-spread. Members fly their last assignment and land safely on endurance, so the accepted hazards on the safety side hold, but the mission ends. Credit for naming `GroundCoordinatorSinglePointHazard` explicitly; no credit for `satisfy ... by fleet`, which the allocation block contradicts — the fleet holds only `deconflictFlight` and `relayThroughNeighbour`.
