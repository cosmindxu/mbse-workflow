#!/usr/bin/env python3
"""How much simulated time a second of wall clock buys.

Reads `gz topic -e -t /world/<name>/stats` on stdin and reports the factor
across the whole window, not a snapshot: a snapshot taken while the autopilot
is settling and one taken mid-climb disagree by a factor of three, and the
fleet size in WP0.3 is sized from this number.

The factor that matters is the ratio of the *elapsed* simulated time to the
elapsed real time between the first and last sample. The per-sample
`real_time_factor` Gazebo publishes is an instantaneous estimate; it is
reported too, as a spread, because a mean that hides a stall is a lie.
"""
import re
import sys

STAMP = re.compile(r"^(sim_time|real_time) \{")
SEC = re.compile(r"^\s*sec: (-?\d+)")
NSEC = re.compile(r"^\s*nsec: (-?\d+)")
FACTOR = re.compile(r"^real_time_factor: ([\d.eE+-]+)")


def main() -> int:
    samples: list[tuple[float, float]] = []
    factors: list[float] = []
    field: str | None = None
    sec = nsec = 0
    pending: dict[str, float] = {}

    for line in sys.stdin:
        line = line.rstrip("\n")
        if (m := STAMP.match(line)) is not None:
            field, sec, nsec = m.group(1), 0, 0
            continue
        if field is not None:
            if (m := SEC.match(line)) is not None:
                sec = int(m.group(1))
                continue
            if (m := NSEC.match(line)) is not None:
                nsec = int(m.group(1))
                continue
            if line.startswith("}"):
                pending[field] = sec + nsec / 1e9
                field = None
                if "sim_time" in pending and "real_time" in pending:
                    samples.append((pending["sim_time"], pending["real_time"]))
                    pending = {}
                continue
        if (m := FACTOR.match(line)) is not None:
            factors.append(float(m.group(1)))

    if len(samples) < 2:
        print("RTF no usable samples", file=sys.stderr)
        return 1

    sim_span = samples[-1][0] - samples[0][0]
    real_span = samples[-1][1] - samples[0][1]
    if real_span <= 0:
        print("RTF the clock did not advance", file=sys.stderr)
        return 1

    mean = sim_span / real_span
    print(
        f"RTF mean={mean:.3f} over {real_span:.1f} s of wall clock "
        f"({sim_span:.1f} s simulated, {len(samples)} samples)"
    )
    if factors:
        ordered = sorted(factors)
        median = ordered[len(ordered) // 2]
        print(
            f"RTF instantaneous min={ordered[0]:.3f} median={median:.3f} "
            f"max={ordered[-1]:.3f}"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
