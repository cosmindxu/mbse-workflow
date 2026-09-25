#!/usr/bin/env python3
"""Get N autopilots into the air together, and say how many made it.

WP0.3 measures what a fleet costs, and that measurement is only worth having
over a window where the whole fleet is actually flying. So this arms every
instance, commands a takeoff, waits for all of them to reach altitude, and then
holds — printing a line the driver script can use to open the measurement
window.

It reports rather than asserts, and it never pretends: a vehicle that will not
arm or will not climb is named, and the hold happens with whatever is airborne
so the measurement can still be taken and described honestly as k of N.

    python3 fleet_fly.py --count 12 --altitude 20 --hold 60
"""
from __future__ import annotations

import argparse
import sys
import time

from pymavlink import mavutil

# SITL instance n puts its MAVLink port here; `-I n` moves it by ten.
MAVLINK_PORT_BASE = 5760
MAVLINK_PORT_STRIDE = 10


def log(message: str) -> None:
    print(f"[fleet] {message}", flush=True)


class Vehicle:
    """One autopilot, and what it has managed so far."""

    def __init__(self, index: int) -> None:
        self.index = index
        self.port = MAVLINK_PORT_BASE + MAVLINK_PORT_STRIDE * index
        self.link: mavutil.mavfile | None = None
        self.armed = False
        self.airborne = False
        self.altitude = 0.0
        self.note = ""

    def connect(self, timeout: float) -> bool:
        try:
            link = mavutil.mavlink_connection(f"tcp:127.0.0.1:{self.port}")
        except Exception as error:  # a refused connection is a normal outcome here
            self.note = f"connect failed: {error}"
            return False
        if link.wait_heartbeat(timeout=timeout) is None or link.target_system == 0:
            self.note = "no heartbeat"
            return False
        self.link = link
        # Only the one message this needs, at 5 Hz. Asking for every stream
        # and then reading one message at a time turns a climb into a queue.
        link.mav.command_long_send(
            link.target_system, link.target_component,
            mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL, 0,
            mavutil.mavlink.MAVLINK_MSG_ID_GLOBAL_POSITION_INT, 200000, 0, 0, 0, 0, 0,
        )
        return True

    def pump(self) -> None:
        """Read everything waiting, once, and dispatch it by type.

        Two type-filtered reads in the same loop do not coexist: pymavlink
        *discards* what does not match, so a call asking for positions throws
        away the arm acknowledgements and a call asking for acks throws away
        the positions. Read once, sort afterwards.
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
            elif kind == "HEARTBEAT":
                # The heartbeat carries the armed bit. That is the autopilot's
                # own account of its state, and unlike an acknowledgement it
                # cannot be missed by reading a moment too late.
                self.armed = bool(
                    message.base_mode & mavutil.mavlink.MAV_MODE_FLAG_SAFETY_ARMED
                )
            elif kind == "STATUSTEXT" and self.note == "":
                text = getattr(message, "text", "")
                if "PreArm" in text or "Arm" in text:
                    self.note = text.strip()

    def try_arm(self) -> None:
        if self.link is None or self.armed:
            return
        link = self.link
        link.mav.command_long_send(
            link.target_system, link.target_component,
            mavutil.mavlink.MAV_CMD_DO_SET_MODE, 0,
            mavutil.mavlink.MAV_MODE_FLAG_CUSTOM_MODE_ENABLED, 4, 0, 0, 0, 0, 0,  # GUIDED
        )
        link.arducopter_arm()

    def takeoff(self, altitude: float) -> None:
        if self.link is None:
            return
        self.link.mav.command_long_send(
            self.link.target_system, self.link.target_component,
            mavutil.mavlink.MAV_CMD_NAV_TAKEOFF, 0, 0, 0, 0, 0, 0, 0, altitude,
        )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--count", type=int, required=True)
    parser.add_argument("--altitude", type=float, default=20.0)
    parser.add_argument("--hold", type=float, default=60.0)
    parser.add_argument("--arm-timeout", type=float, default=300.0)
    args = parser.parse_args()

    fleet = [Vehicle(n) for n in range(args.count)]

    connected = [v for v in fleet if v.connect(timeout=90)]
    log(f"connected {len(connected)} of {args.count}")
    for vehicle in fleet:
        if vehicle not in connected:
            log(f"  vehicle {vehicle.index} on {vehicle.port}: {vehicle.note}")
    if not connected:
        log("nothing to fly")
        return 1

    # Arming is a wait on each autopilot's EKF, and those waits overlap: ask
    # them all, repeatedly, rather than walking the fleet one at a time.
    started = time.time()
    while time.time() - started < args.arm_timeout:
        for vehicle in connected:
            vehicle.pump()
            vehicle.try_arm()
        if all(v.armed for v in connected):
            break
        time.sleep(1)
    armed = [v for v in connected if v.armed]
    log(f"armed {len(armed)} of {args.count} after {time.time() - started:.0f} s")
    for vehicle in connected:
        if not vehicle.armed and vehicle.note:
            log(f"  vehicle {vehicle.index} would not arm: {vehicle.note}")

    for vehicle in armed:
        vehicle.takeoff(args.altitude)
    log(f"takeoff commanded to {args.altitude:.0f} m")

    climb_started = time.time()
    while time.time() - climb_started < args.arm_timeout:
        for vehicle in armed:
            vehicle.pump()
            if vehicle.altitude >= args.altitude - 2.0:
                vehicle.airborne = True
        if all(v.airborne for v in armed):
            break
        time.sleep(0.5)
    airborne = [v for v in armed if v.airborne]
    log(f"airborne {len(airborne)} of {args.count} after {time.time() - climb_started:.0f} s")

    # The line the driver waits for before it opens the measurement window.
    print(f"FLEET_READY airborne={len(airborne)} of={args.count}", flush=True)

    hold_started = time.time()
    while time.time() - hold_started < args.hold:
        for vehicle in airborne:
            vehicle.pump()
        time.sleep(0.5)
    altitudes = [v.altitude for v in airborne]
    if altitudes:
        log(
            f"held {args.hold:.0f} s; altitude "
            f"{min(altitudes):.1f}–{max(altitudes):.1f} m"
        )
    print(
        f"RESULT connected={len(connected)} armed={len(armed)} "
        f"airborne={len(airborne)} of={args.count}"
    )
    return 0 if len(airborne) == args.count else 4


if __name__ == "__main__":
    sys.exit(main())
