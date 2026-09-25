#!/usr/bin/env python3
"""WP5 — claimed against simulated.

The report a run leaves behind. Three columns matter and the rest is context:
what the brief asked for, what the architecture claimed, and what the run did.
A number that contradicts a claim is a finding and is printed as one; the
simulation is never tuned until it agrees.

Everything here is derived from `results.json` and the event log, so the report
can be regenerated from a recorded run without flying it again, and it cannot
say anything the run did not do.

Three things it always prints, because a report that omits them is worse than
no report:

  * **what was not exercised** — a rule that held because nothing tested it is
    not evidence, and the demonstration's limits belong beside its results;
  * **what the numbers mean** — a coverage share computed over sectors T-05
    drew is not the same claim as coverage of the area;
  * **how to reproduce it** — the command, with the arguments this run used.
"""
from __future__ import annotations

import argparse
import json
import pathlib
import sys

import yaml


def verdict_of(measure: dict) -> str:
    if measure.get("meets_target"):
        return "meets the target"
    return "**misses the target**"


def claim_line(measure: dict, claimed: dict) -> str:
    """One measure's row: target, claim, result, and whether they agree."""
    name = measure["measure"]
    estimate = claimed.get(name, {}).get("estimate")
    kind = claimed.get(name, {}).get("estimate_kind", "—")
    sense = "≥" if measure["sense"] == "max" else "≤"
    simulated = measure["simulated"]

    if estimate is None:
        # A derived estimate has no literal to compare against: the model fixes
        # it by constraint. Saying so is more useful than a blank, and more
        # honest than pretending this read the derivation.
        claim = "derived by constraint" if kind == "derived" else "not stated"
        agreement = "—"
    else:
        claim = f"{estimate:g} (stated)"
        # "Agrees" is a deliberately loose word: within a tenth of the claim.
        # The point of the column is to show contradiction, not to grade.
        close = abs(simulated - estimate) <= max(0.1 * abs(estimate), 1e-9)
        agreement = "agrees" if close else f"**contradicts** ({simulated:g} vs {estimate:g})"

    return (
        f"| `{name}` | {sense} {measure['target']:g} | {claim} | "
        f"{simulated:g} | {verdict_of(measure)} | {agreement} |"
    )


def build(run: pathlib.Path, generated: pathlib.Path) -> str:
    results = json.loads((run / "results.json").read_text())
    fleet = yaml.safe_load((generated / "fleet.yaml").read_text())
    mapping = yaml.safe_load((generated / "mapping.yaml").read_text())
    claimed = {m["measure"]: m for m in mapping.get("measures", [])}
    root = fleet["member_definition"].split("::")[0]
    duty = fleet["duty_cycle"]

    lines: list[str] = []
    add = lines.append

    add(f"# {root} — the model, flown")
    add("")
    add(f"A run of the scenario T-05 generated from this architecture: "
        f"{results['members_flown']} member(s) over {results['sectors']} sector(s), "
        f"{results['scenario_seconds']:.0f} s of simulated time at a declared time scale of "
        f"{duty['time_scale']}.")
    add("")
    if results.get("offline"):
        add("> **Flown offline.** The agents ran against cooperative stand-ins: no autopilot, "
            "no physics, no Gazebo. Everything about the coordination, the rules and the "
            "measures is exercised; nothing about whether an aircraft obeys is.")
        add("")

    # -- claimed against simulated -----------------------------------------
    add("## Claimed against simulated")
    add("")
    add("| Measure | Brief's target | Architecture's estimate | Simulated | Against the target | Against the claim |")
    add("|---|---|---|---|---|---|")
    for measure in results.get("measures", []):
        add(claim_line(measure, claimed))
    add("")
    contradictions = [
        m for m in results.get("measures", [])
        if claimed.get(m["measure"], {}).get("estimate") is not None
        and abs(m["simulated"] - claimed[m["measure"]]["estimate"])
        > max(0.1 * abs(claimed[m["measure"]]["estimate"]), 1e-9)
    ]
    if contradictions:
        add("### Findings")
        add("")
        for measure in contradictions:
            estimate = claimed[measure["measure"]]["estimate"]
            add(f"- **`{measure['measure']}`**: the architecture estimates {estimate:g}, "
                f"the run measured {measure['simulated']:g}. A simulated value that contradicts "
                "an estimate is a finding about the architecture, not a defect of the "
                "simulation, and nothing here was tuned until they agreed.")
        add("")

    # -- the rules ----------------------------------------------------------
    add("## The rules the checker proved, over this run")
    add("")
    add("| Rule | Kind | Outcome | Evidence |")
    add("|---|---|---|---|")
    for rule in results.get("rules", []):
        outcome = {"held": "held", "not-checked": "**not checked**", "broken": "**BROKEN**"}[
            rule["outcome"]
        ]
        if rule["outcome"] == "held" and rule["vacuous"]:
            outcome = "held, *never exercised*"
        add(f"| `{rule['rule']}` | {rule['kind']} | {outcome} | {rule['detail']} |")
    add("")
    add("Sysprose proves these over the state machine; this watches them over the flight. They "
        "are different claims: the checker says the design cannot break the rule, the monitor "
        "says this run did not. A rule marked *never exercised* held because nothing put it to "
        "the test, which is not evidence that it works.")
    add("")

    # -- what it did not do -------------------------------------------------
    add("## What this did not exercise")
    add("")
    for limit in results.get("not_exercised", []):
        add(f"- {limit}")
    missing = (results.get("functions") or {}).get("not_implemented") or []
    if missing:
        add(f"- **{len(missing)} of the model's functions are not implemented by this runtime** "
            "and did not run at all. A demonstration is evidence about the parts it "
            "demonstrates, and these are not among them:")
        for entry in missing:
            if isinstance(entry, dict):
                add(f"  - `{entry['function']}` — {entry['why']}")
            else:
                add(f"  - `{entry}`")
    if results.get("unfilled_sectors"):
        add(f"- {results['unfilled_sectors']} occasion(s) when a sector went unwatched with no "
            "member charged to send. That is the brief's own arithmetic rather than a failure "
            "of the coordination: the duty cycle puts a fraction of the fleet in the air at any "
            "moment, and the sector count is the fleet size.")
    add("")

    # -- traceability -------------------------------------------------------
    add("## Where every moving thing came from")
    add("")
    add("| In the run | In the model |")
    add("|---|---|")
    add(f"| the member | `{fleet['member_definition']}` |")
    add(f"| the fleet, {fleet['size']} of them | `{fleet['fleet_usage']}` "
        f"(from `{fleet['size_from']}`) |")
    for function in mapping.get("coordination_behaviours", [])[:6]:
        add(f"| the behaviour `{function.split('::')[-1]}` | `{function}` |")
    for event in mapping.get("operator_events", [])[:3]:
        add(f"| the operator event `{event.split('::')[-1]}` | `{event}` |")
    add(f"| the flight budget, {duty['flight_seconds']} s | `{duty['flight_from']}` |")
    add(f"| the recharge, {duty['recharge_seconds']} s | `{duty['recharge_from']}` |")
    add("")
    add(f"Charge is the coordination agent's, not the autopilot's: "
        f"{fleet['charge_model']['why_not_the_autopilot']}.")
    add("")

    # -- reproduction -------------------------------------------------------
    add("## Reproducing this")
    add("")
    add("```")
    add(f"npx tsx src/cli.ts simulate --out <the run> --into {generated}")
    add(f"python3 sim/runtime/run.py --run {generated}"
        + (" --offline" if results.get("offline") else "")
        + f" --out {run}")
    add(f"python3 sim/runtime/overlay.py --run {run} --from {generated}")
    add("```")
    add("")
    add(f"The event log this was computed from is `{run / 'events.jsonl'}`; the replay is "
        f"`{run / 'replay.html'}`. Both are generated, and neither can show anything the run "
        "did not do.")
    add("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run", type=pathlib.Path, required=True)
    parser.add_argument("--from", dest="generated", type=pathlib.Path, default=None)
    parser.add_argument("--out", type=pathlib.Path, default=None)
    args = parser.parse_args()
    generated = args.generated or args.run.parent
    out = args.out or (args.run / "README.md")
    out.write_text(build(args.run, generated), encoding="utf-8")
    print(f"[report] {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
