#!/usr/bin/env python3
"""The same fleet, flown as a swarm: up together, out to sectors, back.

`fleet_fly.py` answers "can this host fly N autopilots at once", and holds them
in a block because a measurement wants the fleet still. This one is for the
camera. It flies the shape the model describes — every member climbs to its own
deconfliction layer, spreads to the sector it was assigned, watches, and
regroups — so that a clip of the flight and a diagram of the scenario show the
same thing happening.

Nothing here is a second simulation of the model: it is the probe world with a
flight path, and the numbers that decide anything still come from
`sim/runtime/run.py`. What this produces is footage.

    python3 swarm_fly.py --count 12 --altitude 20 --spread 1.6 --hold 45
"""
from __future__ import annotations

import argparse
import math
import sys
import time

from pymavlink import mavutil

from fleet_fly import Vehicle, log
from fleet_world import grid

# Position-only: every bit set but the three position bits, which is how a
# SET_POSITION_TARGET says "go here" without also commanding velocity.
POSITION_ONLY = 0b0000111111111000


class Member(Vehicle):
    """A vehicle that also knows where it is, not only how high."""

    def __init__(self, index: int) -> None:
        super().__init__(index)
        self.north = 0.0
        self.east = 0.0
        self.target: tuple[float, float] | None = None

    def connect(self, timeout: float) -> bool:
        if not super().connect(timeout):
            return False
        link = self.link
        assert link is not None
        link.mav.command_long_send(
            link.target_system, link.target_component,
            mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL, 0,
            mavutil.mavlink.MAVLINK_MSG_ID_LOCAL_POSITION_NED, 200000, 0, 0, 0, 0, 0,
        )
        return True

    def pump(self) -> None:
        """One drain of the queue, dispatched by type — see `Vehicle.pump`.

        Written out rather than delegated: the parent drains the same queue and
        discards what it does not recognise, so a local position read after it
        would always find nothing.
        """
        if self.link is None:
            return
        while True:
            message = self.link.recv_match(blocking=False)
            if message is None:
                break
            kind = message.get_type()
            if kind == "GLOBAL_POSITION_INT":
                self.altitude = message.relative_alt / 1000.0
            elif kind == "LOCAL_POSITION_NED":
                self.north, self.east = message.x, message.y
            elif kind == "HEARTBEAT":
                self.armed = bool(
                    message.base_mode & mavutil.mavlink.MAV_MODE_FLAG_SAFETY_ARMED
                )
            elif kind == "STATUSTEXT" and self.note == "":
                text = getattr(message, "text", "")
                if "PreArm" in text or "Arm" in text:
                    self.note = text.strip()

    def go(self, north: float, east: float, altitude: float) -> None:
        """Fly to a point in this vehicle's own local frame, holding altitude."""
        if self.link is None:
            return
        self.target = (north, east)
        self.link.mav.set_position_target_local_ned_send(
            0, self.link.target_system, self.link.target_component,
            mavutil.mavlink.MAV_FRAME_LOCAL_NED, POSITION_ONLY,
            north, east, -altitude, 0, 0, 0, 0, 0, 0, 0, 0,
        )

    def arrived(self, tolerance: float = 3.0) -> bool:
        if self.target is None:
            return True
        return math.hypot(self.north - self.target[0], self.east - self.target[1]) <= tolerance


def phase(members: list[Member], seconds: float, until_arrived: bool = False) -> int:
    """Run the link for a while; stop early once everyone is where it was sent."""
    started = time.time()
    while time.time() - started < seconds:
        for member in members:
            member.pump()
        if until_arrived and members and all(m.arrived() for m in members):
            break
        time.sleep(0.25)
    return sum(1 for m in members if m.arrived())


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--count", type=int, required=True)
    parser.add_argument("--altitude", type=float, default=20.0)
    parser.add_argument(
        "--layers", type=float, default=4.0, metavar="METRES",
        help="vertical separation between deconfliction layers; members are "
             "dealt round-robin into three of them",
    )
    parser.add_argument(
        "--spread", type=float, default=1.6,
        help="how far out the sectors sit, as a multiple of the launch grid",
    )
    parser.add_argument("--climb-timeout", type=float, default=180.0)
    parser.add_argument("--transit", type=float, default=60.0,
                        help="seconds allowed to reach a sector before giving up on it")
    parser.add_argument("--hold", type=float, default=45.0, help="seconds on station")
    parser.add_argument("--regroup", type=float, default=0.0,
                        help="seconds spent flying back to the launch grid; 0 skips it")
    parser.add_argument("--arm-timeout", type=float, default=300.0)
    args = parser.parse_args()

    fleet = [Member(n) for n in range(args.count)]
    launch = grid(args.count)

    connected = [v for v in fleet if v.connect(timeout=90)]
    log(f"connected {len(connected)} of {args.count}")
    for vehicle in fleet:
        if vehicle not in connected:
            log(f"  vehicle {vehicle.index} on {vehicle.port}: {vehicle.note}")
    if not connected:
        log("nothing to fly")
        return 1

    started = time.time()
    while time.time() - started < args.arm_timeout:
        for vehicle in connected:
            vehicle.pump()
            vehicle.try_arm()
        if all(v.armed for v in connected):
            break
        time.sleep(1)
    armed = [v for v in connected if v.armed]
    # The driver script waits for this line before it starts the recorder.
    log(f"armed {len(armed)} of {args.count} after {time.time() - started:.0f} s")
    for vehicle in connected:
        if not vehicle.armed and vehicle.note:
            log(f"  vehicle {vehicle.index} would not arm: {vehicle.note}")
    if not armed:
        return 1

    # Each member owns a layer, so that spreading and regrouping cross no other
    # member's altitude. This is `deconflictMembers` as a flight path rather
    # than as a rule: the clip shows the separation the model asks for.
    layer = {v.index: args.altitude + (v.index % 3) * args.layers for v in armed}
    for vehicle in armed:
        vehicle.takeoff(layer[vehicle.index])
    log(f"takeoff commanded, {args.altitude:.0f}–{args.altitude + 2 * args.layers:.0f} m "
        f"in {3} layers")

    climb = time.time()
    while time.time() - climb < args.climb_timeout:
        for vehicle in armed:
            vehicle.pump()
            if vehicle.altitude >= layer[vehicle.index] - 2.0:
                vehicle.airborne = True
        if all(v.airborne for v in armed):
            break
        time.sleep(0.5)
    airborne = [v for v in armed if v.airborne]
    log(f"airborne {len(airborne)} of {args.count} after {time.time() - climb:.0f} s")
    print(f"FLEET_READY airborne={len(airborne)} of={args.count}", flush=True)

    # Out to the sectors. Gazebo's world is ENU and the autopilot's frame is
    # NED, so the world's y is north and its x is east.
    out = args.spread - 1.0
    for vehicle in airborne:
        x, y = launch[vehicle.index]
        vehicle.go(y * out, x * out, layer[vehicle.index])
    log(f"sectors commanded, {args.spread:g}x the launch grid")
    there = phase(airborne, args.transit, until_arrived=True)
    log(f"on station {there} of {len(airborne)}")

    log(f"watching for {args.hold:.0f} s")
    phase(airborne, args.hold)

    if args.regroup:
        for vehicle in airborne:
            vehicle.go(0.0, 0.0, layer[vehicle.index])
        log("regroup commanded")
        back = phase(airborne, args.regroup, until_arrived=True)
        log(f"regrouped {back} of {len(airborne)}")

    for vehicle in airborne:
        vehicle.pump()
    altitudes = [v.altitude for v in airborne]
    if altitudes:
        log(f"altitude {min(altitudes):.1f}–{max(altitudes):.1f} m")
    print(
        f"RESULT connected={len(connected)} armed={len(armed)} "
        f"airborne={len(airborne)} onstation={there} of={args.count}",
        flush=True,
    )
    return 0 if len(airborne) == args.count else 1


if __name__ == "__main__":
    sys.exit(main())
