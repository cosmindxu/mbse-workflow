# `sim/` — the model, flown

T-05 (`src/realization/simulation.ts`) turns a finished run into a world, a
fleet and a scenario. This directory is what runs them: Gazebo Harmonic for the
physics and the picture, ArduPilot SITL for the autopilots, and — once WP2
lands — the coordination agents, the rule monitors and the measure metrics.

Nothing here invents a number. Every artefact T-05 writes carries the qualified
name of the model element it came from, and `sim/out/<run>/trace.json` is the
whole map.

## What the host needs

Docker, and your user in the `docker` group:

```
sudo usermod -aG docker $USER    # once; then log out and back in
```

A shell that predates that change can still reach the daemon with
`sg docker -c '<command>'`. Nothing else needs root.

Rendering is **hardware EGL through `/dev/dri`**. On this host (AMD Renoir
iGPU, kernel `amdgpu`) the container reaches the GPU on the EGL *device*
platform — `AMD Radeon Graphics (radeonsi, renoir)`, OpenGL 4.6 — while the
*surfaceless* platform silently falls back to `llvmpipe`. That is why the image
sets `EGL_PLATFORM=device`, and why the smoke test prints the renderer before
it prints anything else: a software render is correct and far too slow, and it
is a decision to take, not a thing to discover in a video.

## Build

```
sg docker -c 'docker build --build-arg JOBS=12 -t mbse-sim:harmonic sim/docker'
```

Pinned, so a report can be reproduced: ArduPilot `Copter-4.7.1`,
`ardupilot_gazebo` at `082a0fe`, Gazebo Harmonic from the OSRF `noble`
repository. The base is Ubuntu 24.04 because Harmonic ships for noble and not
for the 26.04 host.

## Probe (WP0.2)

```
sg docker -c 'docker run --rm --device /dev/dri \
  --group-add $(getent group render | cut -d: -f3) \
  -v '"$PWD"'/sim:/sim mbse-sim:harmonic /sim/probe/wp02-smoke.sh'
```

It reports the renderer, the real-time factor idle and in flight, and whether
one vehicle armed, climbed to 10 m and landed. The real-time factor is what
WP0.3 sizes twelve vehicles and the time-scale factor from — measured, not
guessed.

## Layout

| Path | What it is |
|---|---|
| `docker/Dockerfile` | the pinned runtime image |
| `probe/wp02-smoke.sh` | WP0.2: renderer, real-time factor, one flight |
| `probe/takeoff.py` | arm, climb, land over MAVLink; reports, does not assert |
| `probe/wp03-fleet.sh` | WP0.3: N vehicles at a given physics step, measured while airborne |
| `probe/fleet_world.py` | generates an N-vehicle world; `--camera` adds the render back |
| `probe/fleet_fly.py` | arms and flies N autopilots together |
| `probe/wp04-battery.sh` | WP0.4: does the battery drain, and does the failsafe fire? |
| `probe/battery.py` | `--measure` the hover draw, or `--watch` for the failsafe |
| `probe/rtf.py` | simulated time per second of wall clock, across a window |
| `probe/cpu.py` | where the CPU goes, sampled rather than averaged over a lifetime |
| `fly.sh` | WP6: generate → fly → report → replay, in one command |
| `agents/` | WP2: the members, the ground, the mesh, the monitors, the measures |
| `runtime/run.py` | WP3: the scenario, live or offline |
| `runtime/report.py` | WP5: claimed against simulated, and what was not exercised |
| `runtime/overlay.py` | WP4: the run as a replay, from the event log alone |
| `runtime/models.py` | one vehicle model per member, from the airframe the image carries |
| `probe/record-demo.sh` | records the fleet flying to a video file, headless |
| `out/` | generated and recorded; not under version control |

## From model to flight

```
sim/fly.sh examples/drone-swarm-v7              # generate, fly, report, replay
sim/fly.sh examples/drone-swarm-v7 --offline    # no Gazebo; seconds, on any machine
MEMBERS=4 DURATION=300 sim/fly.sh <run>         # smaller and shorter, labelled as such
```

It leaves `events.jsonl` (what happened, in the model's own element names),
`results.json`, `README.md` (claimed against simulated) and `replay.html` (the
run, watchable).

The generation half runs on the host, because that is where the model and
Sysprose are; the flying half runs in the image, because that is where Gazebo
and the autopilots are. That split is forced rather than chosen — the stock
airframe exists only inside the image and the model only outside it.

Two things a reader should know before quoting a number from it:

- **A reduced or shortened run says so** in the report and on the replay. A
  coverage over four sectors is not a coverage over twelve.
- **A run where nothing armed produces no numbers at all.** That refusal
  exists because the runtime once reported a coverage of 0.0 and a broken rule
  for twelve aircraft that never left their pads.

## A clip, with no display anywhere

```
sg docker -c 'docker run --rm --device /dev/dri \
  --group-add $(getent group render | cut -d: -f3) \
  -v '"$PWD"'/sim:/sim mbse-sim:harmonic /sim/probe/record-demo.sh 12'
```

Gazebo's own `camera-video-recorder` system does the encoding, server side, so
no GUI and no X display is involved. `FORMAT=mp4|avi|ogv` picks what the
recorder writes; `ALSO=avi,webm,gif` transcodes that same recording into other
containers afterwards — a transcode, never a second run, because two runs of a
simulation are two different flights. **The file appears only when recording
stops and the encoder flushes**, not while it rolls.

This is not the forerunner demo: no sectors, no handover, no recharge rotation,
no injected loss, no overlays. It shows that the stack renders and records
headless, which is the part WP4 rests on.

Two things every one of these gets right, because getting them wrong cost time:
one read pass per MAVLink link dispatched by type (two type-filtered reads in
one loop discard each other's messages), and no fixed wait for arming (it grew
25 s → 52 s → 148 s from one vehicle to twelve).

The plan this follows, work package by work package, is
`docs/plans/swarm-3d-forerunner.md`.
