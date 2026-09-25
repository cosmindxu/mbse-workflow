#!/usr/bin/env python3
"""WP3 — the scenario, flown.

Reads what T-05 generated for a run (`fleet.yaml`, `mapping.yaml`,
`scenario.yaml`), materialises the vehicle models, starts Gazebo and one
autopilot per member, executes the scenario's own timeline, and writes the
event log the monitors and metrics are computed from.

Nothing in here decides what happens: the timeline, the fleet size, the duty
cycle, the sectors, the rules and the measures all come out of the generated
files, which came out of the model. What this adds is the running of it.

Two operational facts, both measured rather than assumed:

  * **Every autopilot needs a client attached before anything works.** SITL
    blocks until one connects, and an unconnected instance's Gazebo plugin
    stalls the shared world for everybody. So all links are opened first.
  * **Arming has no fixed duration.** 25 s for one vehicle, 52 s for four,
    148 s for twelve. Everything waits on a condition.

It can also run with `--offline`, which flies the same scenario with no Gazebo
and no autopilots at all — the agents against cooperative fakes. That is not a
substitute for the real thing and the report says so, but it exercises the
scenario, the monitors and the metrics on any machine in seconds.
"""
from __future__ import annotations

import argparse
import json
import pathlib
import subprocess
import sys
import time

import yaml

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "agents"))

from ground_agent import GroundAgent          # noqa: E402
from log import EventLog                      # noqa: E402
from member_agent import Duty, MemberAgent, States  # noqa: E402
from mesh import Mesh                          # noqa: E402
from metrics import (coverage_after_ground_loss, coverage_over_time,  # noqa: E402
                     loss_on_member_loss, against_target)
from monitors import check_rules, worth_reporting  # noqa: E402

ARDUCOPTER = "/opt/ardupilot/build/sitl/bin/arducopter"
DEFAULTS = (
    "/opt/ardupilot/Tools/autotest/default_params/copter.parm,"
    "/opt/ardupilot/Tools/autotest/default_params/gazebo-iris.parm"
)


class CooperativeAutopilot:
    """A stand-in for a run with no Gazebo — which still has to fly the distance.

    It obeys instantly in everything except geography. An earlier version
    teleported: `goto` simply set the altitude and the member was over its
    sector in the same tick. That hid a real defect for a whole day — members
    counted as watching while they were still minutes away — and it made the
    offline watch share twice the live one for reasons nobody could see. It now
    moves at the fleet's cruise speed, which is the one thing about a transit
    that matters.
    """

    def __init__(self, index: int, speed: float = 15.0, tick: float = 1.0) -> None:
        self.index = index
        self.altitude = 0.0
        self.speed = speed
        self.tick = tick
        self._at = (0.0, 0.0)
        self._target = (0.0, 0.0)
        self._returning = False

    def position(self) -> tuple[float, float]:
        return self._at

    def pump(self) -> None:
        """One tick of travel toward wherever it was last sent."""
        north, east = self._at
        target_n, target_e = self._target
        dn, de = target_n - north, target_e - east
        distance = (dn * dn + de * de) ** 0.5
        step = self.speed * self.tick
        if distance <= step or distance == 0:
            self._at = self._target
            # Arrived. If it was coming home, it lands — which it did not do
            # before, so recalled members flew home and hovered there for ever,
            # never reached Landed, never recharged, and the fleet went quiet
            # after one sortie.
            if self._returning:
                self.altitude = 0.0
            return
        self._at = (north + dn / distance * step, east + de / distance * step)

    def takeoff(self, altitude: float) -> None:
        self.altitude = altitude
        # Taking off is the opposite of coming home, and forgetting to say so
        # left the descent from the last sortie still armed: every tick after a
        # relaunch, `pump` saw a member at its home target with `_returning`
        # set and put it back on the ground. The fleet flew one sortie and then
        # sat on its pads for the rest of the run, at altitude zero.
        self._returning = False

    def goto(self, north: float, east: float, altitude: float) -> None:
        self.altitude = altitude
        self._target = (north, east)
        self._returning = False

    def return_to_launch(self) -> None:
        self._target = (0.0, 0.0)
        self._returning = True
        if self._at == (0.0, 0.0):
            self.altitude = 0.0

    def land(self) -> None:
        self._target = (0.0, 0.0)
        self._returning = True
        if self._at == (0.0, 0.0):
            self.altitude = 0.0


def load(run: pathlib.Path) -> tuple[dict, dict, dict]:
    fleet = yaml.safe_load((run / "fleet.yaml").read_text())
    mapping = yaml.safe_load((run / "mapping.yaml").read_text())
    scenario = yaml.safe_load((run / "scenario.yaml").read_text())
    return fleet, mapping, scenario


def build_fleet(fleet: dict, mapping: dict, log: EventLog, links: dict,
                *, decides_locally: bool = True) -> tuple[dict, GroundAgent, Mesh]:
    root = fleet["member_definition"].split("::")[0]
    duty = Duty(
        flight_seconds=float(fleet["duty_cycle"]["flight_seconds"]),
        recharge_seconds=float(fleet["duty_cycle"]["recharge_seconds"]),
        time_scale=float(fleet["duty_cycle"]["time_scale"]),
    )
    sectors = {s["id"]: (float(s["centre"][1]), float(s["centre"][0])) for s in fleet["sectors"]}
    states = States.from_mapping(mapping)
    members = {
        int(i["id"]): MemberAgent(
            index=int(i["id"]),
            sector=int(i["sector"]),
            link=links.get(int(i["id"])),
            mesh=None,  # set below, once every member is known
            log=log,
            duty=duty,
            sectors=sectors,
            watch_altitude=float(fleet.get("watch_altitude_m", 60)),
            arrival_radius=float(fleet.get("arrival_radius_m", 75)),
            cruise_speed=float(fleet.get("cruise_speed_mps", 15)),
            root=root,
            states=states,
            decides_locally=decides_locally,
        )
        for i in fleet["instances"]
    }
    mesh = Mesh(list(members))
    for member in members.values():
        member.mesh = mesh
    ground = GroundAgent(members=members, mesh=mesh, log=log,
                         sectors=[s["id"] for s in fleet["sectors"]], root=root)
    return members, ground, mesh


def start_gazebo(run: pathlib.Path, models: pathlib.Path) -> subprocess.Popen:
    import os
    env = dict(os.environ)
    env["GZ_SIM_RESOURCE_PATH"] = f"{models}:{env.get('GZ_SIM_RESOURCE_PATH', '')}"
    process = subprocess.Popen(
        ["gz", "sim", "-s", "-r", "-v", "1", str(run / "world.sdf")],
        stdout=(run / "gz.log").open("w"), stderr=subprocess.STDOUT, env=env,
    )
    # Wait on the world, never on a clock: loading a fleet takes as long as it
    # takes, and a timeout here looks exactly like a crash.
    for _ in range(240):
        listing = subprocess.run(["gz", "topic", "-l"], capture_output=True, text=True, env=env)
        if "/stats" in listing.stdout:
            return process
        time.sleep(1)
    raise SystemExit("gazebo never published a stats topic; see gz.log")


def start_autopilots(fleet: dict, out: pathlib.Path) -> list[subprocess.Popen]:
    processes = []
    for instance in fleet["instances"]:
        directory = out / "sitl" / str(instance["id"])
        directory.mkdir(parents=True, exist_ok=True)
        processes.append(subprocess.Popen(
            [ARDUCOPTER, "--model", "JSON", "--speedup", "1", "--slave", "0",
             "--defaults", DEFAULTS, "--sim-address=127.0.0.1", f"-I{instance['id']}"],
            cwd=directory, stdout=(directory / "sitl.log").open("w"),
            stderr=subprocess.STDOUT,
        ))
    return processes


def run_scenario(
    members: dict, ground: GroundAgent, mesh: Mesh, log: EventLog,
    scenario: dict, *, offline: bool, tick: float = 1.0,
    clock=None, cut_ground_at: float | None = None,
) -> None:
    """Execute the timeline T-05 generated, event by event.

    `clock` returns the fleet's own time. That distinction is the whole of this
    function's correctness: the scenario's `at: 720` means seven hundred and
    twenty seconds *of simulated time*, and a simulation running at a real-time
    factor below one has had less of it than the wall clock suggests. Pacing
    the timeline against wall clock fires every event early — and at a factor
    of 0.07 it fired all of them before the aircraft had finished climbing, so
    a fleet that armed and flew correctly reported a coverage of zero.

    Offline there is no simulator, so the clock is the tick count and the two
    agree by construction.
    """
    duration = float(scenario["duration_seconds"])
    timeline = sorted(scenario["timeline"], key=lambda e: e["at"])
    pending = list(timeline)
    # An event the scenario asks for has to happen. Injecting a fault at an
    # instant when nothing is airborne and calling it done leaves a measure or
    # a rule silently unexercised, which reads exactly like one nobody wrote.
    deferred: list[tuple[str, str, float]] = []

    def defer(what: str, name: str, at: float) -> None:
        deferred.append((what, name, at))
        log.record(at, "note", element=None, scenario_event=name,
                   deferred="nothing was airborne at this moment; it will happen as "
                            "soon as something is, and the delay is recorded")

    def inject(what: str, fleet: dict, at: float) -> bool:
        airborne = [m for m in fleet.values() if m.state == m.states.watching]
        if not airborne:
            return False
        if what == "quarantine":
            airborne[-1].quarantine(at)
        elif what == "clearance":
            airborne[0].breach_clearance(at)
        else:
            airborne[0].mark_lost(at)
        return True
    started = time.time()
    t = 0.0

    while t <= duration:
        while pending and pending[0]["at"] <= t:
            event = pending.pop(0)
            name = str(event["event"])
            if name.endswith("taskMission"):
                ground.taskMission(t)
            elif name.endswith("recallAndLand"):
                ground.recallAndLand(t)
            elif "quarantine" in name.lower():
                defer("quarantine", name, t)
            elif "geofence" in name.lower() or "clearance" in name.lower():
                defer("clearance", name, t)
            elif "member lost" in name:
                # Always a tick later, never in the same one. A loss injected in
                # the very tick a member began watching collapsed into a single
                # coverage sample, so the measure read a drop from zero to zero:
                # the fleet's coverage before the loss has to be a moment the
                # log actually recorded.
                if False:
                    pass
                else:
                    # Nothing airborne at this instant. The scenario asked for a
                    # loss and a loss is what it must get, so this waits for the
                    # next moment something is watching rather than skipping:
                    # an unlucky instant once left the whole measure out of the
                    # report, indistinguishable from one nobody implemented.
                    defer("member lost", name, t)
            else:
                log.record(t, "note", detail_event=name, detail=event.get("detail", ""))

        if cut_ground_at is not None and mesh.ground_up and t >= cut_ground_at:
            mesh.cut_ground_link()
            log.record(t, "fault", element=None, fault="ground link lost",
                       why="the trade-off's instrument: from here the ground station "
                           "reaches nobody, and only an architecture that decides on "
                           "board can still rotate")

        # Anything the scenario asked for that could not happen yet, acted on
        # *before* this tick's steps so that the state it needs is one the log
        # already recorded. Injected after them, a loss landed in the very tick
        # its victim began watching: the two collapsed into one coverage sample
        # and the measure read a drop from zero to zero.
        if deferred:
            what, name, asked_at = deferred[0]
            if inject(what, members, t):
                deferred.pop(0)
                log.record(t, "note", element=None, scenario_event=name,
                           injected_late_by=round(t - asked_at, 1),
                           why="the scenario asked for this before anything was airborne")

        for member in members.values():
            member.step(t)
        ground.step(t)


        if offline or clock is None:
            t += tick
        else:
            # Follow the fleet, not the wall. A vehicle's own boot time is
            # simulated time, so this advances exactly as fast as the physics
            # the aircraft are actually flying in.
            time.sleep(tick / 4)
            now = clock()
            if now is None:
                continue
            t = now



def function_coverage(mapping: dict) -> dict:
    """Which functions the model names, and which of them this runtime flies.

    A report that lists only what ran invites the reader to assume the rest was
    realised. Five of v7's thirteen coordination and command functions are not
    implemented here, and the report has to say which five — a demonstration is
    only evidence about the parts it demonstrates.
    """
    import inspect
    from ground_agent import GroundAgent
    from member_agent import MemberAgent

    implemented = {
        name for cls in (MemberAgent, GroundAgent)
        for name, _ in inspect.getmembers(cls, predicate=inspect.isfunction)
        if not name.startswith("_")
    }
    named = [
        *(mapping.get("coordination_behaviours") or []),
        *(mapping.get("operator_events") or []),
    ]
    # Why each missing one is missing. A list of names invites the reader to
    # assume they were merely not got round to; most of these need a model this
    # forerunner deliberately does not have, and saying which is the difference
    # between a limitation and an omission.
    reasons = {
        "correlateTracks": "needs a detection model: there is nothing to track",
        "handOverTrack": "needs a detection model: there is nothing to track",
        "presentStatusPicture": "an operator interface, which this runtime has no operator for",
        "acknowledgeReport": "needs reports, which need a detection model",
        "commandSupervision": "supervision of a mission this scenario does not vary",
    }
    flown, missing = [], []
    for qualified in named:
        name = qualified.split("::")[-1]
        if name in implemented:
            flown.append(qualified)
        else:
            missing.append({
                "function": qualified,
                "why": reasons.get(name, "not implemented by this runtime"),
            })
    return {"flown": flown, "not_implemented": missing}


def report(
    run: pathlib.Path, fleet: dict, mapping: dict, scenario: dict, log: EventLog,
    *, offline: bool, coordination: str = "onboard",
) -> dict:
    """Claimed against simulated, and what was not exercised."""
    states = States.from_mapping(mapping)
    sectors = len(fleet["sectors"])
    duration = float(scenario["duration_seconds"])
    coverage = coverage_over_time(log.events, sectors=sectors,
                                  watching=states.watching, until=duration)
    impact = loss_on_member_loss(log.events, coverage)
    verdicts = check_rules(
        log.events, mapping.get("rules_to_monitor", []),
        recalled=states.recalled, watching=states.watching,
        landed=states.landed, outside=states.outside, ended_at=duration,
        # Every state the model declares, so a rule that names its own trigger
        # is matched against the model rather than against a word list here.
        states=tuple(row["state"] for row in mapping.get("states", [])),
    )

    measures = {m["measure"]: m for m in mapping.get("measures", [])}
    def target_of(name: str) -> tuple[float, str] | None:
        row = measures.get(name)
        if not row:
            return None
        text = str(row["target"])
        sense = "max" if ">=" in text else "min"
        return float(text.replace(">=", "").replace("<=", "").strip()), sense

    results: dict = {
        "offline": offline,
        "scenario_seconds": duration,
        "coordination": coordination,
        "members_flown": len(fleet["instances"]),
        "sectors": len(fleet["sectors"]),
        "fleet_that_flew": sum(
            1 for e in log.events
            if e.kind == "state" and e.detail.get("to") == States.from_mapping(mapping).watching
        ),
        "sectors": sectors,
        "members": len(fleet["instances"]),
        "duty_cycle": fleet["duty_cycle"],
        "measures": [],
        "rules": [
            {"rule": v.rule, "kind": v.kind, "held": v.held, "checked": v.checked,
             "vacuous": v.vacuous, "detail": v.detail, "breaches": list(v.breaches),
             "outcome": ("held" if v.held else ("not-checked" if v.checked == 0 else "broken"))}
            for v in verdicts
        ],
        # Which of the model's own functions this runtime actually realises.
        # Read from the agents rather than listed by hand, so a function that
        # is added to one and not the other cannot quietly pass as flown.
        "functions": function_coverage(mapping),
        "not_exercised": [
            "the simulated vehicle never runs out of power: charge is the agent's, "
            "because SITL takes battery state from the simulator and the plugin sends none",
            "a sector counts as watched when a member is over it; v7 states no sensor "
            "footprint, so this is T-05's reading of coverage and not the model's",
        ],
    }
    if offline:
        results["not_exercised"].insert(
            0, "no autopilot and no physics: the agents flew against cooperative fakes"
        )

    watch = target_of("areaUnderWatchShare")
    if watch:
        target, sense = watch
        results["measures"].append({
            "measure": "areaUnderWatchShare",
            "target": target, "sense": sense,
            "simulated": coverage.mean,
            "lowest": coverage.lowest,
            "meets_target": against_target(coverage.mean, target, sense),
        })
    ground_loss = coverage_after_ground_loss(log.events, coverage, until=duration)
    link = target_of("groundLinkLossAreaUnderWatchShare")
    if ground_loss and link:
        target, sense = link
        results["measures"].append({
            "measure": "groundLinkLossAreaUnderWatchShare",
            "target": target, "sense": sense,
            "simulated": ground_loss["mean_after"],
            "coordination": coordination,
            **ground_loss,
            "meets_target": against_target(ground_loss["mean_after"], target, sense),
        })

    loss = target_of("coverageLossOnMemberLoss")
    if loss and impact:
        target, sense = loss
        results["measures"].append({
            "measure": "coverageLossOnMemberLoss",
            "target": target, "sense": sense,
            "simulated": impact.loss,
            "before": impact.before, "lowest_after": impact.lowest_after,
            "recovery_seconds": impact.recovery_seconds,
            "charged_within_seconds": impact.window,
            "meets_target": against_target(impact.loss, target, sense),
        })
    results["unfilled_sectors"] = len(getattr(report, "_unfilled", []) or [])
    return results


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run", type=pathlib.Path, required=True,
                        help="the directory T-05 generated (holds fleet.yaml and world.sdf)")
    parser.add_argument("--out", type=pathlib.Path, default=None)
    parser.add_argument("--offline", action="store_true",
                        help="fly the scenario with no Gazebo and no autopilots")
    parser.add_argument("--tick", type=float, default=1.0)
    parser.add_argument(
        "--coordination", choices=("onboard", "ground"), default="onboard",
        help="where coordination is decided. `onboard` is alternative 2, where "
             "members settle handover among themselves; `ground` is alternative "
             "1, where the ground decides and a member waits to be told. The "
             "difference is invisible until the ground link is cut",
    )
    parser.add_argument(
        "--cut-ground-at", type=float, default=None, metavar="SECONDS",
        help="cut the ground link at this point of simulated time. This is the "
             "trade-off's instrument: the same scenario under both "
             "architectures, with the link taken away",
    )
    parser.add_argument(
        "--members", type=int, default=None,
        help="fly only the first N members. A reduced fleet is not the brief's "
             "fleet: the count is recorded in the results and every measure is "
             "labelled with it, because coverage over four sectors and coverage "
             "over twelve are different numbers",
    )
    parser.add_argument(
        "--arm-timeout", type=float, default=600.0,
        help="how long to wait for the fleet to arm. Arming needs simulated "
             "time, so a loaded host needs a longer wait, not a smaller fleet",
    )
    parser.add_argument(
        "--duration", type=float, default=None,
        help="override the scenario's own duration, for a smoke run. The "
             "override is recorded in the results, because a scenario cut "
             "short has not run the scenario",
    )
    args = parser.parse_args()

    run = args.run
    out = args.out or (run / f"run-{time.strftime('%Y%m%dT%H%M%S')}")
    out.mkdir(parents=True, exist_ok=True)
    fleet, mapping, scenario = load(run)
    if args.members is not None:
        kept = sorted(fleet["instances"], key=lambda i: int(i["id"]))[: args.members]
        sectors = fleet["sectors"][: args.members]
        fleet = {**fleet, "instances": kept, "sectors": sectors}
    log = EventLog(out / "events.jsonl")

    gazebo = None
    autopilots: list[subprocess.Popen] = []
    links: dict = {}
    partial: int | None = None
    try:
        if args.offline:
            speed = float(fleet.get("cruise_speed_mps", 15))
            links = {int(i["id"]): CooperativeAutopilot(int(i["id"]), speed, args.tick)
                     for i in fleet["instances"]}
        else:
            from models import materialise
            materialise(run / "fleet.yaml", run / "models")
            gazebo = start_gazebo(run, run / "models")
            autopilots = start_autopilots(fleet, out)
            from mavlink_link import arm_fleet, connect_all
            ports = [(int(i["id"]), int(i["mavlink_port"])) for i in fleet["instances"]]
            print(f"[run] attaching to {len(ports)} autopilot(s) — every one, before anything else",
                  flush=True)
            opened = connect_all(ports, timeout=180)
            links = {link.index: link for link in opened}
            print("[run] arming (asking repeatedly: a refusal before the EKF has a "
                  "position is the normal answer, not an error)", flush=True)
            armed_count = arm_fleet(opened, timeout=args.arm_timeout)
            print(f"[run] armed {armed_count} of {len(opened)}", flush=True)
            may_report, why = worth_reporting(armed_count, len(opened))
            if not may_report:
                # Refuse rather than report. A run where nothing armed once
                # carried on and produced a coverage of 0.0 and a rule verdict
                # of BROKEN — a fabricated finding about an architecture that
                # never flew. The measures of a fleet that did not take off are
                # not measures, and a monitor that saw no states did not check
                # a rule.
                # Print what the autopilots were saying. The first time this
                # fired, those lines read "EKF3 IMU0 origin set" and "using
                # GPS" — the autopilots were ready and the runtime had simply
                # asked them to arm once, too early, and never asked again.
                for link in opened[:3]:
                    for message in link.messages[-3:]:
                        print(f"    instance {link.index}: {message}", flush=True)
                log.record(0, "note", element=None, refused=why)
                print(f"[run] REFUSED: {why}", flush=True)
                return 3
            if armed_count < len(opened):
                print(f"[run] {why}", flush=True)
                partial = armed_count

        members, ground, mesh = build_fleet(
            fleet, mapping, log, links,
            decides_locally=(args.coordination == "onboard"),
        )
        log.record(0, "note", element=None, coordination=args.coordination,
                   why="where this run decides handover and rotation: `onboard` is the "
                       "architecture that settles it between members, `ground` the one "
                       "that waits to be told")
        if args.members is not None:
            log.record(0, "note", element=None, reduced_fleet=args.members,
                       why="a reduced fleet flown to validate the runtime against "
                           "real physics and real autopilots; its coverage is over "
                           "that many sectors and is not the brief's measure")
        if partial is not None:
            log.record(0, "note", element=None, partial_fleet=partial,
                       of=len(fleet["instances"]),
                       why="not every autopilot armed; every measure below is over "
                           "the fleet that flew, not the fleet the brief specifies")
        if args.duration is not None:
            log.record(0, "note", element=None,
                       duration_overridden_from=scenario["duration_seconds"],
                       to=args.duration,
                       why="a smoke run: the scenario was cut short and its "
                           "measures are not the scenario's measures")
            scenario = {**scenario, "duration_seconds": args.duration}
        print(f"[run] {len(members)} member(s), {len(fleet['sectors'])} sector(s), "
              f"{scenario['duration_seconds']} s of scenario"
              + (" (cut short: a smoke run)" if args.duration is not None else ""), flush=True)
        def fleet_clock():
            """The fleet's own clock: the median of what the autopilots report."""
            times = [l.boot_ms / 1000.0 for l in links.values()
                     if getattr(l, "boot_ms", 0)]
            if not times:
                return None
            times.sort()
            return times[len(times) // 2] - clock_zero[0]

        clock_zero = [0.0]
        if not args.offline and links:
            for link in links.values():
                link.pump()
            first = [l.boot_ms / 1000.0 for l in links.values() if getattr(l, "boot_ms", 0)]
            clock_zero[0] = min(first) if first else 0.0
            print(f"[run] the scenario clock follows the fleet, not the wall: "
                  f"starting at {clock_zero[0]:.0f} s of simulated time", flush=True)

        run_scenario(members, ground, mesh, log, scenario, offline=args.offline,
                     tick=args.tick, clock=None if args.offline else fleet_clock,
                     cut_ground_at=args.cut_ground_at)
        results = report(run, fleet, mapping, scenario, log, offline=args.offline,
                         coordination=args.coordination)
        results["unfilled_sectors"] = len(ground.unfilled)
        (out / "results.json").write_text(json.dumps(results, indent=2))

        # A run that leaves only a JSON file has not reported. Both of these
        # are generated from the log and can be rebuilt from it later, but
        # producing them now means a finished run is a finished run.
        try:
            from report import build as build_report
            (out / "README.md").write_text(build_report(out, run), encoding="utf-8")
            from overlay import build as build_replay
            build_replay(out, out / "replay.html", run)
        except Exception as error:  # a report that fails must not lose the run
            print(f"[run] the run finished; its report did not: {error}", flush=True)
        print(json.dumps(results["measures"], indent=2))
        for rule in results["rules"]:
            # Three outcomes, not two. A rule nobody could check is not a rule
            # that failed, and printing it as BROKEN is its own small lie.
            if rule["held"]:
                mark = "held (never exercised)" if rule["vacuous"] else "held"
            elif rule["checked"] == 0:
                mark = "NOT CHECKED"
            else:
                mark = "BROKEN"
            print(f"  {rule['rule']}: {mark} — {rule['detail']}")
        print(f"[run] {out}\n"
              f"      report: {out / 'README.md'}\n"
              f"      replay: {out / 'replay.html'}")
        return 0
    finally:
        log.close()
        # The runtime is root inside a container writing into the user's tree.
        # Without this, every SITL log, EEPROM and dataflash file it leaves
        # behind needs sudo to remove — and a run leaves hundreds.
        try:
            import os
            owner = out.parent.stat()
            for path in [out, *out.rglob("*")]:
                os.chown(path, owner.st_uid, owner.st_gid)
        except (OSError, PermissionError):
            pass
        for process in autopilots:
            process.terminate()
        if gazebo is not None:
            gazebo.terminate()


if __name__ == "__main__":
    sys.exit(main())
