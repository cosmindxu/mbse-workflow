# Plan — the 3D forerunner: the v7 swarm model flown in Gazebo with SITL autopilots

## Goal

A first **3D demonstration generated from the model**, not drawn beside it: the v7 drone-swarm
model (`~/Work/mbse-workflow/examples/drone-swarm-v7/`) is transposed into a Gazebo world with
SITL autopilots, flies the **recharge rotation with sector handover** scenario, takes one injected
fault (**a drone is lost, coverage re-spreads**), and reports the simulated measures beside the
architecture's own estimates. The deliverables are a video, a run log, and a "claimed vs
simulated" table — every moving thing traceable to a named model element.

Forerunner scenario and why (decided with the user 2026-09-17): it needs only what a stock SITL
gives (waypoints, battery, RTL, geofence) — no perception, no RF model — and it exercises the
model's core claims: `handOverSector`, `rotateRecharge`, `redistributeCoverage`,
`areaUnderWatchShare ≥ 0.9` (estimate 0.92), `coverageLossOnMemberLoss ≤ 0.25` (estimate 0.083
at PA). Link loss (ground-centric 0.55 vs distributed 0.92) is stage 2; rules on a real autopilot
(RecallWins, geofence) stage 3; GNSS-denied navigation, detection and jamming come later.

## Facts about this host (probed 2026-09-17)

- Ubuntu **26.04.1**, bare metal, 16 cores, 61 GB RAM, 343 GB free, AMD Vega iGPU.
- **No Gazebo in apt**: `apt-cache search gz-sim|gz-harmonic` is empty on 26.04, and OSRF's apt
  repository targets 24.04 — do not assume it installs here.
- `gz`, `ros2`, `colcon`, `mavproxy.py`, `sim_vehicle.py`, `pymavlink`: all missing.
  Present: docker (CLI), cmake, ninja, gcc/g++, python3/pip, git, ffmpeg, xvfb-run.
- **Docker is installed but the user is not in the `docker` group** ("permission denied … docker.sock").
- The session display is xrdp (`DISPLAY=:10`) → OpenGL is **llvmpipe (software)**. The user *is* in
  `render` and `video`, and `/dev/dri/renderD128` exists, so **headless GPU rendering through EGL**
  works without a desktop session — which is how the video gets made.

## Decisions (defaults; the user confirms at the pause)

- **D1 — containerised stack, pinned to Ubuntu 24.04 inside.** One image: Gazebo Harmonic (LTS) +
  the autopilot SITL + the `ardupilot_gazebo` plugin, run with `--device /dev/dri` for EGL
  rendering. It sidesteps the 26.04 packaging gap and makes the demo reproducible on any machine.
  **Needs sudo once:** `sudo usermod -aG docker $USER` then log out and in (or `newgrp docker`).
  Nothing else on the host needs sudo. No-sudo fallback, to probe only if D1 is refused: Gazebo
  from conda-forge via micromamba in `$HOME` (unpinned against the autopilot plugins — riskier).
- **D2 — ArduPilot SITL for the forerunner**, behind an adapter so PX4 can replace it. Twelve
  instances are lighter than twelve PX4s, multi-vehicle is one flag (`-I n`), and battery failsafe,
  RTL and geofence are native parameters. The adapter speaks MAVLink only (pymavlink), which PX4
  also speaks; the PX4 variant is a second image, not a rewrite.
- **D3 — lives in `mbse-workflow`**: the generator is a transition like T-01…T-04 (`T-05`,
  model → simulation), so it belongs with them; the runtime sits in `sim/`. Sysprose is only read
  (its API gives the elements), never modified.
- **D4 — time is compressed and says so.** A 40/60-minute cycle is scaled by a declared factor
  (default 10: 4 min flight, 6 min recharge) applied to battery capacity and recharge timer; the
  factor is a parameter in the generated scenario file and printed on the video and the report,
  so a simulated measure is never compared against an unscaled target by accident.

## Model → simulation mapping (the generator's contract)

| Model (v7, PA unless noted) | Simulation artefact |
|---|---|
| `#Member part def SurveillanceDrone` | vehicle model (iris-class quad SDF) + one SITL instance each |
| `part fleet : SurveillanceDrone [12]` | spawn count and instance ids; `memberA/B` = instances 0/1 |
| `#Node GroundStation`, `RechargePoint` | static models at world poses; recharge pads = landing sites |
| budgets `areaOfInterestKm2 = 25`, `memberFlightEnduranceMinutes = 40`, `memberRechargeMinutes = 60`, `fleetSize = 12` | world extent and sector grid; `BATT_CAPACITY`/`SIM_BATT_*`; recharge timer; all through the time scale |
| member states `Landed, Launching, Watching, Recalled, Landing, Isolated…` | mapping table state → autopilot mode (`GUIDED`/`AUTO`/`RTL`/`LAND`) and the telemetry predicate that means "in this state" |
| `#Coordination` functions `handOverSector, rotateRecharge, redistributeCoverage, deconflictMembers` | behaviours of the coordination node, named after the functions, placed per the chosen architecture (LA alt-2: on board = per-vehicle agent processes; ground = one process) |
| `#C2` `taskMission, recallAndLand` | operator script events (mission start; a recall at T+x) |
| rules `RecallWins`, `GeofenceBreachEndsWatch`, `ReturnsWhenIsolated` | runtime monitors over the state trace — the same sentences the model checker proved, now checked on the run |
| measures `areaUnderWatchShare`, `coverageLossOnMemberLoss` | metrics computed from logged poses × sensor footprint over the sector grid |
| hazards `MeshJammingHazard`… | not simulated in the forerunner; listed in the report as "not exercised" |

Every generated file carries the qualified name of the element it came from; `sim/out/trace.json`
is the full map and is what the report's traceability section prints.

## Work packages

**WP0 — probes (no sudo needed until 0.2).**
0.1 Read the v7 model through Sysprose in process (as `src/sysprose/inprocess.ts` does) and dump the
   mapping inputs above; confirm every row of the table has a source element (names may differ per run,
   so the generator keys on tags and brief fields — `population.memberDef`, `fleetPart`, budgets — never
   on v7's literal names).
0.2 After the docker-group step: build the image; one vehicle takes off headless; `gz sim -s
   --headless-rendering` records frames through EGL on `/dev/dri/renderD128`; confirm GPU not llvmpipe.
0.3 Twelve instances: measure real-time factor and CPU; settle the time-scale factor and the video
   resolution from the measurement, not a guess.
0.4 Battery realism: confirm the SITL battery drains under `SIM_BATT_CAP_AH` and triggers the failsafe
   at the scaled endurance; otherwise model charge in the coordination node from flight time.

### WP0.4 result (measured 2026-09-18, `sim/probe/wp04-battery.sh`)

**Done. The battery does not drain in this stack, so the duty cycle belongs to the coordination
node — which is where the model puts it anyway.** The plan's stated fallback is the answer, and
for a better reason than "the first option failed".

What was measured, in three steps:

| Configuration | Hover draw | Consumed | Verdict |
|---|---|---|---|
| Gazebo + JSON, `SIM_BATT_CAP_AH` at its default 0 | 0.0 A, 12.6 V flat | 0 mAh in 86 s | no drain |
| Gazebo + JSON, `SIM_BATT_CAP_AH = 3.3`, failsafe armed (`BATT_LOW_MAH 330`, `BATT_FS_LOW_ACT 2`) | 0.0 A, 12.6 V flat | 0 mAh in 86 s | **no drain** |
| ArduPilot's own physics (`--model quad`), same parameters | **29.4 A, 11.8 V** | **487 mAh in 60 s = 8.12 mAh/s**, 82% left | drains |

So the parameters were right and the autopilot's battery model works — it is the **JSON backend**
that bypasses it. With an external FDM, SITL takes battery state from the simulator rather than
modelling it: `libraries/SITL/SIM_JSON.h:163-164` accepts `battery: {voltage, current}` as
*optional* fields and `SIM_JSON.cpp:491` applies them only when the `BAT_VOLT` bit says they
arrived. `ardupilot_gazebo` never sends them — the plugin's source contains no battery, voltage
or current code at all, and the capability line SITL prints on connection lists only
`timestamp, imu, position, quaternion, velocity`.

**Decision: charge is modelled in the coordination agent, from flight time against the brief's
own budget.** Not merely because the alternative is unavailable, but because it is the faithful
realisation: `rotateRecharge` is a `#Coordination` function the model allocates to the
coordination node, so charge accounting living in that agent *is* the architecture. Charge
hiding inside the autopilot would put a model function somewhere the model does not put it.
The agent therefore owns the duty cycle — flight time against
`memberFlightEnduranceMinutes` divided by the declared time scale — and commands `RTL` and the
landing itself, which is also what makes the rule `RecallWins` observable: the recall and the
recharge then contend inside one agent, where the model says they contend.

Consequences and limits, recorded rather than smoothed over:
- **The simulated vehicle never runs out of power.** A member that the agent does not recall
  will hover indefinitely. That is a property of the demonstration and belongs in WP5's "what
  was not exercised" section: the forerunner shows the *rotation logic*, not a real energy
  margin.
- **The measured 8.12 mAh/s is not used for the forerunner** and is recorded only as evidence
  that the autopilot's model works. It comes from ArduPilot's internal quad, not from the Gazebo
  airframe, so it is not this vehicle's power curve. The forerunner's charge model is
  time-based, which is what D4 scales and what traces to a brief budget.
- **A later option, not taken now:** teach the plugin to send `battery.voltage` and
  `battery.current` — the protocol already accepts them — and the autopilot's own failsafe comes
  back, which would let stage 3 put the battery failsafe under the rule monitors. That means
  patching a pinned dependency, so it is a stage-3 item, not a forerunner one.

### WP0.3 result (measured 2026-09-18, `sim/probe/wp03-fleet.sh`)

**Done, and it settles the question the plan reserved: twelve vehicles hold real time here, so
nothing has to be reduced — not the fleet, not the physics rate.**

Each cell is N vehicles armed and hovering at 20 m together, with the factor measured over a
45 s window that opens only once the whole fleet is airborne, and the CPU sampled over the same
window. `ruby` is the Gazebo server (the `gz` CLI runs the server inside a ruby process).

| N | step | camera | RTF mean | fleet airborne | server CPU | autopilot CPU | total |
|---|---|---|---|---|---|---|---|
| 1 | 1 ms | — | **0.960** | 1/1, armed in 25 s | 36% | 6% | 44% |
| 4 | 1 ms | — | **0.953** | 4/4, armed in 52 s | — | — | 102% |
| 12 | 1 ms | — | **0.871** | 12/12, armed in 148 s | — | — | 251% |
| 12 | 1 ms | 1280×720 | **0.769** | 12/12, armed in 153 s | 166% | 71% | 239% |
| 4 | 2.5 ms | — | (1.000) | **0/4 — never initialised** | — | — | 115% |
| 12 | 2.5 ms | — | (0.390) | **0/12 — never initialised** | — | — | 148% |

CPU is a percentage of *one* core, on a 16-core host: the busiest cell uses 15% of the machine.

**The step size: keep the default 1 ms.** The plan reserved "twelve at a reduced physics rate" as
the fallback, and 2.5 ms was the candidate because it matches ArduCopter's 400 Hz main loop. It
does not work: at 2.5 ms *no* vehicle ever initialised its EKF, at four or at twelve, and every
arm was refused with "Arm: System not initialised". The autopilot needs the ~1 kHz IMU that the
1 ms step delivers. The factors in those two rows are parenthesised because nothing was flying
in them, so they measure an idle world rather than a fleet.

**What the fleet costs.** Twelve vehicles cost about a tenth of real time against one (0.871 vs
0.960), and drawing them costs another tenth (0.769 with the 720p overview). The wall is not the
machine — it is one thread: the Gazebo server sits at 166% of a core while the whole run uses 15%
of a 16-core host. So the headroom for more vehicles is in that thread, not in the core count.

**Consequences for the plan:**
- **D4's time scale of 10 stands, and it is the only speed-up available.** A factor of 10 is
  obtained by shortening the *modelled* endurance — the battery and the recharge timer — not by
  running the simulator faster: with `real_time_factor 1.0` the simulation never exceeds real
  time, and the measurements above cap it below. WP3's scenario is 1200 s of simulated time, so
  the recorded run costs about **26 minutes of wall clock** at 0.769. That is the budget.
- **WP4's resolution:** 1280×720 is affordable at the full fleet and is the default to use;
  it is not pre-decided here, and WP4 may raise it against this measurement.
- **WP2 should expect ~150 s to arm twelve.** The EKF settle is per vehicle and overlaps, but it
  grows with N (25 s → 52 s → 148 s); a scenario script that assumes a fixed wait will be flaky.

Two probe defects fixed on the way, both worth recording because both were silent:
- **`<model static="true">` is not SDF.** `static` is a child element; as an attribute sdformat
  warns once and ignores it, so the generated ground plane was a *dynamic* body and fell, taking
  the vehicle with it. An IMU in free fall reads no gravity, the EKF never initialises, and the
  symptom arrives 300 s later as "Arm: System not initialised" with nothing pointing at the
  ground. Isolated by flying a directly-launched autopilot against the *stock* world, which
  armed in 25 s and so cleared the launch method and the fleet driver.
- **Two type-filtered `recv_match` calls in one loop discard each other's messages.** pymavlink
  throws away what does not match the filter, so the loop asking for positions was eating the arm
  acknowledgements and vice versa, and the fleet reported "armed 0 of 1" for an autopilot that
  was arming fine. The driver now reads once per pass and dispatches by type, and it takes armed
  state from the heartbeat's armed bit — the autopilot's own account — rather than from an
  acknowledgement that can be missed. WP2's twelve agents read telemetry this way, so this had
  to be right before it was replicated twelve times.

### WP0.2 result (measured 2026-09-18, `sim/probe/wp02-smoke.sh`)

**Done.** The image is `sim/docker/Dockerfile` — Ubuntu 24.04, Gazebo Harmonic 8.15.0,
ArduPilot `Copter-4.7.1`, `ardupilot_gazebo` at `082a0fe`, 6.6 GB built. One vehicle armed,
climbed to 9.0 m and landed, twice in a row, with Gazebo server-only and headless.

- **Rendering is hardware.** `AMD Radeon Graphics (radeonsi, renoir)`, OpenGL 4.6, Mesa 25.2.8,
  inside the container, and `gz-rendering-ogre2` loads. The risk in the Risks section is closed;
  no software-rendering fallback is needed.
  **But only on the EGL *device* platform.** `EGL_PLATFORM=surfaceless` silently gives
  `llvmpipe` — on the host as well as in the container — so the image pins
  `EGL_PLATFORM=device` and the smoke test prints the renderer before anything else.
- **Real-time factor, one vehicle flying in `iris_runway`: mean 0.718–0.773** across runs (the
  quoted run: 80.0 s simulated in 111.5 s of wall clock, 1104 samples, instantaneous median
  0.706). Physics alone in an empty world: **mean 0.985**.
  An earlier version of this line called the gap "the lockstep round-trip to a single
  autopilot". **There is no lockstep**: SITL's own log lists the plugin's capabilities as
  `no_time_sync, no_lockstep` in every run, WP0.3's included. The gap is the gimbal camera and
  the runway scenery in `iris_runway` — see WP0.3, where the same vehicle in a bare world holds
  0.960.
- **The climb is normal:** 10 m in **6.2 s on the autopilot's own clock** (6.9 s of wall clock),
  about 1.6 m/s under a 2.5 m/s `WPNAV_SPEED_UP`. See the correction below — an earlier version
  of this section reported 0.18 m/s and was wrong.

Four defects found and fixed while getting here, all in the Dockerfile or the probe:
`libopencv-dev` and GStreamer are `REQUIRED` by the plugin's unconditional camera and gimbal
targets; `cppzmq-dev` is a *recommended* dependency of gz-transport that `--no-install-recommends`
drops, and without it the plugin fails to generate on a `CPPZMQ::CPPZMQ` target; SITL run
with `--no-mavproxy` speaks on `tcp:5760` and streams no telemetry until asked, while
`wait_heartbeat` returns `None` on timeout rather than raising — so a probe aimed at the wrong
port reported a heartbeat from "system 0" and carried on; and the physics baseline was being
measured while the lockstep server was still running, which is why it first read 0.880.

**Correction — a probe artefact reported as a finding.** The first write-up of this section said
the vehicle climbed at 0.18 m/s and called it something to understand before scaling endurance.
It was the reader, not the aircraft. The probe asked for `MAV_DATA_STREAM_ALL` at 5 Hz — a
hundred-odd messages a second — then consumed *one* position report per half-second, so it walked
a growing backlog and every altitude it read was staler than the last. Reading the latest report
instead of the next one, and asking only for the one message type it uses, puts the climb at
6.2 s. The tell was that 72.7 s repeated to a tenth of a second across runs: flight dynamics vary,
a deterministic consumer pattern does not. The lesson is carried into WP2, where twelve agents
read telemetry exactly this way, and into the probe itself, which now reports the autopilot's own
clock beside the wall clock so the two can never be confused again.

**WP1 — the generator `T-05` (`src/realization/`). Done 2026-09-18, both halves.**
The generator was written first and, until the adapter existed, had only ever seen a fixture the
test wrote — which proves the generator and nothing about the models it is for.
`src/realization/adapter.ts` reads a run directory into `SimulationInput`, keying on **tags and
brief fields** and never on one run's literal names: `population.memberDef` says which definition
is the member, `#Node` at PA says which parts get built, a MoE's `kind` says budget or measure.
`npx tsx src/cli.ts simulate --out <run>` writes the artefacts and prints what it assumed.
On `examples/drone-swarm-v7` it reads 12 × SurveillanceDrone over 25 km², 2 machines with 13
states, 5 `#Node` parts, 8 coordination functions, 4 rules and 14 measures, and refuses nothing.
`test/integration/simulation-v7.test.ts` is the test that proves T-05 against a real model: nine
assertions over the mapping table's rows, including that every mapped state is a state the model
really has and that no budget is counted as a measure.

Running it on the real model immediately caught a false claim the fixture could not:
`fleet.yaml` asserted "endurance runs through the battery so the autopilot's own failsafe fires"
and emitted `SIM_BATT_CAP_AH`, `BATT_LOW_VOLT` and `BATT_FS_LOW_ACT`. WP0.4 had just measured
that those cannot work through the JSON backend. The battery parameters are gone from
`autopilot_params` — inert parameters made the fleet look as though the autopilot enforced the
endurance — replaced by a `charge_model` section naming `rotateRecharge` as the owner, why not the
autopilot, and what the demonstration therefore does not exercise. Two unit tests guard it: no
`BATT` parameter may return, and the old sentence may not.

Original scope, for the record: Input: a run directory. Output `sim/out/`:
`world.sdf` (area, sectors as ground decals, pads, ground station), `fleet.yaml` (instances, homes,
params), `scenario.yaml` (timeline: start, fault at T, optional recall), `mapping.yaml` (states ↔ modes,
functions ↔ behaviours), `trace.json`. Pure and unit-tested like the other transitions; a fake run
fixture; refuses with a clear message when the brief has no population.

### Where the generated world stands (2026-09-18), and the one thing still open

The world T-05 generates now loads and **arms all twelve autopilots (95 s)**, which it did not
before. Four defects were found by running it rather than by reading it, all of them silent:

- **No `gz-sim-imu-system`.** The ArduPilot plugin reads the member IMU; without that system the
  sensor produces nothing and SITL never receives a JSON frame. Twelve airframes sit in a world
  doing nothing and no error is printed anywhere.
- **`max_step_size` was 0.004.** WP0.3 measured that 2.5 ms already stops the EKF initialising.
  Now 1 ms, with the measurement quoted in the world file.
- **No `<spherical_coordinates>`.** Every reference world carries one; without a geodetic origin
  the autopilot has no home.
- **The sensors system with no camera in the world**, which initialises a render engine to draw
  nothing. WP4 adds it back with the camera it needs.

Two of my own test methods were also wrong, and both produced confident false conclusions:
`"Waiting for connection ...."` in SITL's log is it waiting for a **MAVLink client on 5760**, not
for the FDM — so a harness that never connects one sees "no JSON frame" in *any* world, including
the one that demonstrably flew twelve vehicles in WP0.3. And running **one** SITL against a
twelve-vehicle world leaves eleven plugins timing out, which is not the configuration the runtime
uses. Both are now known; the fair test is the whole fleet with a client attached.

**Resolved (2026-09-18), and the resolution is worth more than the fix.** The fleet arms and
flies in the generated world. Two real defects were found on the way, and one false one:

- **A `<plane>` collision only holds a vehicle up near the world origin.** Its declared size does
  not extend that: enlarging the floor threefold changed nothing, while moving the same vehicles
  to the origin made them rest, and a box of the same size held them at the corner. T-05 put the
  recharge pads at the area's corner — 2460 m out on each axis, 3479 m diagonally — so the whole
  fleet spawned 3.5 km from the origin, **fell through the floor, armed anyway, and never
  climbed**. The pads and the ground station now sit at the centre of the watched area, which is
  also the better placement: members return there from their sectors, and it is the shortest
  worst-case transit. A box floor works too and costs three times the real-time factor with
  twelve vehicles resting on it, so the cheap shape is kept and the vehicles put where it works.
- **Every SITL blocks until a MAVLink client attaches.** `"Waiting for connection ...."` in its
  log is that, not the FDM. A runtime that starts twelve autopilots and connects to one leaves
  eleven blocked, their plugins stalling the world — so WP2 connects every link before it does
  anything else, and a diagnostic that talks to one vehicle in a twelve-vehicle world measures
  only its own mistake.
- **The world was never slow.** An earlier version of this section recorded that the generated
  world ran at 0.221 of real time against the probe's 0.871 and concluded that something in it
  cost four times what the probe's did. It did not. Running the *probe* world through the same
  harness gave the same 0.068, and the machine turned out to be carrying an unrelated
  sixteen-core workload at a load average of 26. **Every real-time factor measured while that
  was running is worthless**, in both directions. The figures that stand are WP0.3's, taken on a
  quiet machine; anything measured on 2026-09-18 after midday needs taking again.

  The lesson is cheap to state and was expensive here: a performance measurement without a
  control is not a measurement. The control — the same harness against a world already known to
  be fast — took one run and would have saved the afternoon.

### WP2 and WP3 result (2026-09-18) — implemented, and the finding landed

**Both done.** `sim/agents/` is the runtime and `sim/runtime/run.py` flies the scenario T-05
generated. 31 unit tests, none of which start Gazebo: the monitors and metrics are pure functions
over the event log and are tested against logs written by hand, including logs that break the
rules they check; the agents run against a fake autopilot.

| Piece | What it is |
|---|---|
| `agents/log.py` | JSONL events, each carrying the qualified name of its model element |
| `agents/mesh.py` | the bearer, as an interface. In memory for the forerunner; stage 2 swaps the class |
| `agents/member_agent.py` | one drone: the model's own states, the four `#Coordination` functions by name, and the duty cycle WP0.4 proved is the agent's |
| `agents/ground_agent.py` | `taskMission`, `recallAndLand`, and the sector board |
| `agents/monitors.py` | the brief's rules, checked over the run |
| `agents/metrics.py` | the two measures, computed from the log |
| `agents/mavlink_link.py` | one autopilot, with WP0.2/0.3's lessons as invariants |
| `runtime/run.py` | WP3: the scenario, live or `--offline` |

**The offline run of v7's own scenario** — twelve members, twelve sectors, 1200 s:

| Measure | Target | Estimate | Simulated | |
|---|---|---|---|---|
| `areaUnderWatchShare` | ≥ 0.9 | **0.92** | **0.3915** | ✗ |
| `coverageLossOnMemberLoss` | ≤ 0.25 | **0.0833** (derived) | **0.0833** | ✓ |

**This is the finding, and it arrived where it was predicted.** Before any of this ran, the plan
recorded that the brief's own budgets put 4.8 of twelve members airborne and so cap coverage near
0.40 against an estimate of 0.92. The runtime produced **0.3915**. And the contrast between the
two rows is the whole argument: `coverageLossOnMemberLoss` is **derived** in the model by
`assert constraint { == 1.0 / fleetSizeValue }`, and the simulation reproduces it exactly;
`areaUnderWatchShare` is a **bare literal** with a prose justification, and the simulation
contradicts it by a factor of two. The measure that showed its arithmetic survived contact with
a runtime. The one that did not, did not.

Rules over that run: `RecallWins` held across 23 recalls; `ReturnsWhenIsolated` held for all
twelve; `GeofenceBreachEndsWatch` held but is reported **never exercised**, because nothing in
the forerunner breaches a geofence; `QuarantinedStaysOut` is reported **not checked**, because
nothing in the model says which state arms it.

Five defects were found by running it, each of which had made the runtime *look* like it worked:

- **A monitor that guessed.** Every `winsUntil` rule was armed on `Recalled`, so
  `QuarantinedStaysOut` came back "held" on the strength of a recall it has nothing to do with —
  a pass for a rule nobody had checked. Rules whose trigger cannot be identified are now reported
  as not checked, and the runtime prints three outcomes rather than two.
- **A measure with no window.** `coverageLossOnMemberLoss` charged the loss with everything that
  happened afterwards and reported 1.0, because the fleet rotated into its recharge an hour
  later. True about the coverage curve, false about the loss. The window is now a parameter and
  is printed beside the number.
- **The ground could not speak.** `Mesh.broadcast` dropped messages from a sender that was not a
  member, and the ground is not a member, so every tasking it sent went nowhere: the fleet
  launched once and never flew again. Coverage read 0.20 and looked like a plausible finding.
- **A member left the moment its reserve was reached**, which is twelve members going home at
  once, not `rotateRecharge`. It now asks for a relief and keeps watching until one arrives, or
  until the flight budget is genuinely spent.
- **The loss that never happened.** The scenario's `member lost` found nothing airborne to kill
  and skipped silently, so the measure was simply absent from the report — indistinguishable
  from a measure nobody implemented. It now records why it could not be injected.

**A sixth defect, found by the first live attempt, and the worst of them.** Twelve autopilots
were started against real Gazebo while the host was carrying an unrelated sixteen-core workload;
none of them armed inside ten minutes, because arming needs *simulated* time and a loaded machine
starves it. The runtime carried on regardless and **reported measures** — a coverage of 0.0 and a
rule verdict of `ReturnsWhenIsolated: BROKEN`. That is a fabricated finding about an architecture
that never left the pad, and it is exactly the kind of output this whole exercise exists to make
impossible. The runtime now refuses: `worth_reporting` is a tested function, a fleet where
nothing armed produces no measures and no verdicts at all, and a partial fleet is reported with
every number labelled as being over the fleet that flew rather than the fleet the brief
specifies. It also says, where the reader will see it, that this is usually the machine rather
than the model.

**Live validation: done, at a reduced scale, and labelled.** Two members flew the generated
scenario under real Gazebo physics and real ArduPilot autopilots: both armed, launched, climbed
and reached `Watching` on their own sectors at t = 25.2 s and 26.2 s of *simulated* time, and the
run measured `areaUnderWatchShare = 0.8286` over 150 s. Every element name in that log is the
model's. The fleet size and the duration were reduced so the run could finish against an
unrelated sixteen-core workload, and both reductions are recorded in the log and printed on the
report, so those numbers can never be read as the brief's.

**Three defects the live path found, none of which the offline path can:**

- **Arming asked once.** The runtime requested arm before the EKF had a position and never asked
  again, then waited out its whole timeout. Found because the refusal above printed the
  autopilots' own words — `EKF3 IMU0 origin set`, `using GPS` — which said they were ready and
  the runtime was not asking. Now it asks until they answer.
- **The scenario clock followed the wall.** `at: 720` means seven hundred and twenty seconds of
  *simulated* time, and a simulation below real time has had less of it than the wall suggests.
  At a factor of 0.07 the whole timeline fired before the aircraft finished climbing, so a fleet
  that armed and flew correctly reported a coverage of zero. The clock now follows the fleet's
  own boot time. Offline this is structurally invisible: there, the two clocks are the same one.
- **A truncated run accused its own members.** The live run ended at 150 s while both members
  were watching their sectors exactly as asked, and `ReturnsWhenIsolated` reported them as
  breaches — a fabricated finding against an architecture the run never gave a chance to
  conclude. A member still away when the log stops is now excluded from the judgement and counted
  separately, and a run where every member is in that position concludes nothing.

### The full live run (2026-09-18), and the finding only it could produce

Twelve members, twelve sectors, 1200 s of simulated time, real Gazebo and twelve ArduPilot
autopilots, through `sim/fly.sh` end to end. All twelve armed, launched, climbed and took their
sectors. `areaUnderWatchShare` measured **0.1791** against an estimate of 0.92 — and against the
**0.3915** the same scenario gives offline.

The gap between those two numbers is the point, and it is a second finding about the
architecture rather than a discrepancy between two simulators:

| | |
|---|---|
| the flight budget the brief fixes | **240 s** (40 min at a time scale of 10) |
| how far the sector centres are from the pads | **625–2509 m** |
| what the return leg alone costs, measured | **142–306 s** |

**A member spends up to more than its whole flight budget just coming home.** The brief's
endurance is stated as though a member spends it watching; at the area's own scale most of it is
transit. That is invisible offline, where a cooperative stand-in is over its sector the moment it
is told to go, and it is invisible to the duty-cycle gate, which bounds coverage at 0.40 by
assuming a member watches for every second it is airborne. The flight measures 0.18 because it
does not.

Two things follow:

- **A candidate for the next gate**, recorded in NEXT.md: a member's flight endurance has to cover
  the transit to its sector and back, and the brief's own numbers can say whether it does — but
  only once the model states a cruise speed, which v7 does not. That is the same shape as the
  duty-cycle gate: the arithmetic is available, the missing piece is one number nobody wrote down.
- **`coverageLossOnMemberLoss` was not measured in this run.** The scenario injects the loss at
  t = 720 s and at that moment every member was recharging, so there was no coverage for a loss to
  cost. The runtime records why rather than omitting the measure silently — which is the
  behaviour added after an earlier run left it absent and indistinguishable from unimplemented.

The rules: `RecallWins` held across 12 recalls. `ReturnsWhenIsolated` is reported *never
exercised* — all twelve were still away when the run ended, and none is judged for it.
`GeofenceBreachEndsWatch` never exercised, `QuarantinedStaysOut` not checked.

Deliberately deferred, and written here so it is a decision rather than an omission: the mesh is
in memory. Stage 2 cuts the link to animate the trade-off, and that is when a UDP implementation
earns its place; a run with twenty-five processes does not need a twenty-sixth before anything
has flown. Everything above `Mesh` speaks the interface.

**WP2 — the runtime (`sim/`), as originally scoped.** `docker/Dockerfile` + `compose.yaml` (gz server, N SITL, agents,
recorder); `agents/` in Python + pymavlink: a per-vehicle agent and a ground agent implementing the four
coordination functions as small, named, separately testable behaviours over a message bus that stands in
for the mesh (UDP multicast inside the compose network — so stage 2 can cut it); `monitors/` for the
three rules; `metrics/` for the two measures; everything logs to `sim/out/run-<ts>/` as JSONL.

### The finding this is expected to produce, written down before it runs

The plan says a simulated value that contradicts an estimate is a finding, and that the demo must
not be tuned until it agrees. One such contradiction is visible from arithmetic alone, so it is
recorded **now**, before the runtime exists, so that the result reads as the point rather than as
a bug discovered late.

The brief fixes `fleetSize = 12`, `memberFlightEnduranceMinutes = 40` and
`memberRechargeMinutes = 60`. A member is therefore airborne 40/100 of the time, and the steady
state is **4.8 of 12 members in the air**. The v7 architecture estimates
`areaUnderWatchShare = 0.92` against a target of 0.9.

Those two cannot both hold under T-05's reading of the area, which gives each member one sector:
twelve sectors watched by 4.8 members is **0.40**, not 0.92. Holding 0.9 that way would need 27
members, or one member would have to watch 2.25 sectors at once.

The model does not say which. **No watch footprint, sensor range or sector count appears anywhere
in v7** — the estimate is a bare literal with a prose justification about on-board coordination
keeping rotation running, and nothing connects it to the duty cycle the brief fixes. Its sibling
`coverageLossOnMemberLoss` is derived (CV-17) by `assert constraint { == 1.0 / fleetSizeValue }`
and is checkable; `areaUnderWatchShare` is not. The model's own trade-off commentary even says of
alternative 2 that "1/12 coverage loss ignores that only about 4–5 drones are airborne at once" —
the arithmetic was noticed about one measure and not the other.

So the expected result is: **the simulation will report `areaUnderWatchShare` far below the
estimate, and that is a true finding about the architecture, not a defect of the simulation.**
Three things follow, and none of them is "tune the simulation":

1. **T-05's one-sector-per-member grid is an assumption, not a model fact.** It is already
   declared in `assumptions`, and the report must repeat it beside the number, because the
   measured coverage means "of the twelve sectors T-05 drew", not "of the area".
2. **The honest reading is that the estimate is unfalsifiable as stated.** A measure about area
   needs a footprint to be checkable at all. The report says that, rather than declaring the
   architecture wrong on a reading it never committed to.
3. **A workflow improvement falls out of it** (recorded in NEXT.md): a measure the brief's own
   budgets determine should be derived like `coverageLossOnMemberLoss`, not stated as a literal.
   The gate that would have caught this is one that asks an `#Estimate` whose inputs are all
   brief budgets to show its arithmetic.

**WP3 — the scenario.** Rotation + handover for ≥ 2 full cycles, then kill one vehicle mid-watch;
acceptance: no sector unwatched longer than the handover budget, coverage ≥ target through rotation,
coverage drop after the loss ≤ target, and recovery time reported.

**WP4 — the 3D output. One constraint measured early, 2026-09-18, by recording a clip.**

Recording works headless: Gazebo's own `camera-video-recorder` system encodes server side, driven
by a service call, so no GUI and no display is involved (`sim/probe/record-demo.sh`; mp4, avi or
ogv, and anything else as a transcode of that one recording). What the first clips showed is that
the hard part of WP4 is not capture — it is **that a photoreal wide shot cannot show this swarm.**

The first recording was a uniform grey rectangle. Not a failure of rendering: the drones were
there, six pixels across, on an untextured plane with no horizon. Reframing on the fleet's own
volume, adding a sky, and laying a tile under each member made it a real picture — and the
aircraft were still small, because four 0.5 m airframes spread over 10 m cannot fill one frame.
A close shot (`FRAME=14`) shows an aircraft clearly, and then holds only one or two of them.

**At the forerunner's real scale this gets far worse, and it is arithmetic, not taste.** The
brief's 25 km² is 5000 m on a side; twelve members in a 4×3 grid sit ~1250 m apart. A frame wide
enough to hold the fleet is ~5 km across, so a 0.5 m drone is **0.13 px** at 1280 wide. There is
no lens, resolution or lighting that fixes that.

So WP4 is not "point a camera at it":
- **Members need markers sized for the shot** — a beacon or trail per member, scaled to the frame
  rather than to the airframe, coloured per member so a handover is visible as a colour changing
  sector. A marker is a rendering device and must be labelled as one, never mistaken for a sensor
  footprint. Adding a link to the vehicle model costs mass, so any marker carries a negligible
  inertial or it changes the flight it is supposed to depict.
- **The legible view is the schematic one**: the sector grid as a plan, coloured by who is
  watching it, with the measures live — the overlay was always in the plan, and it is now clear
  the overlay *is* the demonstration and the photoreal view is the supporting shot, not the other
  way round.
- **Both, composited**: a close chase on one member showing that this is a real aircraft under a
  real autopilot, beside the plan view showing what the fleet is doing. That is the pairing the
  report's "claimed vs simulated" table needs anyway.

Original scope: Headless camera(s): one overview, one chase; overlays burnt in with ffmpeg
from the run log — sector heat-map state, per-drone model state, the measures live, the time-scale
factor, and the element name of whatever behaviour is acting. Output `demo.mp4` + stills.

### WP4 result (2026-09-18) — the schematic is the demonstration

`sim/runtime/overlay.py` turns a run's event log into a self-contained HTML replay: the sector
grid over simulated time, each cell coloured and labelled with the member holding it, the
coverage measure moving against its target beside it, and the member loss when it lands. One
file, no ffmpeg, no GPU, no display — a run on a loaded machine still produces something a person
can watch, and the same file opens on a phone.

This is the inversion the earlier measurement forced. A photoreal frame wide enough to hold
twelve members 1250 m apart renders a 0.5 m drone at an eighth of a pixel, so the camera cannot
be the demonstration; it is the supporting shot that proves these are real aircraft under real
autopilots. What is legible at the brief's scale is what the architecture is about — which sector
is watched, by whom, and what that does to the measure.

Two properties it keeps, and both are the point:
- **It can only show what the run did.** Frames come from `events.jsonl` and nothing else, so the
  replay cannot depict a handover the fleet never made. A test asserts that an empty log draws an
  empty grid rather than a plausible one.
- **It carries its own caveats.** The page states, where a viewer will read it, that a sector
  counts as watched when a member is over it and that the model states no sensor footprint — so
  this is T-05's reading of coverage, not the architecture's. A run flown offline, or with a
  reduced fleet, says so on the page rather than in a file nobody opens.

Four tests cover the frame builder, including the empty-log case.

### WP5 and WP6 result (2026-09-18)

**WP5 — the report** (`sim/runtime/report.py`). Three columns and the rest is context: what the
brief asked, what the architecture claimed, what the run did. The claim comes from the model —
the adapter now reads `#Estimate` at PA, and carries it through `mapping.yaml` — so a
contradiction is printed as a finding with both numbers beside each other. On v7:

| Measure | Target | Architecture | Simulated | |
|---|---|---|---|---|
| `areaUnderWatchShare` | ≥ 0.9 | 0.92 *(stated)* | 0.3915 | **contradicts** |
| `coverageLossOnMemberLoss` | ≤ 0.25 | *derived by constraint* | 0.0833 | agrees |

The report always prints three things a reader needs and a flattering report would omit: what was
**not exercised** (a rule that held because nothing tested it is not evidence, and it says so per
rule), what the numbers **mean** (coverage over sectors T-05 drew is not coverage of the area),
and **how to reproduce it**, with this run's own arguments.

**WP6 — the wire-in** (`sim/fly.sh`). One command from a finished model run to a report:
generate, materialise the vehicles, start the world and the autopilots, fly the scenario, write
the report and the replay. `--offline` does the same without Gazebo in seconds; `MEMBERS` and
`DURATION` shrink a run and are recorded in the results so a reduced run can never be read as the
brief's. The host/image split is forced rather than chosen: the stock airframe exists only inside
the image, and the model only outside it.

A run now finishes as a finished run — `events.jsonl`, `results.json`, `README.md`, `replay.html`
— rather than as a JSON file someone still has to interpret.

**WP5 — the report, as originally scoped.** `sim/out/run-<ts>/README.md`: claimed vs simulated per measure (estimate, target,
simulated, verdict), rule monitors (held / broken with the trace), what was not exercised, the mapping
table with element names, reproduction command. Linked from the run's `audit/final/README.md`.

**WP6 — wire-in and docs.** `mbse-workflow simulate --out <run>` (generate → up → run → report →
down); README section "From model to flight"; NEXT.md; memory. Optional later step S80 in the step
table, never blocking, like S60.

### Stage 2 result (2026-09-18) — the trade-off, run rather than argued

`sim/tradeoff.sh` runs the same generated world twice, changing one thing — where handover and
rotation are decided — and cutting the ground link at the same moment in both.

| | decided **on board** | decided **on the ground** |
|---|---|---|
| watch, whole run | 0.3908 | 0.1608 |
| **watch after the link is cut** | **0.2544** | **0.0000** |

The ground-decided architecture goes to **zero**: its members ask to rotate, nothing answers, they
hold station until their budget runs out, and no order to relaunch can reach them again. That is
what v7's own trade-off commentary predicted in words — "drones fly their last assignment,
rotation stops, and nothing plans a landing" — and it is now a number. **The decision v7 took is
vindicated; the numbers on both sides of it are not.**

**The third finding — corrected 2026-09-18, and the correction matters more than the finding.**
This section claimed that both PA alternatives estimated `groundLinkLossAreaUnderWatchShare` at
0.9 with the same doc, and that the decisive measure therefore discriminated nothing. **That was
wrong.** It came from grepping `build/6_PA.alt-*.sysml` — assembled copies — instead of
`fragments/`, where the authored alternatives read **0.55 and 0.91**. v7's decisive measure did
its job and separated the alternatives cleanly.

What is true, checked against the recorded trade-off: **four of v7's fourteen measures gave both
alternatives the same number** — `reportLatencySeconds`, `reportsLostInLinkGap`,
`missedDetectionShare`, `falseAlarmsPerHour`. So a third of that comparison turned on nothing,
which is worth a check, but it is a claim about dead weight beside the decision rather than about
the decision itself.

The lesson is the one this project keeps relearning in new costumes: a build artefact is not the
thing that was authored, and a measurement of the wrong file is not a measurement.

That suggests a third gate, recorded in NEXT.md: where alternatives are compared, at least the
measures that name the thing they differ about must differ in their estimates, or the comparison
is decided on measures that do not measure the difference.

**Two defects in this study itself**, both of which made it useless while looking like it worked:

- **The ground tasked a fleet it could no longer reach.** Its orders called `launch()` directly
  instead of travelling down the link, so cutting the link changed nothing and the two
  architectures measured the same to four decimal places. A trade-off study that cannot tell its
  alternatives apart is worse than none, because it reads as evidence that they are equivalent.
- **The ground relaunched members under *both* architectures**, which erased the difference a
  second way. On-board members now claim a dark sector between themselves over the mesh —
  `redistributeCoverage`, decided where the architecture says it is decided — and the ground
  stands back. Two tests pin the distinction: a ground-decided fleet cut off must hold station and
  not rotate; an on-board fleet must relaunch with no ground at all.

### Five defects closed (2026-09-18), and what fixing the first one did to the numbers

**1. `Watching` began on departure, not on arrival.** A member counted as watching its sector from
the moment it was *told* to go there. At this brief's scale a station is 625–2509 m out, so
minutes of transit were reported as coverage and **every watch-share figure in this document was
an over-estimate**. Members now enter `Watching` when they are within 75 m of their sector's
centre, and the offline stand-in flies the distance instead of teleporting.

The effect is the strongest evidence in the whole exercise that the two paths now model the same
thing:

| | before | after |
|---|---|---|
| offline `areaUnderWatchShare` | 0.3915 | **0.1788** |
| live, twelve members | 0.1791 | — |

**The offline and live figures now agree to three decimal places.** The entire divergence between
them was this defect. T-05 also declares a `cruise_speed_mps` — the brief's when it fixes one, an
assumption otherwise, stated in `fleet.yaml` and in the run's assumptions because at this scale
that number decides most of what a flight budget buys.

**2. Seven of the model's thirteen functions are not implemented**, and the report now says so by
name: `relayLink`, `correlateTracks`, `handOverTrack`, `admitMember`, `commandSupervision`,
`presentStatusPicture`, `acknowledgeReport`. The list is read from the agents rather than written
by hand, so a function added to the model and not to the runtime cannot quietly pass as flown.

**3. `QuarantinedStaysOut` was never checked**, because the monitor had a hard-coded list of words
that could arm a rule. It now looks for a state *the model declares* whose name appears in the
rule's name — `QuarantinedStaysOut` → `Quarantined` — and falls back to the hints only for rules
that name a situation rather than a state.

**4. Two rules were never exercised.** T-05's scenario now injects a quarantine and a clearance
breach when the model states rules about them, so `QuarantinedStaysOut` and
`GeofenceBreachEndsWatch` are checked against something that happened rather than reported as
vacuous. Both now read *held, 1 occurrence*.

**5. An injection at an unlucky instant was skipped.** The member loss fired at t = 720 when
nothing was airborne, and the measure simply vanished from the report. Every injection the
scenario asks for is now deferred until it can happen, with the delay recorded beside it.

Three further defects surfaced while fixing these, all in the offline stand-in and all of the
same kind — it obeyed instantly in geography as well as in everything else:

- it never descended on arriving home, so recalled members hovered over their pads for ever,
  never landed, never recharged, and the fleet went quiet after one sortie;
- `takeoff` did not cancel the pending return, so after the fix above every relaunch was undone
  by the next tick and the fleet sat at altitude zero;
- and the honest consequence of modelling transit at all: **all twelve members returned beyond
  their flight budget**, which the runtime now records as a fault against
  `memberFlightEnduranceMinutes`. That is the transit gate's warning, arriving as measurement.

### The follow-on defects, closed (2026-09-18)

**The reserve ignored the way home.** A member turned back at a flat 80% of its budget however
far out it was, so a station 2.5 km away was left with its whole return leg still to fly. The
reserve is now the share *plus* the transit home, computed from the member's own position and the
fleet's cruise speed.

That did not remove the overruns, and it is important that it did not: **21 returns still finish
beyond the flight budget, the worst by 168 s.** With a usable budget of 192 s and the furthest
station 167 s away, a member has to turn for home before it has arrived — there is no departure
time that works. The agent now leaves as early as it can and the overrun is recorded as a fault
against `memberFlightEnduranceMinutes`. That is the transit gate's warning, arriving as
measurement on the fleet the brief specifies.

**Two more of the model's functions are implemented**, `admitMember` and `relayLink`, chosen
because they need no detection model: admission is a decision about membership, and a relay is a
member saying whether it can carry a peer's traffic — which is a refusal worth having the moment
stage 2 starts cutting links. The remaining five now carry **why** they are absent rather than
just their names, because a bare list invites the reader to assume nobody got round to them:
three need a detection model this forerunner deliberately does not have, one is an operator
interface with no operator, and one supervises a mission this scenario does not vary.

**`coverageLossOnMemberLoss` measured a drop from zero to zero.** The loss was injected in the
very tick its victim began watching, so both landed in one coverage sample and the measure saw
nothing happen. Injections now act at the top of a tick, on state the log already recorded. The
measure reads **0.0833** — one twelfth, exactly the value the model derives by
`assert constraint { == 1.0 / fleetSizeValue }` — with a 41 s recovery.

So both computable measures now agree with the architecture where it derived them and contradict
it where it stated a literal, on both paths:

| Measure | Architecture | Offline | Live |
|---|---|---|---|
| `areaUnderWatchShare` | 0.92 *(stated)* | **0.179** | **0.1791** |
| `coverageLossOnMemberLoss` | *derived* | **0.0833** | — |

**Stage 2 (after the forerunner):** cut the ground link for both architectures (needs LA alt-1's
ground-centric agents too) — the side-by-side that animates the trade-off. **Stage 3:** rules on the
autopilot (recall during watch, geofence breach). **Stage 4:** PX4 image behind the same adapter.

## Verification

Unit tests for T-05 and for each behaviour, monitor and metric (pure functions over recorded logs);
a recorded 60-second single-vehicle log as fixture; one integration test that runs the stack headless
for two scaled minutes when `MBSE_SIM=1` (opt-in, like `test:live`). No paid model calls anywhere.

## Risks

- 12 × SITL + Gazebo physics may not hold real time on this CPU → WP0.3 decides between 12 full-physics
  vehicles and 12 with a reduced physics rate; the fleet size is a brief budget and is not reduced silently.
- EGL headless rendering on the Vega iGPU from inside a container is the single point the video depends
  on → WP0.2 first; fallback is software rendering at low resolution, slower but correct.
- The v7 estimates are claims; a simulated value that contradicts one is a **finding**, reported as such —
  the demo must not tune the simulation until it agrees.

## Order

WP0 → WP1 → WP2 → WP3 → WP4 → WP5 → WP6. Sudo is needed once, before WP0.2.
