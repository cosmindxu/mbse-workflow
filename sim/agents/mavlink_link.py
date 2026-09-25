#!/usr/bin/env python3
"""One autopilot, spoken to correctly.

Three things here were learned the hard way in WP0.2 and WP0.3, and they are
invariants of this class rather than advice in a comment:

  * **One read pass, dispatched by type.** Two type-filtered `recv_match` calls
    in the same loop discard each other's messages, so a loop asking for
    positions eats the arm acknowledgements and reports a vehicle as refusing
    to arm while it arms on schedule.
  * **Armed state comes from the heartbeat's armed bit**, not from an
    acknowledgement that can be missed by reading a moment too late.
  * **Never a fixed wait.** Arming a fleet took 25 s for one vehicle, 52 s for
    four and 148 s for twelve; a script with a constant in it is a script that
    works until the fleet grows.

And one that is not about MAVLink at all: an autopilot blocks until a client
attaches to its port, so a runtime must connect every link before it does
anything else, or the unconnected ones stall the world for everybody.
"""
from __future__ import annotations

import time
from typing import Callable

from pymavlink import mavutil

GUIDED = 4
RTL = 6
LAND = 9
MODE_NAMES = {0: "STABILIZE", 2: "ALT_HOLD", 3: "AUTO", GUIDED: "GUIDED",
              5: "LOITER", RTL: "RTL", LAND: "LAND"}


class LinkRefused(Exception):
    """The autopilot was not there, or never said anything."""


class MavlinkLink:
    """A connection to one SITL instance, and the last thing it said."""

    def __init__(self, index: int, port: int) -> None:
        self.index = index
        self.port = port
        self.master = None
        self.armed = False
        self.mode = -1
        self.altitude = 0.0
        self.latitude = 0.0
        self.longitude = 0.0
        self.boot_ms = 0
        self.messages: list[str] = []
        self._home: tuple[float, float] | None = None

    # -- opening ------------------------------------------------------------

    def connect(self, timeout: float = 120.0) -> None:
        self.master = mavutil.mavlink_connection(f"tcp:127.0.0.1:{self.port}")
        if self.master.wait_heartbeat(timeout=timeout) is None or self.master.target_system == 0:
            raise LinkRefused(f"no heartbeat from instance {self.index} on {self.port}")
        # Only the messages this reads, at 5 Hz. Asking for every stream puts a
        # hundred a second on the socket and turns reading into keeping up.
        self._ask_for(mavutil.mavlink.MAVLINK_MSG_ID_GLOBAL_POSITION_INT, 200_000)

    def _ask_for(self, message_id: int, interval_us: int) -> None:
        self.master.mav.command_long_send(
            self.master.target_system, self.master.target_component,
            mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL, 0,
            message_id, interval_us, 0, 0, 0, 0, 0,
        )

    # -- reading ------------------------------------------------------------

    def pump(self) -> None:
        """Read everything waiting, once, and sort it by type."""
        if self.master is None:
            return
        while True:
            message = self.master.recv_match(blocking=False)
            if message is None:
                return
            kind = message.get_type()
            if kind == "GLOBAL_POSITION_INT":
                self.altitude = message.relative_alt / 1000.0
                self.latitude = message.lat / 1e7
                self.longitude = message.lon / 1e7
                self.boot_ms = message.time_boot_ms
                if self._home is None:
                    self._home = (self.latitude, self.longitude)
            elif kind == "HEARTBEAT":
                self.armed = bool(
                    message.base_mode & mavutil.mavlink.MAV_MODE_FLAG_SAFETY_ARMED
                )
                self.mode = message.custom_mode
            elif kind == "STATUSTEXT":
                text = getattr(message, "text", "").strip()
                if text and text not in self.messages:
                    self.messages.append(text)

    @property
    def mode_name(self) -> str:
        return MODE_NAMES.get(self.mode, f"mode {self.mode}")

    # -- commanding ---------------------------------------------------------

    def set_mode(self, mode: int) -> None:
        self.master.mav.command_long_send(
            self.master.target_system, self.master.target_component,
            mavutil.mavlink.MAV_CMD_DO_SET_MODE, 0,
            mavutil.mavlink.MAV_MODE_FLAG_CUSTOM_MODE_ENABLED, mode, 0, 0, 0, 0, 0,
        )

    def try_arm(self) -> None:
        """Ask once. Whether it worked is read from the next heartbeat."""
        self.set_mode(GUIDED)
        self.master.arducopter_arm()

    def takeoff(self, altitude: float) -> None:
        self.master.mav.command_long_send(
            self.master.target_system, self.master.target_component,
            mavutil.mavlink.MAV_CMD_NAV_TAKEOFF, 0, 0, 0, 0, 0, 0, 0, altitude,
        )

    def goto(self, north_m: float, east_m: float, altitude: float) -> None:
        """Fly to a point given in metres from home, at `altitude` above it.

        The sectors are laid out in the world's own metres, so this speaks the
        same units rather than making every agent convert to degrees.
        """
        if self._home is None:
            return
        # Close enough over a few kilometres, and exact at the equator's scale
        # of the home latitude — the world is flat ground in any case.
        lat = self._home[0] + north_m / 111_320.0
        import math
        lon = self._home[1] + east_m / (111_320.0 * max(0.1, math.cos(math.radians(self._home[0]))))
        self.master.mav.set_position_target_global_int_send(
            0, self.master.target_system, self.master.target_component,
            mavutil.mavlink.MAV_FRAME_GLOBAL_RELATIVE_ALT_INT,
            0b0000111111111000,  # positions only
            int(lat * 1e7), int(lon * 1e7), altitude,
            0, 0, 0, 0, 0, 0, 0, 0,
        )

    def return_to_launch(self) -> None:
        self.set_mode(RTL)

    def land(self) -> None:
        self.set_mode(LAND)


def connect_all(
    ports: list[tuple[int, int]], *, timeout: float = 120.0,
    on_connected: Callable[[MavlinkLink], None] | None = None,
) -> list[MavlinkLink]:
    """Attach to every autopilot before anything else happens.

    Not a convenience: an autopilot that nobody has connected to sits blocked,
    and its Gazebo plugin then stalls the shared world. Connecting eleven of
    twelve is not eleven twelfths of a fleet, it is a stopped simulation.
    """
    links: list[MavlinkLink] = []
    for index, port in ports:
        link = MavlinkLink(index, port)
        link.connect(timeout=timeout)
        links.append(link)
        if on_connected is not None:
            on_connected(link)
    return links


def arm_fleet(
    links: list[MavlinkLink], *, timeout: float, poll: float = 1.0
) -> int:
    """Keep asking, until every autopilot is armed or the time runs out.

    Asking once does not arm anything. An autopilot refuses until its EKF has a
    position, which takes tens of seconds of *simulated* time, and the refusal
    is not an error — it is the normal answer to an early question. A runtime
    that asks once and then waits will wait for ever, and the symptom is a
    fleet that never arms with an EKF that is perfectly happy: "EKF3 IMU0
    origin set", "using GPS", and nothing in the air.
    """
    deadline = time.time() + timeout
    while time.time() < deadline:
        for link in links:
            link.pump()
            if not link.armed:
                link.try_arm()
        if all(link.armed for link in links):
            break
        time.sleep(poll)
    return sum(1 for link in links if link.armed)


def wait_until(
    condition: Callable[[], bool], links: list[MavlinkLink], *,
    timeout: float, poll: float = 0.5,
) -> bool:
    """Pump every link until a condition holds. Never a bare sleep."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        for link in links:
            link.pump()
        if condition():
            return True
        time.sleep(poll)
    return False
