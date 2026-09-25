# S31

## What was decided

Filled every TODO left by the skeleton and kept all SA-traced functions allocated to `mainComponent` exactly as the skeleton allocated them (per the checked constraint that functions stay on the placeholder this step). Implemented CV-16's population pattern literally: `#Member part def SurveillanceDrone` carries only ports plus a reference to its own `#Mode`/`#State` machines; `fleet : SurveillanceDrone[12]` carries the count and a `#Configuration` fleet state; `memberA`/`memberB` are two named representatives joined by `peerLink : Common::MeshLink connect memberA.meshOut to memberB.meshIn`. The architecture decision required by the brief (where #Coordination/#C2 sit) is made explicit and tagged `#Variant`: the eight #Coordination functions get a second `allocate ... to fleet;` (in addition to the existing `allocate ... to mainComponent;`, which is never removed) and are given matching action usages inside `SurveillanceDrone` so "every usage sits on a member or the fleet" (onboard, CV-16's on-board test); the five #C2 functions stay solely on `mainComponent`, the ground-facing boundary, since they interface with the ground-side actors already defined. No #Coordination/#C2 function was dropped, renamed without trace, or split away from its SA trace. Added `#Mode`/`#State` machines for the member (`MemberMode`, `MemberOperationalState`) and `#Configuration` for the fleet (`FleetConfiguration`), each with every brief-named mode (NavigationDegraded, SensingDegraded, Isolated, Quarantined, MeshDegraded) reachable from `start`, and embedded the four CV-18 rules (RecallWins, ReturnsWhenIsolated, GeofenceBreachEndsWatch, QuarantinedStaysOut) as `@SysproseVerification::PropertyPattern` blocks inside `MemberMode`, using exactly the q/r/p state names SA already fixed. Added a nested `package Hazards` stating two hazards this layer's split of responsibilities introduces (a single point of failure in peer-carried coordination; ground-link dependence of C2), one mitigated (`redistributeCoverage`) and one `#Accepted` with its reason. All eight SA-named hazards are satisfied by path (never restated) by the LA function or component that actually mitigates each. Added `#Estimate` attributes for all twelve scored measures of effectiveness with a one-line arithmetic/behavioural basis each, plus two `require constraint` blocks capturing the coverage and operator-load arithmetic those estimates rest on. Assumed `package Common` already declares the base `Common::<measure>` attributes (referenced generically by name in the brief and implied by SA's `areaUnderWatchBudget`/`operatorAlertBudget` constraints) and all the item/port/interface types already used by the given skeleton (`Common::MeshPeerPort`, `Common::MeshLink`, `Common::DetectionReport`, `Common::Track`, `Common::TriagedAlert`, etc.), so `commonAdditions` is empty.

## Repair 1

The checker flagged fleet, memberA and memberB as components — this step writes functions only, allocated to the single placeholder mainComponent; splitting into logical components (and instantiating the CV-16 population as a fleet usage plus two representative peers) is the next step's job. I removed the three usages and the peerLink interface that joined memberA/memberB, along with the now-dangling `allocate <fn> to fleet;` lines for the eight #Coordination functions (each keeps its `allocate <fn> to mainComponent;`, so no #Coordination function is lost). I redirected the two `satisfy ... by fleet;` hazard mitigations (PositionDriftHazard, SensingDegradedUnnoticedHazard) to `by mainComponent`, since `fleet` no longer resolves. I kept the #Member part def SurveillanceDrone, MemberMode, MemberOperationalState and FleetConfiguration as the CV-16 population definition/state defs — they are definitions, not component usages, so they don't trip the functions-only rule — and reworded their docs (and the coordinationAllocationDecision, fleetFact and PeerCoordinationSinglePointHazard docs) to say the fleet/representative instantiation is deferred to the next step rather than claiming it already exists here. Everything else — functions, traces, estimates, verification constraints, hazards and their satisfy statements — is unchanged, since the checker said to change only what it named. The unevaluable numeric constraints were reported as non-blocking ("It never blocks you"), so left untouched.

## Deliberately left for later

- Decomposing mainComponent into several distinct logical sub-components (sensing/nav/comms/etc.) is intentionally left for the next step, which is meant to do this several ways and compare; only the population (fleet/memberA/memberB) and the allocation-to-fleet-vs-ground decision were introduced here.
- watchEnduranceHoursWithoutPeople is estimated at 10h, short of the 12h working target, because RechargePointAndBatterySwap still needs GroundCrew presence; flag this gap for the customer conversation the brief itself calls for.
- The #Estimate values are basis-level engineering judgement, not a simulated coverage/queueing model; PA should recompute them once physical drone/sensor/radio choices are fixed.
- Confirmed by assumption rather than by reading Common directly: Common::<measure> base attributes for all twelve scored MOEs already exist (implied by SA's areaUnderWatchBudget/operatorAlertBudget constraints). If a later check reports ref/unresolved-reference on any Common::<measure>, those base attribute defs need adding to Common.

## Checks

- `check` clear — `npm run check -- /home/xcos/Work/mbse-workflow/runs/v8/build/5_LA.sysml --json`
- `requirements-hazards` clear — `npm run sysprose -- requirements /home/xcos/Work/mbse-workflow/runs/v8/build/5_LA.sysml --kind requirement --json`
- `elements` clear — `npm run sysprose -- elements /home/xcos/Work/mbse-workflow/runs/v8/build/5_LA.sysml --json`
- `trace-trace` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v8/build/5_LA.sysml --relation trace --json`
- `trace-allocate` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v8/build/5_LA.sysml --relation allocate --from ActionUsage --to PartUsage --json`

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
- `functions.coordination` SurveillanceDroneSwarm::LA::handOverSector: `handOverSector` is coordination between members and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.coordination` SurveillanceDroneSwarm::LA::rotateRecharge: `rotateRecharge` is coordination between members and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.coordination` SurveillanceDroneSwarm::LA::redistributeCoverage: `redistributeCoverage` is coordination between members and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.coordination` SurveillanceDroneSwarm::LA::deconflictFlight: `deconflictFlight` is coordination between members and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.coordination` SurveillanceDroneSwarm::LA::relayThroughNeighbour: `relayThroughNeighbour` is coordination between members and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.coordination` SurveillanceDroneSwarm::LA::correlateTracks: `correlateTracks` is coordination between members and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.coordination` SurveillanceDroneSwarm::LA::handOverTrack: `handOverTrack` is coordination between members and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.coordination` SurveillanceDroneSwarm::LA::admitMember: `admitMember` is coordination between members and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.c2` SurveillanceDroneSwarm::LA::taskSurveillanceMission: `taskSurveillanceMission` is command and control and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.c2` SurveillanceDroneSwarm::LA::issueSupervisoryCommand: `issueSupervisoryCommand` is command and control and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.c2` SurveillanceDroneSwarm::LA::recallToLand: `recallToLand` is command and control and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.c2` SurveillanceDroneSwarm::LA::presentStatusPicture: `presentStatusPicture` is command and control and nothing flows into or out of it. What does it receive, and what does it decide for whom?
- `functions.c2` SurveillanceDroneSwarm::LA::acknowledgeDetectionReport: `acknowledgeDetectionReport` is command and control and nothing flows into or out of it. What does it receive, and what does it decide for whom?
