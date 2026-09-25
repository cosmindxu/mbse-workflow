#!/usr/bin/env python3
"""Where the CPU goes, sampled over an interval rather than averaged over a life.

`ps` reports `%cpu` as the average since a process started, which for a server
that spent its first minute loading models says nothing about what it costs
while flying. This samples `/proc` twice and reports the difference, grouped by
command, so the answer to "is the physics server the wall, or the twelve
autopilots?" is a number.

    python3 cpu.py 10        # sample over ten seconds
"""
from __future__ import annotations

import os
import pathlib
import sys
import time

CLOCK_TICKS = os.sysconf("SC_CLK_TCK")


def snapshot() -> tuple[dict[int, tuple[str, int]], int]:
    """Per-process CPU ticks, and the system-wide total."""
    processes: dict[int, tuple[str, int]] = {}
    for entry in pathlib.Path("/proc").iterdir():
        if not entry.name.isdigit():
            continue
        try:
            fields = (entry / "stat").read_text().rsplit(") ", 1)
            command = fields[0].split("(", 1)[1]
            rest = fields[1].split()
            # utime and stime are fields 14 and 15 of /proc/pid/stat, which is
            # fields 12 and 13 after the command has been split off.
            ticks = int(rest[11]) + int(rest[12])
        except (OSError, IndexError, ValueError):
            continue  # the process went away mid-read, which is normal
        processes[int(entry.name)] = (command, ticks)

    total = 0
    for line in pathlib.Path("/proc/stat").read_text().splitlines():
        if line.startswith("cpu "):
            values = [int(v) for v in line.split()[1:]]
            total = sum(values)
            break
    return processes, total


def main() -> int:
    seconds = float(sys.argv[1]) if len(sys.argv) > 1 else 10.0
    cores = os.cpu_count() or 1

    before, before_total = snapshot()
    time.sleep(seconds)
    after, after_total = snapshot()

    by_command: dict[str, float] = {}
    for pid, (command, ticks) in after.items():
        was = before.get(pid)
        if was is None or was[0] != command:
            continue
        used = (ticks - was[1]) / CLOCK_TICKS
        if used <= 0:
            continue
        by_command[command] = by_command.get(command, 0.0) + used

    print(f"CPU over {seconds:.0f} s on {cores} cores")
    for command, used in sorted(by_command.items(), key=lambda kv: -kv[1])[:8]:
        # One core fully busy for the whole interval is 100%.
        print(f"  {command:<24} {used / seconds * 100:6.1f}% of one core")

    busy = sum(by_command.values())
    print(f"  {'all processes':<24} {busy / seconds * 100:6.1f}% of one core "
          f"({busy / seconds / cores * 100:.1f}% of the machine)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
