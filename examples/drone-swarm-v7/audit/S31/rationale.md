# S31

## What was decided

Kept every SA-derived allocation (`allocate … to mainComponent/operationsCentre/dutyController/groundCrew/fixedCameraNetworkOwner/analysts`) and every `trace` exactly as the skeleton had them, per the checker's "functions only: every function stays allocated to the placeholder component the skeleton provides" rule — the where-should-Coordination/C2-land decomposition is deliberately left to the next step, which will compare several allocations. This step's own architecture decision is scoped to the population: fleet/memberA/memberB/peerLink are instantiated per CV-16, but no new function allocations were added onto them, so nothing about the counting rule for #Coordination/#C2 (“on board when every usage sits on a member or the fleet”) is disturbed either way — that comparison starts clean next step.
Filled every remaining TODO doc (actors, action defs, the logical placeholder) with LA-appropriate text that still names which SA function/use case it realises, keeping doc coverage high without touching the parts of the skeleton that already worked (action usages, allocate, trace, flow — all copied verbatim).
Added the population per CV-16 exactly as specified: one #Member part def SurveillanceDrone (ports already given), `part fleet : SurveillanceDrone [12]`, two named representatives memberA/memberB, and a bidirectional peer link (peerLink + peerLinkReturn, since a single one-way interface would leave memberA.meshIn/memberB.meshOut dangling under the interfaces option — mesh radio is inherently bidirectional).
Gave the member its own #Mode/#State machines carrying all four SA rules verbatim (same q/r/p strings as SA), with a transition graph in which every one of the eight named states is reachable from `start` and every state has a path back to Landed (satisfying ReturnsWhenIsolated's "recovery/globally" pattern) while Recalled, OutsideClearedAirspace and Quarantined each have Landed as their only successor (satisfying the three "absence/between" rules). Satisfied all four SA rule requirements by `fleet` (the population usage of the type the requirement's subject names).
For mainComponent, CV-16 says fleet-level states are `#Configuration`, but this run's modes-and-states option wants `#Mode`+`#State` on every stateful element; rather than guess whether tag-stacking (`#Mode #Configuration state def X`) parses, I declared two structurally identical state defs (SwarmMode tagged #Mode, FleetConfiguration tagged #Configuration) plus SwarmStatus tagged #State, and gave mainComponent all three state usages — redundant but unambiguous and low-risk.
Added the 8 part-level connections SA had (actor↔system) since the skeleton only carried action-level flows, leaving all 8 mainComponent ports and the actor ports otherwise unconnected under the interfaces option.
Added 14 `#Estimate` attributes (all scored MOEs, excluding the 5 brief-fixed budgets) inside the logical component, each with a value and a one-line basis grounded in a named LA function, per CV-17.
Re-satisfied all 8 SA hazards by the LA function whose doc already named that mitigation (several SA docs state the mitigation explicitly — relayLink "mitigating mesh jamming", admitMember "mitigating spoofed members", correlateTracks "to avoid duplicates and stale tracks" — so those mappings are load-bearing, not guessed), using the fully qualified `SurveillanceDroneSwarm::SA::Hazards::<name>` path. Added 4 new hazards in a nested `package Hazards` under names SA doesn't use, each visible only because the population is now instantiated (member-to-member collision, premature departure before handover, coverage gap on member loss, an isolated member no peer can relay for), each satisfied by the coordination function that addresses it.

## Repair 1

The checker flagged `fleet`, `memberA` and `memberB` as components — this "functions only" step must not place any part usage besides `mainComponent`; the split into logical components (including instantiating the population) is the next step's job. I removed those three part usages plus the `peerLink`/`peerLinkReturn` interfaces that connected them (their ends no longer exist), and reallocated by updating the four `satisfy ... by fleet;` statements to `by mainComponent;` so CV-18's SA rule-satisfaction references still resolve to a component that exists in this layer. The `#Member part def SurveillanceDrone` (the replicable element's definition, per CV-16) is kept — it is a definition, not a placed component, so it is not what the checker flagged, and it is still needed as the `subject` type for the four LA-added hazards in `package Hazards`, and as the type the next step will instantiate. Rewrote the `fleetFact` prose and the `Hazards` package doc, which had described the now-removed usages, so they accurately describe that the population's fleet usage, representative pair and peer interface are deferred to the next step while every function (including all eight `#Coordination` and five `#C2` actions) stays allocated to `mainComponent`, satisfying "no #Coordination or #C2 function is lost". No new Common types were needed, so `commonAdditions` is empty. The "not blocking" constraint-evaluation warnings reference attributes/lines outside what this fix targets and were left untouched per the instruction to change only what the blocking findings name.

## Deliberately left for later

- Which of the #Coordination/#C2 functions actually move onto the fleet/representatives ("ground or members") is left for the next step; this fragment keeps them all on mainComponent as the skeleton had them so the comparison starts from a clean, unmodified baseline.
- groundLinkLossAreaUnderWatchShare (0.9) is estimated on the assumption that Coordination functions end up allocated onboard next step; if a later architecture keeps them ground-side instead, this estimate needs revising down.
- watchAsset (the operational entity the system takes over) is an OA-layer declaration per the brief; not redeclared here since OA's content wasn't provided to this step and re-guessing its exact path risks an unresolved reference.
- Did not add individual docs to every inherited SA-typed port on mainComponent/actors (taskingIn, reportsOut, etc.) or to the ~24 action usages/flows, to avoid touching skeleton text that already satisfied the checker; if doc_coverage_min is stricter than assumed, those are the next things to annotate.
- MergeWithCameraNetworkTracks, ViewStatusPicture, ServiceAndRecharge, ProvideCameraTracks and JudgeAlerts are left as actor-side pass-throughs, unchanged from SA in substance — not decomposed at LA since they belong to actors outside the system boundary.

## Checks

- `check` clear — `npm run check -- /home/xcos/Work/mbse-workflow/runs/v7/build/5_LA.sysml --json`
- `requirements-hazards` clear — `npm run sysprose -- requirements /home/xcos/Work/mbse-workflow/runs/v7/build/5_LA.sysml --kind requirement --json`
- `elements` clear — `npm run sysprose -- elements /home/xcos/Work/mbse-workflow/runs/v7/build/5_LA.sysml --json`
- `trace-trace` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v7/build/5_LA.sysml --relation trace --json`
- `trace-allocate` clear — `npm run sysprose -- trace /home/xcos/Work/mbse-workflow/runs/v7/build/5_LA.sysml --relation allocate --from ActionUsage --to PartUsage --json`

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
