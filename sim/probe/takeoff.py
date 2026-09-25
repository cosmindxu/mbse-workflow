#!/usr/bin/env python3
"""One vehicle, off the ground and back — the smallest thing that proves the
Gazebo/SITL pair is really one vehicle and not two programs in a room.

It reports what it saw rather than asserting: the caller decides whether a
climb to within a metre of the commanded altitude counts, and the numbers are
what WP0.3 sizes the fleet from.
"""
import sys
import time

from pymavlink import mavutil

TARGET_ALT = float(sys.argv[1]) if len(sys.argv) > 1 else 10.0
# SITL's own MAVLink port. Only MAVProxy forwards to udp:14550, and the probe
# runs without it — aiming at 14550 finds nothing and, because pymavlink
# *returns* None on a heartbeat timeout instead of raising, the failure is
# silent unless it is checked.
ENDPOINT = sys.argv[2] if len(sys.argv) > 2 else "tcp:127.0.0.1:5760"
DEADLINE = 120.0


def log(message: str) -> None:
    print(f"[takeoff] {message}", flush=True)


def wait(master, predicate, what: str, timeout: float = 60.0):
    """Pump messages until a predicate holds, and say what was last seen."""
    started = time.time()
    last = None
    while time.time() - started < timeout:
        message = master.recv_match(blocking=True, timeout=1.0)
        if message is None:
            continue
        last = message
        if predicate(message):
            return message
    raise TimeoutError(f"{what}: nothing in {timeout:.0f} s (last: {last})")


def latest_position(master):
    """The most recent position report, not the next one in the queue.

    Reading one message per half-second out of a stream arriving far faster
    than that does not sample the flight — it walks a growing backlog, and
    every altitude read is older than the one before. A climb measured that way
    is the reader's lag, and it is reproducible to a tenth of a second across
    runs, which is what makes it look like a real measurement.
    """
    newest = None
    while True:
        message = master.recv_match(type="GLOBAL_POSITION_INT", blocking=False)
        if message is None:
            break
        newest = message
    if newest is None:
        newest = wait(
            master,
            lambda m: m.get_type() == "GLOBAL_POSITION_INT",
            "a position report",
        )
    return newest


def altitude(master) -> float:
    return latest_position(master).relative_alt / 1000.0


def main() -> int:
    log(f"connecting to {ENDPOINT}")
    master = mavutil.mavlink_connection(ENDPOINT)
    if master.wait_heartbeat(timeout=60) is None or master.target_system == 0:
        log(f"no heartbeat on {ENDPOINT} — SITL is not there")
        return 1
    log(f"heartbeat from system {master.target_system}")

    # Nothing streams telemetry on this port until it is asked. MAVProxy does
    # this on the way past; without it the autopilot arms, flies and says
    # nothing but heartbeats, and the climb looks like a hang.
    # One message type at 5 Hz, not MAV_DATA_STREAM_ALL: asking for every
    # stream puts a hundred messages a second on the socket, and reading is
    # then a matter of keeping up rather than of listening.
    master.mav.command_long_send(
        master.target_system, master.target_component,
        mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL, 0,
        mavutil.mavlink.MAVLINK_MSG_ID_GLOBAL_POSITION_INT, 200000, 0, 0, 0, 0, 0,
    )
    first = wait(master, lambda m: m.get_type() == "GLOBAL_POSITION_INT",
                 "a position report after asking for one", timeout=30)
    log(f"telemetry flowing; on the ground at {first.relative_alt / 1000.0:.2f} m")

    # EKF and GPS need a moment before the autopilot will accept an arm.
    started = time.time()
    while time.time() - started < DEADLINE:
        master.mav.command_long_send(
            master.target_system, master.target_component,
            mavutil.mavlink.MAV_CMD_DO_SET_MODE, 0,
            mavutil.mavlink.MAV_MODE_FLAG_CUSTOM_MODE_ENABLED, 4, 0, 0, 0, 0, 0,  # 4 = GUIDED
        )
        master.arducopter_arm()
        ack = master.recv_match(type="COMMAND_ACK", blocking=True, timeout=3)
        if ack and ack.command == mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM:
            if ack.result == mavutil.mavlink.MAV_RESULT_ACCEPTED:
                log("armed")
                break
            log(f"arm refused ({ack.result}); waiting for the autopilot to be ready")
        time.sleep(2)
    else:
        log("never armed")
        return 2

    master.mav.command_long_send(
        master.target_system, master.target_component,
        mavutil.mavlink.MAV_CMD_NAV_TAKEOFF, 0, 0, 0, 0, 0, 0, 0, TARGET_ALT,
    )
    log(f"takeoff commanded to {TARGET_ALT:.1f} m")

    climb_started = time.time()
    first_report = latest_position(master)
    boot_started = first_report.time_boot_ms
    reached = first_report.relative_alt / 1000.0
    boot_now = boot_started
    while time.time() - climb_started < DEADLINE:
        report = latest_position(master)
        reached = report.relative_alt / 1000.0
        boot_now = report.time_boot_ms
        if reached >= TARGET_ALT - 1.0:
            break
        time.sleep(0.2)
    wall = time.time() - climb_started
    # The autopilot's own clock is the honest one. If these two disagree by
    # much more than the real-time factor explains, the reader is the problem.
    onboard = (boot_now - boot_started) / 1000.0
    log(
        f"altitude {reached:.2f} m after {onboard:.1f} s on the autopilot's "
        f"clock ({wall:.1f} s of wall clock)"
    )

    if reached < TARGET_ALT - 1.0:
        log("did not reach the commanded altitude")
        return 3

    master.set_mode("LAND")
    log("landing")
    landed = wait(
        master,
        lambda m: m.get_type() == "GLOBAL_POSITION_INT" and m.relative_alt / 1000.0 < 0.5,
        "a landing",
        timeout=DEADLINE,
    )
    log(f"down at {landed.relative_alt / 1000.0:.2f} m")
    print(
        f"RESULT climb_onboard_seconds={onboard:.1f} climb_wall_seconds={wall:.1f} "
        f"peak_altitude={reached:.2f}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
