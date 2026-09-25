#!/usr/bin/env python3
"""The measures, computed from the run rather than claimed.

Two of the brief's measures can be computed from the event log alone, and those
are the two the forerunner scenario is built around:

  areaUnderWatchShare        the share of sectors with a member watching them,
                             averaged over the watched period
  coverageLossOnMemberLoss   how much of that share the fleet lost when a
                             member was killed, before it re-spread

Both are pure functions over the log, so they are tested against logs written by
hand and can be recomputed from a recorded run without flying it again.

**What "coverage" means here, stated because the number is meaningless without
it.** T-05 divides the area into one sector per member and a sector counts as
watched when a member is in the `Watching` state over it. That is T-05's
reading, not the model's: v7 states no sensor footprint anywhere, so nothing in
the architecture says how much ground one drone can watch. A share computed this
way answers "how many of the twelve sectors had someone over them", which is
not the same question as "how much of the area was under watch". The report
carries this sentence next to the number.
"""
from __future__ import annotations

from dataclasses import dataclass

from log import Event, state_changes


@dataclass(frozen=True)
class Coverage:
    """The watched share over time, and what it averages to."""

    samples: tuple[tuple[float, float], ...]
    """(t_sim, share) at every moment the share changed."""
    mean: float
    lowest: float
    sectors: int

    def share_at(self, t: float) -> float:
        share = 0.0
        for at, value in self.samples:
            if at > t:
                break
            share = value
        return share


def coverage_over_time(
    events: list[Event], *, sectors: int, watching: str, until: float | None = None
) -> Coverage:
    """The share of sectors under watch, as a step function over the run.

    A member holds its sector from the moment it reports `Watching` until it
    reports anything else. The mean is time-weighted: a fleet that watched
    everything for one second and nothing for an hour did not average a half.
    """
    holding: dict[int, str] = {}
    samples: list[tuple[float, float]] = [(0.0, 0.0)]
    changes = state_changes(events)
    for event in changes:
        if event.member is None:
            continue
        state = event.detail.get("to")
        sector = event.detail.get("sector")
        if state == watching and sector is not None:
            holding[event.member] = sector
        elif event.member in holding:
            del holding[event.member]
        else:
            continue
        share = len(set(holding.values())) / sectors if sectors else 0.0
        if samples and samples[-1][0] == event.t_sim:
            samples[-1] = (event.t_sim, share)
        else:
            samples.append((event.t_sim, round(share, 4)))

    end = until if until is not None else (changes[-1].t_sim if changes else 0.0)
    if end <= 0:
        return Coverage(samples=tuple(samples), mean=0.0, lowest=0.0, sectors=sectors)

    # Time-weighted mean over [0, end].
    total = 0.0
    for i, (at, share) in enumerate(samples):
        nxt = samples[i + 1][0] if i + 1 < len(samples) else end
        total += share * max(0.0, min(nxt, end) - at)
    lowest = min((share for _, share in samples), default=0.0)
    return Coverage(
        samples=tuple(samples),
        mean=round(total / end, 4),
        lowest=round(lowest, 4),
        sectors=sectors,
    )


@dataclass(frozen=True)
class LossImpact:
    """What the fleet lost when a member was taken, and whether it recovered."""

    window: float = 0.0
    """How long after the loss was charged to it. Printed with the number."""
    before: float = 0.0
    lowest_after: float = 0.0
    loss: float = 0.0
    recovered_to: float = 0.0
    recovery_seconds: float | None = None
    lost_at: float = 0.0


def loss_on_member_loss(
    events: list[Event], coverage: Coverage, *, settle: float = 30.0,
    window: float = 120.0,
) -> LossImpact | None:
    """The drop in watched share caused by losing a member.

    `before` is the share just before the kill and `lowest_after` the worst the
    fleet reached **within `window` seconds of it**. The window is the point:
    without one, this measure charges the loss with everything that happened
    afterwards. The first version had no window and reported a loss of 1.0 on a
    run where the fleet simply rotated into its recharge an hour later — a true
    fact about the coverage curve and a false one about the loss.

    `window` therefore has to be long enough to contain the re-spread and short
    enough to exclude the next rotation; the report prints it beside the number
    so the reader knows what was charged to the loss.
    """
    kills = [e for e in events if e.kind == "fault" and e.detail.get("fault") == "member lost"]
    if not kills:
        return None
    lost_at = kills[0].t_sim
    before = coverage.share_at(lost_at - 0.001)

    after = [(at, share) for at, share in coverage.samples
             if lost_at <= at <= lost_at + window]
    if not after:
        return LossImpact(window, before, before, 0.0, before, None, lost_at)
    lowest_after = min(share for _, share in after)
    recovered_at = next((at for at, share in after if at > lost_at + settle and share >= before), None)
    return LossImpact(
        window=window,
        before=round(before, 4),
        lowest_after=round(lowest_after, 4),
        loss=round(max(0.0, before - lowest_after), 4),
        recovered_to=round(after[-1][1], 4),
        recovery_seconds=round(recovered_at - lost_at, 1) if recovered_at else None,
        lost_at=lost_at,
    )


def against_target(value: float, target: float, sense: str) -> bool:
    """Whether a measured value meets the brief's target, the brief's way round."""
    return value >= target if sense == "max" else value <= target


def coverage_after_ground_loss(
    events: list[Event], coverage: Coverage, *, until: float
) -> dict | None:
    """The watch share once the ground station stops being heard.

    `groundLinkLossAreaUnderWatchShare` in the brief, and the measure the whole
    architecture decision turns on: v7's alternative 1 estimates 0.55 for it and
    alternative 2 estimates 0.91, because one of them decides rotation on the
    ground and the other decides it between members. Running the same scenario
    under both, with the link taken away, is what turns that pair of claims into
    a pair of numbers.

    Time-weighted over the window from the cut to the end of the run, so a fleet
    that held the watch for a minute and then lost it does not average out to
    looking healthy.
    """
    cuts = [e for e in events if e.kind == "fault" and e.detail.get("fault") == "ground link lost"]
    if not cuts:
        return None
    at = cuts[0].t_sim
    if until <= at:
        return None

    total = 0.0
    samples = [(t, v) for t, v in coverage.samples if t <= until]
    for i, (t, share) in enumerate(samples):
        nxt = samples[i + 1][0] if i + 1 < len(samples) else until
        start, end = max(t, at), min(nxt, until)
        if end > start:
            total += share * (end - start)
    window = until - at
    after = [v for t, v in coverage.samples if t >= at]
    return {
        "cut_at": at,
        "window_seconds": round(window, 1),
        "before": round(coverage.share_at(at - 0.001), 4),
        "mean_after": round(total / window, 4),
        "lowest_after": round(min(after), 4) if after else 0.0,
    }
