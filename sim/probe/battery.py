#!/usr/bin/env python3
"""Does the simulated battery drain, and does the failsafe fire where it should?

D4 compresses a 40-minute endurance by a declared factor, so a member's flight
lasts four minutes of simulated time at factor 10. That is only an honest model
if the autopilot's own battery runs out at the scaled endurance and trips its
own failsafe — otherwise the recharge rotation has to be modelled in the
coordination node, and the autopilot is then flying a duty cycle it does not
know about.

Two modes, because the second needs a number from the first:

  --measure 90        hover and report the draw: amps, mAh per second, and the
                      capacity a given endurance would need
  --watch             hover until the battery failsafe fires, and report when
                      it fired and what the autopilot did about it

    python3 battery.py --measure 90 --endurance 240
    python3 battery.py --watch --endurance 240
"""
from __future__ import annotations

import argparse
import sys
import time

from pymavlink import mavutil

ENDPOINT = "tcp:127.0.0.1:5760"
GUIDED = 4
# The modes a battery failsafe puts a copter into, by ArduCopter's numbering.
FAILSAFE_MODES = {6: "RTL", 9: "LAND", 2: "ALT_HOLD", 5: "LOITER"}


def log(message: str) -> None:
    print(f"[battery] {message}", flush=True)


class Flight:
    """One vehicle, its battery, and what it said about both."""

    def __init__(self, link) -> None:
        self.link = link
        self.altitude = 0.0
        self.armed = False
        self.mode = GUIDED
        self.boot_ms = 0
        self.voltage = 0.0
        self.current_a = 0.0
        self.consumed_mah = 0.0
        self.remaining_pct = -1
        self.messages: list[str] = []

    def pump(self) -> None:
        """One read pass, dispatched by type — never two filtered reads."""
        while True:
            message = self.link.recv_match(blocking=False)
            if message is None:
                return
            kind = message.get_type()
            if kind == "GLOBAL_POSITION_INT":
                self.altitude = message.relative_alt / 1000.0
                self.boot_ms = message.time_boot_ms
            elif kind == "HEARTBEAT":
                self.armed = bool(
                    message.base_mode & mavutil.mavlink.MAV_MODE_FLAG_SAFETY_ARMED
                )
                self.mode = message.custom_mode
            elif kind == "BATTERY_STATUS":
                if message.voltages and message.voltages[0] != 65535:
                    self.voltage = message.voltages[0] / 1000.0
                # current_battery is in centiamps; -1 means "not measured".
                if message.current_battery != -1:
                    self.current_a = message.current_battery / 100.0
                if message.current_consumed != -1:
                    self.consumed_mah = float(message.current_consumed)
                self.remaining_pct = message.battery_remaining
            elif kind == "STATUSTEXT":
                text = getattr(message, "text", "").strip()
                if text and text not in self.messages:
                    self.messages.append(text)

    def ask_for(self, message_id: int, interval_us: int) -> None:
        self.link.mav.command_long_send(
            self.link.target_system, self.link.target_component,
            mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL, 0,
            message_id, interval_us, 0, 0, 0, 0, 0,
        )

    def set_param(self, name: str, value: float) -> None:
        self.link.mav.param_set_send(
            self.link.target_system, self.link.target_component,
            name.encode(), float(value), mavutil.mavlink.MAV_PARAM_TYPE_REAL32,
        )

    def read_param(self, name: str, timeout: float = 5.0) -> float | None:
        self.link.mav.param_request_read_send(
            self.link.target_system, self.link.target_component, name.encode(), -1
        )
        deadline = time.time() + timeout
        while time.time() < deadline:
            message = self.link.recv_match(type="PARAM_VALUE", blocking=True, timeout=1)
            if message and message.param_id.strip("\x00") == name:
                return message.param_value
        return None

    def arm_and_climb(self, altitude: float, timeout: float = 300.0) -> bool:
        started = time.time()
        while time.time() - started < timeout and not self.armed:
            self.link.mav.command_long_send(
                self.link.target_system, self.link.target_component,
                mavutil.mavlink.MAV_CMD_DO_SET_MODE, 0,
                mavutil.mavlink.MAV_MODE_FLAG_CUSTOM_MODE_ENABLED, GUIDED, 0, 0, 0, 0, 0,
            )
            self.link.arducopter_arm()
            self.pump()
            time.sleep(1)
        if not self.armed:
            log("never armed")
            return False
        log(f"armed after {time.time() - started:.0f} s")
        self.link.mav.command_long_send(
            self.link.target_system, self.link.target_component,
            mavutil.mavlink.MAV_CMD_NAV_TAKEOFF, 0, 0, 0, 0, 0, 0, 0, altitude,
        )
        climb_started = time.time()
        while time.time() - climb_started < timeout:
            self.pump()
            if self.altitude >= altitude - 2.0:
                log(f"hovering at {self.altitude:.1f} m")
                return True
            time.sleep(0.5)
        log(f"never reached {altitude:.0f} m (got {self.altitude:.1f} m)")
        return False


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--measure", type=float, metavar="SECONDS")
    parser.add_argument("--watch", action="store_true")
    parser.add_argument("--altitude", type=float, default=20.0)
    parser.add_argument(
        "--endurance", type=float, default=240.0,
        help="the scaled flight endurance in seconds — 40 min at a time scale of 10",
    )
    parser.add_argument("--watch-limit", type=float, default=900.0)
    args = parser.parse_args()
    if not args.measure and not args.watch:
        raise SystemExit("choose --measure SECONDS or --watch")

    link = mavutil.mavlink_connection(ENDPOINT)
    if link.wait_heartbeat(timeout=90) is None or link.target_system == 0:
        log("no heartbeat; SITL is not there")
        return 1
    flight = Flight(link)
    flight.ask_for(mavutil.mavlink.MAVLINK_MSG_ID_GLOBAL_POSITION_INT, 200000)
    flight.ask_for(mavutil.mavlink.MAVLINK_MSG_ID_BATTERY_STATUS, 500000)

    for name in ("BATT_MONITOR", "SIM_BATT_CAP_AH", "SIM_BATT_VOLTAGE",
                 "BATT_CAPACITY", "BATT_LOW_MAH", "BATT_FS_LOW_ACT"):
        value = flight.read_param(name)
        log(f"  {name} = {'(absent)' if value is None else value}")

    if not flight.arm_and_climb(args.altitude):
        return 2

    if args.measure:
        # A hover is the duty cycle's steady state, so the draw measured here is
        # what an endurance should be sized against.
        flight.pump()
        start_boot = flight.boot_ms
        start_mah = flight.consumed_mah
        samples: list[float] = []
        started = time.time()
        while time.time() - started < args.measure:
            flight.pump()
            if flight.current_a:
                samples.append(flight.current_a)
            time.sleep(0.5)
        flight.pump()
        onboard = (flight.boot_ms - start_boot) / 1000.0
        drawn = flight.consumed_mah - start_mah
        if onboard <= 0:
            log("the autopilot clock did not advance; nothing to report")
            return 3
        mean_a = sum(samples) / len(samples) if samples else 0.0
        rate = drawn / onboard
        log(f"hover draw {mean_a:.1f} A, {flight.voltage:.1f} V")
        log(f"consumed {drawn:.0f} mAh in {onboard:.0f} s onboard = {rate:.2f} mAh/s")
        if rate > 0:
            needed_mah = rate * args.endurance
            log(
                f"a {args.endurance:.0f} s endurance needs about "
                f"{needed_mah:.0f} mAh ({needed_mah / 1000:.2f} Ah)"
            )
            print(
                f"RESULT hover_amps={mean_a:.2f} mah_per_second={rate:.3f} "
                f"capacity_for_endurance_mah={needed_mah:.0f} "
                f"remaining_pct={flight.remaining_pct}"
            )
        else:
            log("the battery did not drain at all over the window")
            print("RESULT hover_amps=%.2f mah_per_second=0 drained=no" % mean_a)
        return 0

    # --watch: hold the hover and wait for the autopilot's own failsafe.
    flight.pump()
    start_boot = flight.boot_ms
    started = time.time()
    fired_at: float | None = None
    while time.time() - started < args.watch_limit:
        flight.pump()
        if flight.mode != GUIDED:
            fired_at = (flight.boot_ms - start_boot) / 1000.0
            break
        time.sleep(0.5)
    onboard = (flight.boot_ms - start_boot) / 1000.0

    battery_messages = [m for m in flight.messages if "atter" in m or "ailsafe" in m]
    if fired_at is None:
        log(
            f"no failsafe in {onboard:.0f} s onboard; battery at "
            f"{flight.remaining_pct}%, {flight.consumed_mah:.0f} mAh consumed"
        )
        for message in battery_messages:
            log(f"  said: {message}")
        print(
            f"RESULT failsafe=none onboard_seconds={onboard:.0f} "
            f"consumed_mah={flight.consumed_mah:.0f} remaining_pct={flight.remaining_pct}"
        )
        return 4

    action = FAILSAFE_MODES.get(flight.mode, f"mode {flight.mode}")
    log(
        f"failsafe at {fired_at:.0f} s onboard — the autopilot switched to "
        f"{action} with {flight.consumed_mah:.0f} mAh consumed, "
        f"{flight.remaining_pct}% left"
    )
    for message in battery_messages:
        log(f"  said: {message}")
    against = fired_at / args.endurance if args.endurance else 0
    log(f"that is {against:.2f} of the {args.endurance:.0f} s scaled endurance")
    print(
        f"RESULT failsafe={action} at_onboard_seconds={fired_at:.0f} "
        f"consumed_mah={flight.consumed_mah:.0f} remaining_pct={flight.remaining_pct} "
        f"fraction_of_endurance={against:.2f}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
