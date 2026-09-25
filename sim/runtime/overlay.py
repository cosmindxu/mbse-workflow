#!/usr/bin/env python3
"""WP4 — the run, made watchable.

The photoreal camera is the supporting shot, not the demonstration. That was
measured rather than decided: the brief's area is 5 km on a side and twelve
members sit ~1250 m apart, so a frame wide enough to hold the fleet renders a
0.5 m drone at an eighth of a pixel. No lens fixes that. What *is* legible at
that scale is the thing the architecture is actually about — which sector is
under watch, by whom, and what the measures are doing while it happens.

So this turns an event log into a replay: the sector grid over time, coloured
by who holds it, with the measures moving beside it and every moving thing
labelled with the model element it came from. It is generated from
`events.jsonl` and nothing else, so it can be produced from a recorded run
without flying it again, and it cannot show anything the run did not do.

The output is one self-contained HTML file. No ffmpeg, no GPU, no display: a
run on a loaded machine still produces something a person can watch, and the
same file opens on a phone.
"""
from __future__ import annotations

import argparse
import html
import json
import pathlib
import sys

import yaml

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "agents"))

from log import Event  # noqa: E402


def frames_from(events: list[Event], sectors: list[dict], *, until: float,
                watching: str, step: float = 5.0) -> list[dict]:
    """The state of every sector at a regular cadence.

    A step function sampled evenly, because a replay needs frames and the log
    has events. Each frame says which member holds each sector, so the replay
    can colour by member and a handover reads as a colour changing rather than
    a gap appearing.
    """
    ids = [s["id"] for s in sectors]
    holders: dict[int, int] = {}
    ordered = sorted(
        [e for e in events if e.kind == "state" and e.member is not None],
        key=lambda e: e.t_sim,
    )
    faults = {e.t_sim: e.member for e in events if e.kind == "fault"}

    frames: list[dict] = []
    index = 0
    t = 0.0
    lost: set[int] = set()
    while t <= until:
        while index < len(ordered) and ordered[index].t_sim <= t:
            event = ordered[index]
            state = event.detail.get("to")
            sector = event.detail.get("sector")
            if state == watching and sector is not None:
                holders[sector] = event.member
            else:
                for held, member in list(holders.items()):
                    if member == event.member:
                        del holders[held]
            index += 1
        for at, member in faults.items():
            if at <= t:
                lost.add(member)
        frames.append({
            "t": round(t, 1),
            "held": {str(s): holders.get(s) for s in ids},
            "watched": sum(1 for s in ids if s in holders),
            "share": round(sum(1 for s in ids if s in holders) / len(ids), 4) if ids else 0.0,
            "lost": sorted(lost),
        })
        t += step
    return frames


PAGE = """<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title>
<style>
  :root {{
    --ink: #10221f; --dim: #5d716d; --line: #cfdad7; --ground: #f4f7f6;
    --panel: #ffffff; --held: #0f766e; --dark: #e7ecea; --lost: #b4341f;
    --warn: #b4341f;
  }}
  @media (prefers-color-scheme: dark) {{
    :root:not([data-theme="light"]) {{
      --ink: #e8efed; --dim: #93a7a3; --line: #2b3b38; --ground: #101a19;
      --panel: #16211f; --held: #2dd4bf; --dark: #1d2b29; --lost: #f87171;
      --warn: #f87171;
    }}
  }}
  * {{ box-sizing: border-box; }}
  body {{ margin: 0; background: var(--ground); color: var(--ink);
         font: 15px/1.5 ui-sans-serif, system-ui, -apple-system, sans-serif; }}
  .wrap {{ max-width: 980px; margin: 0 auto; padding-block: 28px; padding-inline: 16px; }}
  h1 {{ font-size: 1.4rem; margin: 0 0 .25rem; text-wrap: balance; }}
  .sub {{ color: var(--dim); margin: 0 0 1.5rem; }}
  .stage {{ display: grid; grid-template-columns: minmax(0,1fr) 260px; gap: 20px; align-items: start; }}
  @media (max-width: 720px) {{ .stage {{ grid-template-columns: 1fr; }} }}
  .grid {{ display: grid; gap: 6px; background: var(--panel); padding: 12px;
           border: 1px solid var(--line); border-radius: 10px; }}
  .cell {{ aspect-ratio: 1; border-radius: 6px; background: var(--dark);
           display: grid; place-content: center; font-size: 12px; color: var(--dim);
           transition: background .25s, color .25s; }}
  .cell.held {{ background: var(--held); color: #fff; }}
  .panel {{ background: var(--panel); border: 1px solid var(--line);
            border-radius: 10px; padding: 14px; }}
  .metric {{ margin-bottom: 14px; }}
  .metric b {{ display: block; font-size: 1.6rem; font-variant-numeric: tabular-nums; }}
  .metric span {{ color: var(--dim); font-size: 12px; }}
  .miss {{ color: var(--warn); }}
  .bar {{ height: 6px; background: var(--dark); border-radius: 3px; overflow: hidden; margin-top: 6px; }}
  .bar i {{ display: block; height: 100%; background: var(--held); }}
  .controls {{ display: flex; gap: 10px; align-items: center; margin: 16px 0 8px; }}
  input[type=range] {{ flex: 1; }}
  button {{ font: inherit; padding: 6px 14px; border-radius: 6px; cursor: pointer;
            border: 1px solid var(--line); background: var(--panel); color: var(--ink); }}
  .note {{ color: var(--dim); font-size: 13px; border-top: 1px solid var(--line);
           margin-top: 22px; padding-top: 14px; }}
  .note code {{ font-size: 12px; }}
  .caveat {{ border-left: 3px solid var(--warn); padding-left: 12px; margin-top: 10px; }}
</style></head><body>
<div class="wrap">
  <h1>{title}</h1>
  <p class="sub">{subtitle}</p>

  <div class="stage">
    <div>
      <div class="grid" id="grid" style="grid-template-columns: repeat({columns}, 1fr)"></div>
      <div class="controls">
        <button id="play">Play</button>
        <input type="range" id="scrub" min="0" max="{last}" value="0">
        <span id="clock" style="font-variant-numeric: tabular-nums"></span>
      </div>
    </div>
    <div class="panel">
      <div class="metric">
        <span>{measure_a} — target {target_a}</span>
        <b id="share">—</b>
        <div class="bar"><i id="sharebar" style="width:0%"></i></div>
      </div>
      <div class="metric">
        <span>sectors under watch</span>
        <b id="count">—</b>
      </div>
      <div class="metric">
        <span>members lost</span>
        <b id="lost">0</b>
      </div>
    </div>
  </div>

  <div class="note">
    {footer}
    <div class="caveat">{caveat}</div>
  </div>
</div>
<script>
const FRAMES = {frames};
const SECTORS = {sector_ids};
const TARGET = {target_value};
const grid = document.getElementById('grid');
const cells = {{}};
for (const id of SECTORS) {{
  const cell = document.createElement('div');
  cell.className = 'cell';
  cell.textContent = id;
  grid.appendChild(cell);
  cells[id] = cell;
}}
const scrub = document.getElementById('scrub');
const clock = document.getElementById('clock');
const share = document.getElementById('share');
const sharebar = document.getElementById('sharebar');
const count = document.getElementById('count');
const lost = document.getElementById('lost');
function draw(i) {{
  const f = FRAMES[i];
  for (const id of SECTORS) {{
    const holder = f.held[String(id)];
    cells[id].className = holder === null || holder === undefined ? 'cell' : 'cell held';
    cells[id].textContent = holder === null || holder === undefined ? id : id + ' \\u2190 ' + holder;
  }}
  clock.textContent = f.t.toFixed(0) + ' s';
  share.textContent = f.share.toFixed(2);
  share.className = f.share >= TARGET ? '' : 'miss';
  sharebar.style.width = (f.share * 100) + '%';
  count.textContent = f.watched + ' of ' + SECTORS.length;
  lost.textContent = f.lost.length;
}}
scrub.addEventListener('input', () => draw(+scrub.value));
let timer = null;
document.getElementById('play').addEventListener('click', (e) => {{
  if (timer) {{ clearInterval(timer); timer = null; e.target.textContent = 'Play'; return; }}
  e.target.textContent = 'Pause';
  timer = setInterval(() => {{
    const next = (+scrub.value + 1) % FRAMES.length;
    scrub.value = next; draw(next);
  }}, 60);
}});
draw(0);
</script>
</body></html>
"""


def build(run: pathlib.Path, out: pathlib.Path,
          generated: pathlib.Path | None = None) -> pathlib.Path:
    """`run` is where the flight was recorded; `generated` is what T-05 wrote.

    They are the same directory when a run writes into its own generation, and
    different when it does not, so the caller says which is which rather than
    this guessing from a path.
    """
    source = generated or run.parent
    fleet = yaml.safe_load((source / "fleet.yaml").read_text())
    mapping = yaml.safe_load((source / "mapping.yaml").read_text())
    results = json.loads((run / "results.json").read_text())
    events = [Event(**json.loads(l)) for l in (run / "events.jsonl").read_text().splitlines() if l.strip()]

    sectors = fleet["sectors"][: results.get("members_flown", len(fleet["sectors"]))]
    watching = next((r["state"] for r in mapping["states"] if r["autopilot"] and "AUTO" in str(r["autopilot"])), "Watching")
    duration = float(results.get("scenario_seconds", 1200))
    frames = frames_from(events, sectors, until=duration, watching=watching)

    measures = {m["measure"]: m for m in results.get("measures", [])}
    watch = measures.get("areaUnderWatchShare", {})
    columns = max(1, int(len(sectors) ** 0.5 + 0.999))

    root = fleet["member_definition"].split("::")[0]
    caveat = (
        "A sector counts as watched when a member is over it. The model states no sensor "
        "footprint anywhere, so this is T-05's reading of coverage and not the architecture's: "
        "it answers how many sectors had someone above them, which is a different question from "
        "how much ground was under watch."
    )
    if results.get("offline"):
        caveat += (" This run was flown offline — the agents against cooperative stand-ins, with "
                   "no autopilot and no physics.")
    if results.get("members_flown", 0) < len(fleet.get("instances", [])):
        caveat += (f" Only {results['members_flown']} of {len(fleet['instances'])} members flew, "
                   "so this is not the fleet the brief specifies.")

    page = PAGE.format(
        title=f"{root} — the watch, replayed",
        subtitle=html.escape(
            f"{len(sectors)} sectors, {results.get('members_flown', '?')} members, "
            f"{duration:.0f} s of simulated time at a declared time scale of "
            f"{fleet['duty_cycle']['time_scale']}"
        ),
        columns=columns,
        last=len(frames) - 1,
        frames=json.dumps(frames),
        sector_ids=json.dumps([s["id"] for s in sectors]),
        measure_a="areaUnderWatchShare",
        target_a=watch.get("target", "—"),
        target_value=watch.get("target", 0.9),
        footer=html.escape(
            "Generated from the run's own event log. Every sector, member and measure here "
            f"traces to {root}: the sectors are the ones T-05 drew from the area budget, the "
            "handovers are SurveillanceDroneSwarm::PA::handOverSector, and the coverage is "
            "computed from the states the members reported."
        ),
        caveat=html.escape(caveat),
    )
    out.write_text(page, encoding="utf-8")
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run", type=pathlib.Path, required=True,
                        help="a run directory written by run.py (holds events.jsonl)")
    parser.add_argument("--out", type=pathlib.Path, default=None)
    parser.add_argument("--from", dest="generated", type=pathlib.Path, default=None,
                        help="the directory T-05 generated (default: the run's parent)")
    args = parser.parse_args()
    out = args.out or (args.run / "replay.html")
    build(args.run, out, args.generated)
    print(f"[overlay] {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
