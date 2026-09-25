# Where this stands, and what comes next

Last worked 2026-09-17: the v7 run finished — the brief's hazards, modes, rules and items carried by name from SEED to PA, every carried rule holding.
Everything below is on disk and committed; nothing is mid-flight.

## State

| | |
|---|---|
| Tests | 265 passing (`npm test`), typecheck clean |
| Calibrated against | Sysprose `91cc4a5` (`config/workflow.yaml: sysprose.expected_commit`) |
| Complete runs | `examples/drone-swarm-v7/` (sensing, links, oversight and rules the swarm never breaks). v1–v3 live in git history under tag `runs-v1-v3`, v4 under `runs-v4`, v5 under `runs-v5`, v6 under `runs-v6` |
| Scratch | `runs/` is gitignored; a run worth keeping is copied into `examples/` |

## What v7 produced (2026-09-17)

The article's lessons for a watch-and-report swarm (FT, "The era of AI warfare
has arrived"; weapons and interception stay out of scope, word for word), from
SEED. `examples/drone-swarm-v7/`; start at `audit/final/README.md`.

| | v6 | **v7** |
|---|---|---|
| Brief | 983 words | **1,823**: interference, no satellite positioning, degraded sensing, triage, decision record, 8 hazards, 5 modes, 4 rules |
| CLI witness | clean, 26 diagnostics | **clean, 29** |
| Requirements satisfied | 26/29 | **30/32 — the 2 open are accepted hazards** |
| Realization OA→SA→LA→PA→EPBS | 47, 21, 21, 4 | **44/44, 28/28, 28/28, 5/5** |
| Scored measures | 6 | **14, all decided at LA and PA; 5 budgets held, not scored** |
| LA trade-off | 0.60 vs 0.94 | **0.67 vs 0.90** (ground-centric misses link-loss coverage and endurance) |
| PA trade-off | 0.53 vs 0.89 | **0.75 vs 0.88** |
| Behaviour sweep | 22 of 31 recoverable | **20 of 20 hold: 5 machines carry the brief's rules, 15 recover** |
| Doc coverage | LA 96 %, PA 97 % | **100 % on every layer but Common (97 %)** |
| Cost | 50.93 USD, 22 calls | **40.43 USD, 21 calls** (+ a 2.24 USD smoke call); longest call 952 s |

What worked first time: SEED extracted all four new brief fields exactly (8
hazards, 4 rules with the right kinds, 5 modes, 3 items), and SA's first answer
stated and carried every rule and hazard — no new gate fired at S21.

What v7 exposed, and where it stands:

- **Rules and modes left the member.** The transitions copy a layer's state
  machines to package level, so both LA and PA alternatives first carried the
  rules on a machine the member does not own; 1–2 repair rounds each moved them.
  Fixed in the gate for the legitimate shape (`state mode : MemberMode` in the
  member, def in the package — 1e4e249); the transition itself still moves them.
- **Path allocations survived the prompt.** A PA alternative allocated 19
  functions by their LA path after being told not to. The composer now rewrites
  such a path when this layer has the function (9babce0); untested live.
- **"State the hazards this layer adds" met "every layer states one".** EPBS's
  first answer stated none and `requirements.hazards` blocked it once.
- **The sweep read a machine in the wrong layer** (PA's FleetConfiguration checked
  against LA's states) — fixed, and the kept audit regenerated (e0d009c).
- **A leg-budget stop would have landed mid-S32**, so leg 1 was stopped by hand at
  S31's first seconds; the killed call is not in the log.

## What v6 produced (2026-09-17)

From SEED on the brief that now states 12 drones and the coverage the customer
needs. Kept under tag `runs-v6`; start at `audit/final/README.md`.

| | v5 | **v6** |
|---|---|---|
| CLI witness | clean, 6 diagnostics | **clean, 26** |
| Requirements satisfied | 48/49 | **26/29 — the 3 open are accepted hazards** |
| Realization OA→SA→LA→PA→EPBS | 34/34 … | **47/47, 21/21, 21/21, 4/4** |
| LA trade-off (total) | 0.33 vs 0.67 on measures | **0.60 vs 0.94; measures 0.67 vs 1.00** |
| PA trade-off (total) | 0.50 vs 0.67 on measures | **0.53 vs 0.89; measures 0.58 vs 1.00** |
| Coordination and C2 on board, PA | 2/10 vs 10/10 | **0/10 vs 5/10 — C2 stays on the ground** |
| Hazards accepted by the chosen PA | — | **0 (alt-1 accepted 2, structure −0.10)** |
| Repair rounds per alternative | several | **1 each, at S32 and S41** |
| Cost | ~54 USD recorded, 3 legs | **50.93 USD in the call log, 22 calls** (43.52 recorded by the legs, see below) |

What each piece of the plan showed, live:

- **Brief targets** — every measure's target came from the brief; `## Measures`
  flags no unreachable target.
- **Measures weight** — LA alternative 1 missed `coverageDropOnLossRatio` (0.30)
  and `linkGapCoverageRatio` (0.70); the choice followed.
- **Derived estimates** — `coverageDropOnLossRatio` 0.2083 and `fleetSize` 12,
  both `(derived)`, at LA and PA.
- **Component mitigation** — the first S32 answer blocked on 4 hazards (v5's
  answers would have blocked on 12–13); each cleared with one repair.
- **Acceptance penalty** — shown and applied in both trade-offs.
- **Bearer** — `#Node part def MeshRadio` at PA, typed links `MeshLink` /
  `MeshRadioChannel`.
- **Bonus lane** — behaviour sweep over 31 machines: 22 recoverable, 2 OA
  machines undecided (their triggers are offered everywhere), 7 EPBS lifecycles
  with nothing to check. Fault tree: 29 contracts, none with a top event, so no
  cut sets (exit 2 = nothing to analyse).
- **Timeout** — no call killed at 1800 s; the longest took 896 s.

### What v6 exposed, all fixed (47bacf9, f252520, b22b213)

- **A repair threw away an alternative's hazards.** `build` merges the answer's
  `package Hazards` into the head's, above the section marker; the repair
  `extract` read only below it. On its first repair S32's alternative 2 "removed"
  a hazard and lost every `satisfy … by <part>`. The first leg was stopped at that
  point and resumed from S32; `nestedAdditions` recovers them now.
- **The merge duplicated restated hazards** — 10 duplicate names in `LA::Hazards`
  after the fix above; merged bodies are now deduped against the head's package.
- **The same hazard name at SA, LA and PA is three hazards.** `satisfy X by p;`
  answers only the nearest (probed: `SA::Hazards::X` clears SA's alone). Prompt and
  gate message now name hazards by layer path.
- **Sysprose withholds a derived bound it cannot reproduce in floating point.**
  `r == (1.0 / n) * (1.0 + m)` false at the solver's rational point ⇒
  `verification/not-evaluable` for every measure the equation reaches. PA
  alternative 1 cleared the gate with value *expressions* and scored five measures
  undecided. `moe.estimated` now reports the refusal and asks for a literal. This is
  Sysprose's deliberate rule, not a defect to patch from here.
- **The bearer name was prose** (`Mesh radio`), so `pa.bearer` suggested
  `connection def Mesh radioLink`; normalised to `MeshRadio`.
- **A stopped leg's finished calls vanish from the total.** Spend is saved when a
  step finishes; the three S32 calls of the stopped leg (7.41 USD) are missing
  from `state.llm`. `status` and the final audit now print the call-log total
  beside it.

## What v3 produced (2026-09-16)

The run finished. Every hazard in the model is now either mitigated by a named
element or explicitly accepted with its reason — which is what the whole
exercise was for.

| | v1 | v2 | **v3** |
|---|---|---|---|
| CLI witness | clean, 76 diagnostics | clean, 57 | **clean, 74** |
| Requirements satisfied | 41/70 (59 %) | 30/53 (57 %) | **41/46 (89 %)** |
| PA→EPBS closure | 14/16 | 1/6 (a reporting bug) | **5/5** |
| Doc coverage | 100 % except SA 87 % | same | **100 % every layer** |
| Unexplained elements | 0 | 0 | **0** |
| PA architecture chosen | alternative 1 | alternative 1 (only one survived) | **alternative 2** (0.65 vs 0.61) |

The five unsatisfied requirements are the three `OperationalBudgets` ones,
which are not hazards and were always out of scope, and the two hazards the
model deliberately accepted: `hazCoordinatorSinglePointOfFailure` and
`groundNodeConsolidationHazard`, both with their reason in the doc and both
listed under their own heading in the final audit.

What the gate actually changed, layer by layer: SA states five hazards and
satisfies all of them plus OA's; LA states four and satisfies them by
functions; PA satisfies every inherited logical hazard by the physical
component that carries the mitigation —

```
satisfy LA::Hazards::airspaceIncursionHazard by droneAirframeNode.flightSafetyController;
```

— where v1 and v2 had no `satisfy` in PA at all. Cost: ~22 USD over 11 calls
across two legs.

## What the v3 leg exposed (2026-09-16)

The hazard gate did its job and, in doing so, walked the composition code into
two defects it had never met. Both are fixed and validated against the real
answers that failed.

- **The unguarded unwrap** (`alternatives.ts`). `packageBody(text)` matches the
  first `package X {` *anywhere*, and the composition used it with no check
  that the package wrapped the whole answer — a check `withoutDuplicates`
  already had, with a comment warning of this exact failure. The chain: the
  gate forced hazards into the alternative, its `package Hazards` collided with
  the head's, the model renamed its own to `Alt2Hazards` to escape the
  duplicate, and that nested package hijacked the unwrap. An 18,116-character
  repair answer became 2,163: five component definitions gone, and the hazards
  that survived named types that no longer existed. Now one shared
  `unwrapWholePackage` serves both call sites. Replayed on the real answer: the
  whole 18,116 characters pass through, 5 of 5 components survive.

- **Comment-blind statement parsing** (`statements.ts`). A statement carries the
  comments written above it, because `splitStatements` slices from the end of
  the previous one. Both `mergeNestedPackages` and the `NAMED` regex skipped
  `//` lines but not `/* … */` blocks, so an alternative heading its hazards
  with `/* ---------- LA-level hazards ---------- */` defeated the merge and got
  a duplicate package. Fixed, and the merged body now keeps the author's
  comment. Worth recording honestly: replaying the old code proved this was
  *not* what lost the components — it caused the duplicate, nothing more.

**The gate worked as designed.** S31's first answer stated no hazards at all and
was blocked; one repair fixed it. Both LA alternatives then cleared with five
hazards each, five and nine `satisfy` lines, and one `#Accepted` apiece.

### Found while finishing the run

- **Budgets are not procurable.** S50 blocked once on `epbs.paPartsRealised`
  demanding configuration items for `rotationBudget` and `outageBudget` — PA
  models a budget as a part, and the gate reads every direct PA part as
  something to buy or build. Either the gate exempts parts that carry only
  constraints, or PA should stop expressing budgets as parts. The model
  complied without inventing items: `swarmSystemCi` traces to the top assembly
  *and* to `rotationBudget`, `missionComputerSoftwareCi` to the mission computer
  *and* to `outageBudget` — so the PA→EPBS 5/5 above counts two budgets among
  the five realised parts.
- **A finished step kept the note that explained its failure.** The shipped
  `state.json` marks S21 `done` and annotates it "failed after 3 attempts:
  session limit"; S41 and S50 are `done` and annotated "invalidated". Two
  contradictory facts in one record. Fixed — a step that completes clears its
  note — but v3's example (tag `runs-v1-v3`) is left exactly as the run produced it,
  because an audit record should not be retouched.
- **A resumed run under-reports its cost.** `state.llm` is overwritten per leg
  (`state.llm = opts.llm.spent()`, and the client starts at zero in each new
  process), so this run's state says 7.18 USD / 3 calls where the true total is
  ~22 USD / 11. The `--budget-usd` cap is per leg for the same reason, which is
  usually what you want — but `status` should add the legs up.

### Open questions this raised

1. **A hazard can be deleted instead of mitigated.** The rule demands that every
   hazard *stated* be satisfied, so an alternative under repair pressure can
   drop its own hazard and the gate goes quiet — the head's inherited ones stay
   satisfied. Consider refusing a fragment whose hazard count falls, or fixing
   the hazard set at the layer's author step.
2. **`#Accepted` may become the easy path — watch it, but it was not abused.**
   The finished model accepts exactly two hazards, each with a real reason in
   its doc (consolidating the coordinator and gateway onto one ground node;
   the coordinator as a single point of failure), and the trade-off text
   reasons about the consequence rather than hiding it. Still: nothing weighs
   acceptance in the score, so an architecture that accepts more risk scores
   the same as one that mitigates it.
3. ~~**Mitigating by function makes safety invisible to the choice.**~~
   **Answered by the run, at PA at least.** Safety did discriminate: the
   evaluator took alternative 2 partly because it "adds an explicit intra-drone
   bus with its own hazard" and gives the safety controller direct command
   authority, where alternative 1's boundaries were "mostly doc text". The
   concern still stands at LA, where both alternatives inherit the same
   function-level mitigations. Original wording: LA's hazards
   are satisfied by `complyWithClearance`, `respondToWeather` and
   `selfRecoverToPoint`, which live in the fixed function layer every
   alternative shares — so both alternatives inherit them mitigated and safety
   never discriminates between architectures. Demanding *component*-level
   mitigation at S32/S41 would change that; it is a real decision, not a bug.
4. ~~**Drone-to-drone interaction is declared, never instantiated.**~~ Closed by
   the population lane (CV-16): v4 and v5 instantiate a fleet of 12, two
   representatives and peer links at LA and PA.

## Next, in order

1. ~~**The workflow diagram misstates two things a reader trusts it for.**~~ **Corrected
   (2026-09-17)**, in `docs/diagram/workflow.tex` and in the project's own docs it had
   inherited the first claim from:
   - The escalation path now says what happens: a step that still blocks after three rounds
     stops the run, opens its gate only where one exists (S00, S10, S21, S33, S42, S50, S70),
     and an approval there records the decision and stops too — the way on is an edit and a
     `resume`, which page 2 now draws. `README.md`, the header of `src/orch/gates.ts` and the
     `--approve` help say the same, and a blocked step now logs the edit-and-resume recourse.
   - G-LA/G-PA read "approve or reject the pick"; the reject note says the same step runs again,
     at most twice. Where a rejection comment is read and where it is lost is written in the
     README.
   - The Final column says only the parse check blocks; G-OA and G-EPBS are drawn; T-04 is shown
     inside S50; page 2 is titled as the alternatives step; "about 6 s per check" became the
     measured 0.2–5 s per step; the weights say they sum to 1.15; the score pairs name their
     alternative; resilience is drawn in the agent colour, since a model scores it.
   - Still open from that review, and cosmetic: the intake lanes S01/S02 are named in the caption
     but not drawn; `\captionof` sits outside a float; `$\to$` falls back to Computer Modern; the
     font is loaded by name, so the build is not portable to a machine whose Noto ships only the
     variable font.

2. ~~**Three findings about the workflow itself.**~~ **Settled (2026-09-17)**, except one
   deliberate non-change:
   - ~~*The advisor model inside `claude -p --tools ""`.*~~ Found: `advisorModel: fable` in
     `~/.claude/settings.json`, which a child `claude` loads like any other. Every call now runs
     with `--setting-sources project` and an environment stripped of this session's `CLAUDE*`
     variables (`src/llm/claude-cli.ts`, tested). Verified live: one isolated call returns a
     single `message` iteration, no advisor turn. **Open**: whether v7 stays the kept example —
     five of its 21 author calls, the longest and dearest, carried an advisor turn.
   - ~~*Gate comments lost at G-SEED, G-LA and G-PA.*~~ The comment is now kept in `state.json`
     per step and put into SEED's prompt and EVALUATE's rubric prompt; the fragment `#prompt`
     element stays for the authors that read their own layer. A rejection at G-LA/G-PA still
     re-scores the same two alternatives — it cannot ask for a third — and the README says so.
   - ~~*`epbs.paPartsRealised` and `trace.closure` disagreed about actors.*~~ One function now
     answers "which PA parts owe a configuration item" and both predicates call it; replayed on
     v7, the seven "actor not realised" notes are gone. The kept audit keeps its own record.
   - *Approve-on-blocked: deliberately unchanged.* Approving the gate of a blocked step records
     the decision and stops, because the next layer would be derived from one the checks refused.
     Everything that claimed otherwise now says this (README, `gates.ts`, `--approve` help), and
     a blocked step logs the edit-and-`resume` recourse. Revisit only if a run wants to continue
     past a layer it knows is broken.

   Superseded notes from the review:
   - *Approving a gate on a blocked step does not let the run continue*, contradicting
     `gates.ts:7-8` and the CLI's own `--approve` help ("let it go on"). Decide: approval
     overrides the block, or a gate on a blocked step offers only reject / edit-and-resume.
   - *A rejection comment is silently lost at G-SEED, G-LA and G-PA.* SEED rewrites Common
     (`seed.ts:68`), and EVALUATE overwrites the head it was written into (`evaluate.ts:122`)
     while its rubric reads only the alternative files (`evaluate.ts:311`). Decide: thread the
     comment into those prompts, or refuse a comment at a score-driven gate.
   - *Five of v7's 21 author calls also ran an advisor model* (`claude-fable-5-1`) inside
     `claude -p --tools ""` — the five longest and dearest Sonnet calls, per
     `examples/drone-swarm-v7/audit/llm-log.jsonl`. The child inherits the session's advisor
     setting. Sanitise the child environment in `src/llm/claude-cli.ts` (no decision needed), then
     decide whether v7 stays the kept example or is re-run clean.
   - *`epbs.paPartsRealised` (blocking, S50) and `trace.closure` (reporting, S70) disagree* on
     whether external actors must be realised in EPBS. Decide which scope is right.

3. **Next feature — the 3D forerunner: fly the model in Gazebo with SITL autopilots.**
   Detailed plan: `docs/plans/swarm-3d-forerunner.md` (2026-09-17). In short:
   - *Scenario*: recharge rotation with sector handover, then one drone lost and coverage
     re-spreading. Needs only what a stock SITL gives — waypoints, battery, RTL, geofence — and
     exercises `handOverSector`, `rotateRecharge`, `redistributeCoverage` and the measures
     `areaUnderWatchShare` (estimate 0.92, target ≥ 0.9) and `coverageLossOnMemberLoss`.
   - *Generator `T-05`* (`src/realization/`): a run directory → `world.sdf`, fleet, scenario,
     state↔mode and function↔behaviour mapping, and a trace from every artefact to its model
     element. Keyed on tags and brief fields, never on one run's names.
   - *Runtime* (`sim/`): a container pinned to Ubuntu 24.04 with Gazebo Harmonic + ArduPilot SITL
     (PX4 later, behind a MAVLink adapter); per-vehicle and ground agents implementing the
     coordination functions; rule monitors (RecallWins, geofence, returns when isolated); metrics.
   - *Output*: `demo.mp4` rendered headless through EGL, and a **claimed vs simulated** table. A
     simulated value that contradicts an estimate is a finding — the simulation is not tuned to agree.
   - *Host facts*: Ubuntu 26.04 has no Gazebo in apt, so the runtime is a pinned 24.04 container.
     The one sudo step (`sudo usermod -aG docker $USER`) was **done 2026-09-18**; nothing further
     needs root. Headless GPU rendering on `/dev/dri/renderD128` is confirmed working — but only
     on the EGL *device* platform, since surfaceless falls back to llvmpipe in silence.
   - *Time is compressed and says so*: the 40/60-minute cycle runs at a declared factor (default 10),
     printed on the video and the report.
   - *Stages after it*: ground link cut for both architectures (the trade-off, animated); the rules on
     the autopilot; PX4; then GNSS-denied navigation, detection, jamming.
   - Work packages WP0 (probes) → WP1 generator → WP2 runtime → WP3 scenario → WP4 video → WP5
     report → WP6 `mbse-workflow simulate`. No paid model calls.
   - **Done (2026-09-18):** WP0.1, the model probe — every row of the mapping table has a source
     element in v7 — and **WP1, the generator** (`src/realization/simulation.ts`, T-05): a world
     sized 5000 m square from `areaOfInterestKm2`, 12 sectors on a 4×3 grid, 12 pads and the
     ground station from the `#Node` definitions, 12 autopilot instances with the duty cycle
     scaled by a declared factor, the state↔flight-mode mapping (13 states, the ones no flight
     mode fits marked as agent conditions), the four rules to monitor, the 14 measures, the
     rotation-and-loss scenario, and `trace.json` from every artefact to its elements. It refuses
     a brief with no population or a missing budget rather than guessing. Ten unit tests, and the
     generated YAML and SDF are parsed in the test rather than grepped — the first draft wrote
     YAML that no parser would read (`>= 0.9` starts a block scalar).
   - **Done (2026-09-18): WP0.2, the runtime and the clock** (`sim/`, commit `c97d0a3`). The image
     — Ubuntu 24.04, Gazebo Harmonic 8.15.0, ArduPilot `Copter-4.7.1`, `ardupilot_gazebo` at
     `082a0fe`, 6.6 GB — builds with `sg docker -c 'docker build … sim/docker'`, and
     `sim/probe/wp02-smoke.sh` flew one vehicle headless: armed, climbed to 9.0 m, landed, twice.
     Rendering is hardware (`radeonsi`, renoir, OpenGL 4.6) with `gz-rendering-ogre2` loaded, which
     closes the risk the video depended on.
     One vehicle flying in the stock `iris_runway` world holds a real-time factor of
     **0.718–0.773**; an empty world holds 0.985. (An earlier version of this entry called that
     gap the cost of a lockstep round-trip. There is no lockstep — SITL reports the plugin as
     `no_lockstep` in every run — and WP0.3 showed the gap is the camera and the scenery.)
     **A correction worth keeping:** this entry first reported a 0.18 m/s climb as a finding for
     WP0.4. That was the probe, not the aircraft — it asked for every telemetry stream and then
     read one message per half-second, walking a backlog. The climb is 6.2 s to 10 m on the
     autopilot's own clock. The probe now reports that clock beside the wall clock, and WP2's
     agents will read telemetry the corrected way.
   - **Done (2026-09-18): WP0.3, what the fleet costs** (`sim/probe/wp03-fleet.sh`). Twelve
     vehicles armed and hovering together, measured over a window that opens only once the whole
     fleet is airborne:

     | N | step | camera | RTF | airborne |
     |---|---|---|---|---|
     | 1 | 1 ms | — | 0.960 | 1/1 |
     | 4 | 1 ms | — | 0.953 | 4/4 |
     | 12 | 1 ms | — | **0.871** | 12/12 |
     | 12 | 1 ms | 1280×720 | **0.769** | 12/12 |
     | 4, 12 | 2.5 ms | — | — | **0/4, 0/12: never initialised** |

     **Twelve vehicles hold real time, so nothing is reduced** — not the fleet, not the physics
     rate. The plan had reserved a reduced rate as the fallback and 2.5 ms as the candidate; it
     is not available, because at 2.5 ms no autopilot ever initialises its EKF and every arm is
     refused. Keep the 1 ms step.
     CPU is not the limit either: the busiest cell uses 15% of this 16-core host. The wall is one
     thread — the Gazebo server at 166% of a core.
     **Consequences:** D4's time scale of 10 stands and is the only speed-up available, since the
     simulator never beats real time; WP3's 1200 s scenario therefore costs ~26 min of wall clock
     to record; 1280×720 is affordable for WP4; and WP2 must not assume a fixed arming wait,
     which grew 25 s → 52 s → 148 s with the fleet.
     Two silent probe defects fixed: `<model static="true">` is not SDF (`static` is a child
     element), so the generated ground plane fell and took the vehicle with it — an IMU in free
     fall reads no gravity, and the EKF refuses to initialise 300 s later with no hint of the
     cause; and two type-filtered `recv_match` calls in one loop discard each other's messages,
     so arm acknowledgements were being eaten by the position read.
   - **Done (2026-09-18): WP0.4, battery realism** (`sim/probe/wp04-battery.sh`). The battery does
     **not** drain in this stack: 0.0 A and a flat 12.6 V over 86 s, with `SIM_BATT_CAP_AH` at
     its default and again at 3.3 Ah with the failsafe armed. The same parameters against
     ArduPilot's own physics (`--model quad`) draw 29.4 A and 487 mAh in 60 s, so the parameters
     were right and the autopilot's model works — the **JSON backend bypasses it**. With an
     external FDM, SITL takes battery state from the simulator: `SIM_JSON.h:163-164` accepts
     `battery: {voltage, current}` as optional fields, and `ardupilot_gazebo` never sends them
     (no battery code in the plugin at all).
     **Decision: charge lives in the coordination agent**, from flight time against
     `memberFlightEnduranceMinutes` over the declared time scale. That is the plan's stated
     fallback, but it is also the faithful realisation rather than a workaround: `rotateRecharge`
     is a `#Coordination` function the model allocates to the coordination node, so charge
     belongs there, and recall and recharge then contend inside one agent — which is what makes
     `RecallWins` observable at all.
     **Limit to report in WP5:** the simulated vehicle never runs out of power, so the forerunner
     demonstrates the rotation logic, not an energy margin. A stage-3 option exists — teach the
     plugin to send battery fields, since the protocol already accepts them — but that patches a
     pinned dependency.
   - **Done (2026-09-18): WP1's missing half** — `src/realization/adapter.ts` and
     `npx tsx src/cli.ts simulate --out <run>`. The generator had only ever seen a fixture; the
     adapter reads a real run directory (tags and brief fields, never a run's literal names) and
     `test/integration/simulation-v7.test.ts` proves T-05 against v7: 12 × SurveillanceDrone over
     25 km², 2 machines / 13 states, 5 `#Node` parts, 8 coordination functions, 4 rules, 14
     measures, nothing refused.
     Running it on the real model caught a false claim the fixture could not: `fleet.yaml` said
     "endurance runs through the battery so the autopilot's own failsafe fires" and emitted
     `SIM_BATT_*` parameters that WP0.4 had just measured to be inert through the JSON backend.
     Replaced by a `charge_model` section naming `rotateRecharge` as the owner and what the demo
     therefore does not exercise; two unit tests keep both from coming back.
   - **Next: WP2, the runtime** (`sim/`) — the per-vehicle and ground coordination agents (the
     four `#Coordination` functions as separately testable behaviours over a message bus standing
     in for the mesh), the three rule monitors, the two measure metrics, all logging JSONL. WP0 is
     complete; nothing is blocked and nothing needs sudo.

4. **Done (2026-09-18): the gate the v7 model would have failed.** `moe.dutyCycleBound`, blocking
   at S32 and S41, with CV-17 amended to state the rule. Replayed against v7 it blocks **both** PA
   alternatives:

   > `areaUnderWatchShare` is estimated at 0.92 and its own definition says it holds at any
   > moment, but the brief fixes 40 min of flight against 60 min of recharge, so a member is
   > airborne 40% of the time — 4.8 of 12. Holding 0.92 at any moment needs each airborne member
   > to cover 2.3× its share, and nothing in this layer says what one member covers.

   The check is deliberately narrow, because a heuristic that blocks the wrong thing is worse than
   no check. It fires only when the brief fixes both halves of a duty cycle, the measure is a
   dimensionless share to be maximised, **the brief's own doc claims it holds at any moment** —
   the author's words, not an inference — and the estimate states a literal above the bound. Seven
   unit tests pin what it catches and, as carefully, what it leaves alone: a measure with a unit,
   one to be minimised, one that makes no simultaneity claim, a brief with no duty cycle, and a
   derived estimate, which is the whole point of the rule.

   This closes a loop worth naming. The contradiction was found by *flying the model*, months of
   work downstream of where it was written. The same arithmetic now runs at the gate, for nothing,
   before a paid call. What made it checkable was that the author had already written "at any
   moment" in the brief — the claim was there in plain words, and nothing had ever compared it
   with the budgets on the next page.

   ~~**Was: a gate the v7 model would have failed, worth adding**~~ (found 2026-09-18 while preparing
   the simulation, not by a run). `areaUnderWatchShare = 0.92` is a bare `#Estimate` literal, and
   the brief's own budgets contradict it: `fleetSize 12` with a 40/60 duty cycle puts 4.8 members
   airborne, which over twelve sectors is 0.40. The model states no watch footprint anywhere, so
   nothing connects the estimate to the budgets and the claim cannot be checked either way. Its
   sibling `coverageLossOnMemberLoss` *is* derived — `assert constraint { == 1.0 / fleetSizeValue }`
   — and would have been caught if it were wrong.
   **The rule that would catch it:** an `#Estimate` whose value is determined by brief budgets
   must derive it, as CV-17 already allows, rather than state a literal. The hard part is deciding
   "determined by" — a first cut is a measure whose name or doc references a quantity the brief
   fixes (fleet size, endurance, area) and which states a literal with no `assert constraint`.
   Worth a predicate at S42/S50 under the existing knobs. See the plan's "finding this is expected
   to produce".

5. **Done (2026-09-18): the transit gate, and the question that makes it answerable.**
   `moe.transitBudget`, blocking at S32 and S41, checks `2 × distance / speed` against the
   endurance the brief fixes — where `distance` is the far corner of the area, the same reading
   T-05 flies. It fires only when the brief states a **cruise speed**, and says nothing when it
   does not: a check that guessed a speed would fabricate the fact it exists to test. v7 states
   none, so the gate is silent on v7, which is correct and is pinned by a test.
   The other half is therefore the more important one: **SEED now asks for the speed.** When a
   brief fixes an area a population works over and an endurance for its members, it is told that
   this implies a cruise speed, that without one nothing can say whether a member reaches its
   station and returns, and that a swarm flown at v7's numbers spent more than its whole budget
   on the return leg. Where the brief is genuinely silent it must say so in the endurance
   budget's doc rather than leave the question unasked.
   Five tests pin the arithmetic and, as carefully, the silences: no speed, no area, no
   endurance, a speed under any name the brief gives it, and a member fast enough to do the trip.

   ~~**Was: a second gate the live run argues for**~~ (found 2026-09-18, by flying v7 at full scale). The
   flight endurance a brief fixes has to cover the transit to a member's station and back. In v7
   the sector centres are 625–2509 m from the pads, the scaled flight budget is 240 s, and the
   measured return leg alone costs 142–306 s — so a member can spend more than its whole budget
   coming home, and the watch share falls to 0.18 where the duty cycle alone would allow 0.40.
   The arithmetic is available the moment the model states a **cruise speed**, which v7 does not:
   `transit = 2 × distance / speed` against `memberFlightEnduranceMinutes`. Same shape as
   `moe.dutyCycleBound` — the numbers are nearly all there, and the missing one is a figure nobody
   wrote down. Worth a predicate once a brief carries a speed, and worth a SEED prompt line asking
   for one when a brief fixes an area and an endurance.

6. **Done (2026-09-18): the third and fourth gates.** The trade-off now names every measure that
   scored its alternatives identically, and says plainly when a decision was made by elimination
   rather than comparison.
   **With a correction to the evidence that prompted the first of them.** This entry claimed both
   of v7's PA alternatives estimated `groundLinkLossAreaUnderWatchShare` at 0.9. They did not —
   that came from reading `build/` copies instead of `fragments/`, where they read 0.55 and 0.91.
   The decisive measure discriminated properly. What is true is that **four of fourteen** measures
   gave both alternatives the same number, so a third of the comparison turned on nothing — which
   still justifies the check, on smaller grounds than were claimed.
   **The rule:** when alternatives are scored, at least one measure must differ in its estimate,
   and a measure that names the thing the alternatives differ about — the one the rationale
   argues over — should be among them. Identical estimates with identical docs across every
   alternative is a trade-off decided on nothing. Cheap to check at S33 and S42 where both
   alternatives are in hand; the hard part, as with the other two gates, is saying *which*
   measure ought to discriminate, and the rationale text is probably where that is written.

7. **Open.** Nothing is blocking. What a future run should watch:
   - *The fixes below that were replayed offline, not yet seen live*: the
     path-allocation rewrite, typed-usage ownership, the function count in the
     alternatives prompt, the per-layer hazard wording. The next paid run is their test.
   - *The brief's placeholder targets* await the customer's numbers. The final audit
     now says which targets every alternative met — 12 of v7's 14 — so the choice
     rests visibly on the rest.

### Closed after v7 (2026-09-17)

- ~~*Keep v6 in `examples/`?*~~ Moved to tag `runs-v6`.
- ~~*Keep the member's machines on the member in T-02/T-03.*~~ Misdiagnosed: the
  transitions carry no state machines at all. The authors write a member's
  machine at package level and give the member `state mode : <Machine>;`, which is
  valid, and the gate read only definition ownership. Fixed in 1e4e249 and
  replayed: v7 PA alternative 1's first answer, recomposed with today's code,
  shows no rule or mode finding.
- ~~*Path allocations survived the prompt.*~~ The composer rewrites them, now
  including the layer above's action *definitions* (`LA::HandOverSector` →
  `handOverSector`). Replayed on v7's first answers: LA alternative 2's 19 and PA
  alternative 2's 13 are localised, and LA alternative 2's C2 finding goes with
  them. The replay also found that both PA alternatives had dropped the same 6
  untagged functions. The prompt had said "exactly 28" of which 9 were the actors'
  own; it now counts only what is left to allocate and names the untagged ones.
  The allocation message blamed a path for any function the layer above had also
  allocated; it now does so only for allocations into this layer's parts.
- ~~*EPBS and "hazards this layer adds".*~~ Every layer's prompt and the gate say
  what that layer adds; EPBS's names supply, version drift and obsolescence.
- ~~*Tighten the targets.*~~ Decided (2026-09-17): not tightened — that would be
  inventing numbers again. The brief marks the planner's numbers *(placeholder)*,
  SEED records `placeholder: true`, and the final audit labels them and lists every
  target all alternatives met.
- ~~*The fault tree has nothing to read.*~~ Decided: it needs component contracts
  refining a top requirement, which no layer writes. The final audit and S60 say
  "not applicable" and claim nothing about single points of failure.

### Closed after v6

- ~~*Save spend per call*~~ (2498ad1), ~~*six undocumented `assert constraint`s*~~
  (v7: 100 % on every layer but Common), ~~*restated hazards*~~
  (`hazards.notRestated`, none restated in v7).
- ~~*The refused-derivation message is untested live*~~: replayed on v6's PA
  alternative 1 from tag `runs-v6`. Exactly the five estimates v6 scored undecided
  now block, naming the floating-point equation that caused it.

5. **Close what v5 left open.**
   - ~~*The distributed PA alternative moved operator C2 onto a drone.*~~ **Closed
     in the workflow:** `alt.c2Placement` now demands a ground usage for every C2
     function in alternative 2 as well — the distributed design distributes
     coordination, not command; a member may carry its own copy. Replayed: blocks
     v5's alternative 2 (4 C2 functions at LA, 5 at PA with no ground usage), clears
     v4's. The kept v5 example is not re-run.
   - *A target no architecture meets* is now flagged in the final audit's
     `## Measures`, from the bounds reports every alternative left. On v5 that is
     `areaCoverageRatio ≥ 0.95` (0.90–0.94 across all four alternatives). The
     single-loss target is not unreachable: v5's ground-centric PA met it at 0.09.
     The fix for such a target belongs in the brief — state the fleet size and the
     coverage the customer needs, so SEED does not invent both.
   - ~~*The weight check passed, once.*~~ Watched on v6 and v7: it discriminated both
     times (v7 LA 0.86 vs 1.00, PA 0.93 vs 1.00), on few measures — which the final
     audit now shows.
   - ~~*Call timeouts.*~~ No call has been killed since the limit went to 1800 s, and
     then 3000 s: the longest were 1425 s (v6) and 952 s (v7). Spend is saved per call.
   - ~~*PA→EPBS 4/5*~~ was the audit counting the carried `#prose part fleetFact`; fixed, every procurable PA part has its item. The mesh radio was still an `#Actor` at PA; T-03 now writes the brief's bearer as a `#Node` and `pa.bearer` blocks (replayed on v5's LA: loads clean).

6. ~~**Two deferred checks still unwired**~~ Wired into S60 (2026-09-17): `fault-tree`
   once, `check-behaviour` over every state machine — its own properties, or recovery
   to its opening state when it is written to come back. On v5: 17 machines
   recoverable, 3 lifecycles unchecked, 75 ms.

7. ~~**Contribution ease is still unmeasured**~~ **Measured (2026-09-17) on v5**,
   by simulating an edit to each layer on a copy of the state and reading back the
   invalidation a resume would perform — checked against a real edit in
   `test/integration/contribution.test.ts`. Every final audit now has the table.

   | Layer edited | Fragment lines | Re-checked | Runs again | USD those steps cost in v5 |
   |---|---|---|---|---|
   | Common | 158 | S00 | S10…S70 (17) | 52.69 |
   | OA | 462 | S10 | S20…S70 (15) | 43.90 |
   | SA | 544 | S21 | S30…S70 (12) | 40.58 |
   | LA | 768 | S33 | S40…S70 (7) | 23.33 |
   | PA | 585 | S42 | S50…S70 (3) | 4.33 |
   | EPBS | 275 | S50 | — | 0 |

   The edit surface is one fragment; the blast radius is every layer below it, so
   an edit high up costs almost a full run. It also found a defect, fixed: an edit
   to Kinds re-ran SEED, which rewrites Kinds and undid the edit. Finer granularity
   (element-level impact) would need the old fragment text, which the state does
   not keep — the obvious next step if contributor edits become routine.

8. ~~**Watch S10 now that `validation/requirement-subject` blocks there.**~~ Watched:
   neither v6's nor v7's S10 hit it (their repairs were about the system entity and
   unresolved types). The
   cause of the `OperationalBudgets` waste was not Sysprose changing — v2's own
   S10 and S20 packets already report it. It was declared in S21's `failCodes`
   and not in S10's, so it was harmless where it could be fixed and blocking
   where it could not. S10 now declares it; the calibration suite still clears
   the reference OA prefix, but the next OA authoring is the real test.

## Done since the checkpoint

- **v5** (tag `runs-v5`, 2026-09-16), from SEED, three legs, ~54 USD
  recorded. Acceptance met: OA declares the 10 brief functions as tagged
  definitions; SA has 24 functions with those 10 tagged, OA→SA 34/34; both
  alternatives at LA and PA state all six estimates, the trade-offs show worst
  cases and verdicts with no "undecided", and the measures term differs between
  alternatives; `## The fleet` counts by definition (LA 1/10 vs 9/10, PA 2/10 vs
  10/10 on board) and EPBS reads `fleetCi [12]`; `## Measures` present; no `entry;`.
  CLI clean with 6 diagnostics (v4: 24); 48/49 requirements, the one open being an
  accepted hazard, as the headline now says. Alternative 2 chosen at both layers.
  Two workflow defects surfaced and were fixed on the way: T-01 dropped parameters
  declared on definitions as `in item` (S20 blocked, 15 flows without ends), and the
  900 s call timeout killed every S41 attempt.

- **What v4 left open, closed in the workflow** (2026-09-16, no model calls):
  - *The measures term was a constant in every run.* `evaluate.ts` read a
    `verdict` field `bounds` never emits, so every measure was "undecided" and
    `moeScore` returned 0.5 for every alternative ever scored — the 0.4 weight
    never discriminated. Beneath it: it bounded Common's attribute (a subsetting
    estimate gives Common no value; probed), asked for the best case instead of
    the worst, no alternative stated a value, and "max 0.95" was printed where a
    floor was meant — the model copied "target (max 0.95)" into its docs. Now CV-17
    `#Estimate` per architecture, gated by `moe.estimated`, bounded worst-case, 1/0/½
    per measure, reports kept, `## Measures` in the audit, targets rendered `≥ 0.95`.
  - *Tagged functions were counted per usage.* T-01 now merges the members' usages
    of one definition into one system function (tags read from the definition too);
    counts, the placement gate, the score and the audit go by definition;
    `oa.namedFunctions` anchors the brief names at OA. Replay on v4: SA 28 → 19
    functions, clean, 28/28 traced; alternatives 2/10 vs 5/10 on board, where
    per usage they read 12/20 vs 15/20.
  - *The accepted hazard reported as uncovered:* `requirements.coverage` exempts
    `#Accepted` like the hazard gate, the audit reads accepted hazards from the tag
    index, and the headline says when the unsatisfied ones are accepted.

- **v4, the swarm run** (tag `runs-v4`, 2026-09-16). From SEED,
  two legs, 21 calls, ~40 USD. Acceptance met: a `#Member part def SwarmDrone`,
  `part fleet : SwarmDrone [12]`, `memberA`/`memberB` and two `MeshLink` peer
  links at LA and PA; `[12]` CIs at EPBS; alternative 1 ground-centric (the
  deciding coordination functions and all C2 on `groundStation`) and 2
  distributed at both layers, 2 chosen both times (LA 0.72 vs 0.54, PA 0.76 vs
  0.58, resilience 0.63 vs 0.25); no `entry;`; SA and below allocate nothing to
  the OA entity (the 18 `allocate … to watchAsset` are OA's own). CLI clean,
  24 diagnostics against v3's 74; 25/26 requirements satisfied.
  The first leg blocked at S20: T-01 wrote an action definition per usage, so
  two members performing one activity declared it twice (18 errors) — fixed,
  one definition per type, replayed clean on the real OA.

- Hazard-mitigation gate (`efe5f51`): `requirements.hazardsMitigated` on S21,
  S31, S32, S41, S50, blocking under `safety`; `#Accepted` is the escape and the
  final audit lists it. Offline against v2's example (tag `runs-v1-v3`) it blocks
  exactly the hazards that run left unsatisfied (7 at SA, 13 at LA, 17 at PA,
  20 at EPBS).
- README drift (`4e45265`).
- Invalidation reads the hash of the step that finished **last by the clock**,
  not last in the step table (`bb365f5`+). Measured on this run: S22..S70 still
  carried the previous run's hashes, so Common and SA looked edited by a
  person, `resumeAt` was S10, and the resume would have re-authored the model
  from OA down.
- PA→EPBS "1/6" (`0640a77`) was a reporting bug, not a modelling gap: the final
  audit exempted actors by a name regex and missed five `#Actor` parts. The method
  settles the modelling question the other way — a CI realises node *and*
  behaviour components (A1-C-28, A1-R-04) — so the gate stays as it is.

## Before any paid run

```
npm run record-fixtures && npm test     # re-calibrate; Sysprose moves often
```

If a predicate disagrees with the tool, fix the predicate — the validated
reference model is the oracle. Then bump `sysprose.expected_commit`.

When a composition fails, reproduce it offline from the saved raw answer in
`audit/<step>/*.raw-section.*.txt` and read Sysprose's own verdict on the exact
text **before** theorising. That habit is what turned 47 findings into 4.
