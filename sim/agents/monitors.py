#!/usr/bin/env python3
"""The model's rules, checked against what actually flew.

Sysprose proves these over the state machine; these watch them over the run. The
two are different claims and both are worth having: the checker says the design
cannot break the rule, the monitor says this flight did not. A monitor that
fails where the checker passed means the runtime does not implement the machine
the checker proved — which is a finding about the demonstration, not about the
architecture.

Every monitor is a pure function over the event log, so each one is tested
against a log written by hand, including logs that break the rule.

The rule kinds come from the brief and are carried through T-05's
`mapping.yaml`:

  winsUntil        once X holds, Y does not happen until Z
  canAlwaysReturn  from anywhere reachable, Z is still reachable
"""
from __future__ import annotations

from dataclasses import dataclass

from log import Event, state_changes


@dataclass(frozen=True)
class Verdict:
    """What a monitor concluded, and the evidence for it."""

    rule: str
    kind: str
    held: bool
    checked: int
    """How many opportunities the run gave this rule to be broken."""
    detail: str
    breaches: tuple[str, ...] = ()

    @property
    def vacuous(self) -> bool:
        """True when nothing in the run could have broken the rule.

        A rule that held because the situation never arose is not evidence the
        rule works, and the report must not print it as though it were.
        """
        return self.held and self.checked == 0


def _states_by_member(events: list[Event]) -> dict[int, list[tuple[float, str]]]:
    per: dict[int, list[tuple[float, str]]] = {}
    for event in state_changes(events):
        if event.member is None:
            continue
        state = event.detail.get("to")
        if state is None:
            continue
        per.setdefault(event.member, []).append((event.t_sim, state))
    return per


def wins_until(
    events: list[Event], rule: str, *, trigger: str, forbidden: str, until: str
) -> Verdict:
    """Once `trigger`, `forbidden` must not occur before `until`.

    `RecallWins`: once a drone is recalled it does not watch again until it has
    landed. The check walks each member's own history, so one member's recall
    says nothing about another's.
    """
    breaches: list[str] = []
    opportunities = 0
    for member, history in _states_by_member(events).items():
        armed_at: float | None = None
        for at, state in history:
            if state == trigger:
                armed_at = at
                opportunities += 1
            elif armed_at is not None:
                if state == until:
                    armed_at = None
                elif state == forbidden:
                    breaches.append(
                        f"member {member} entered {forbidden} at t={at:.1f}s, "
                        f"{at - armed_at:.1f}s after {trigger} and before {until}"
                    )
                    armed_at = None
    held = not breaches
    return Verdict(
        rule=rule,
        kind="winsUntil",
        held=held,
        checked=opportunities,
        detail=(
            f"{opportunities} occurrence(s) of {trigger}; "
            + ("none followed by " + forbidden + " before " + until
               if held else f"{len(breaches)} breach(es)")
        ),
        breaches=tuple(breaches),
    )


def can_always_return(
    events: list[Event], rule: str, *, home: str, from_states: tuple[str, ...] = (),
    ended_at: float | None = None,
) -> Verdict:
    """From wherever a member got to, it still reached `home`.

    `ReturnsWhenIsolated`: from any situation a drone can be in, it can always
    get back to landed. Over a finite run this is the weaker, honest reading —
    every member that left `home` came back to it — and the verdict says so
    rather than claiming the checker's result.

    **A member still flying when the run ended has not failed to return.** It
    has not finished. A run cut short at 150 s reported both of its members as
    breaches of this rule while they were dutifully watching their sectors,
    which is a fabricated breach and worse than no verdict: it accuses an
    architecture of something the run never gave it a chance to do. Those
    members are excluded from the judgement and counted separately, and a run
    where every member is in that position concludes nothing at all.
    """
    breaches: list[str] = []
    opportunities = 0
    unfinished: list[int] = []
    last = ended_at if ended_at is not None else max(
        (e.t_sim for e in state_changes(events)), default=0.0
    )
    for member, history in _states_by_member(events).items():
        states = [s for _, s in history]
        if from_states and not any(s in from_states for s in states):
            continue
        left = [s for s in states if s != home]
        if not left:
            continue
        if states[-1] != home and history[-1][0] <= last:
            # Still away when the log stops: the run ended first.
            unfinished.append(member)
            continue
        opportunities += 1
        if home not in states[states.index(left[0]):]:
            breaches.append(
                f"member {member} reached {states[-1]} and never returned to {home}"
            )
    held = not breaches
    note = ""
    if unfinished:
        note = (
            f"; {len(unfinished)} member(s) were still away when the run ended and "
            "are not judged — the run finished before they could return"
        )
    return Verdict(
        rule=rule,
        kind="canAlwaysReturn",
        held=held,
        checked=opportunities,
        detail=(
            f"{opportunities} member(s) left {home} and finished their sortie; "
            + ("all returned" if held else f"{len(breaches)} did not")
            + note
        ),
        breaches=tuple(breaches),
    )


# How a rule from the brief is checked, by kind. The state names are the
# model's own, read from mapping.yaml — never typed in here.
def check_rules(
    events: list[Event],
    rules: list[dict],
    *,
    recalled: str,
    watching: str,
    landed: str,
    outside: str | None = None,
    ended_at: float | None = None,
    states: tuple[str, ...] | None = None,
) -> list[Verdict]:
    """Every rule the brief states, checked over one run.

    A rule whose kind this does not know is reported as unchecked rather than
    passed: silence about a rule is not the same as a rule that held.
    """
    # A `winsUntil` rule is only checkable when the state that arms it can be
    # identified. Guessing wrong is worse than not checking: an earlier version
    # of this armed *every* such rule on `Recalled`, so `QuarantinedStaysOut`
    # was reported as held on the strength of a recall it has nothing to do
    # with — a pass for a rule nobody had checked.
    # How a rule's trigger is found, in order of how much it is worth trusting:
    # a state of the model whose name appears in the rule's name is the rule
    # naming its own trigger (`QuarantinedStaysOut` → `Quarantined`), and the
    # hints below are for rules that name the situation rather than the state
    # (`GeofenceBreachEndsWatch` → `OutsideClearance`).
    hints = {"recall": recalled, "geofence": outside, "clearance": outside, "fence": outside}
    verdicts: list[Verdict] = []
    for rule in rules:
        name = rule.get("rule") or rule.get("name", "?")
        kind = rule.get("kind", "?")
        if kind == "winsUntil":
            from_model = sorted(
                (s for s in (states or ()) if s and s.lower() in name.lower()),
                key=len, reverse=True,
            )
            trigger = from_model[0] if from_model else next(
                (state for word, state in hints.items()
                 if state and word in name.lower()),
                None,
            )
            if trigger is None:
                verdicts.append(Verdict(
                    rule=name, kind=kind, held=False, checked=0,
                    detail=(
                        f"no state in this run identifies what arms {name!r} — "
                        "not checked, and not passed. The monitor needs the "
                        "model to say which state the rule starts from."
                    ),
                ))
                continue
            verdicts.append(
                wins_until(events, name, trigger=trigger, forbidden=watching, until=landed)
            )
        elif kind == "canAlwaysReturn":
            verdicts.append(can_always_return(events, name, home=landed, ended_at=ended_at))
        else:
            verdicts.append(
                Verdict(
                    rule=name,
                    kind=kind,
                    held=False,
                    checked=0,
                    detail=f"no monitor for a {kind!r} rule — not checked, not passed",
                )
            )
    return verdicts


def worth_reporting(armed: int, total: int) -> tuple[bool, str]:
    """Whether a run produced anything a report may honestly quote.

    A fleet where nothing armed has not flown, and its measures are not
    measures: a coverage of 0.0 from twelve aircraft that never left the pad is
    a fact about the afternoon, not about the architecture. This once got as
    far as printing a rule verdict of BROKEN for a design that was never
    exercised, which is a fabricated finding.
    """
    if armed <= 0:
        return False, (
            "no autopilot armed, so nothing flew: measures and rule verdicts "
            "would be fabrications. Read what the autopilots said before blaming "
            "the machine — an EKF that reports an origin and GPS was ready, and "
            "the fault is then in the asking, not in the host."
        )
    if armed < total:
        return True, (
            f"only {armed} of {total} armed: every measure is over the fleet that "
            "flew, not the fleet the brief specifies, and must be read that way"
        )
    return True, f"all {total} armed"
