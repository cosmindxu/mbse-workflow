#!/usr/bin/env python3
"""The tutorials page of the site, written from the scenarios and the videos.

Every title, description and duration on the page comes from the scenario files
(`scenarios/*.json`) and from the rendered videos themselves (ffprobe), so the
page cannot describe a video that is not there or say it lasts longer than it
does.

    python3 docs/tutorials/make-page.py          # writes site/tutorials.html
"""
from __future__ import annotations

import html
import json
import pathlib
import subprocess

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
OUT = ROOT / "site" / "tutorials.html"


def duration(mp4: pathlib.Path) -> str:
    secs = float(subprocess.check_output(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(mp4)]).decode().strip())
    return f"{int(secs // 60)}:{int(round(secs % 60)):02d}"


def main() -> None:
    items = []
    for sc_path in sorted((HERE / "scenarios").glob("*.json")):
        sc = json.loads(sc_path.read_text())
        name = sc["name"]
        mp4 = HERE / f"{name}.mp4"
        if not mp4.exists():
            raise SystemExit(f"{name}: no video at {mp4} — record it first")
        n = name.split("-", 1)[0]
        items.append(f"""
      <article class="tut" id="t{n}">
        <h2><span class="num">{n}</span> {html.escape(sc['title'])}</h2>
        <p>{html.escape(sc['subtitle'])} <span class="dur">{duration(mp4)}</span></p>
        <video controls preload="none" poster="{name}-poster.jpg" playsinline>
          <source src="{name}.mp4" type="video/mp4" />
          <track kind="subtitles" srclang="en" label="English" src="{name}.vtt" />
        </video>
      </article>""")
    OUT.write_text(TEMPLATE.replace("{{ITEMS}}", "".join(items)))
    print(f"wrote {OUT.relative_to(ROOT)}: {len(items)} tutorials")


TEMPLATE = """<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Model tutorials</title>
    <meta name="description" content="Silent, subtitled video tutorials: how to read and edit every diagram of the drone-swarm model in Sysprose, one video per layer." />
    <style>
      :root { --bg: #ffffff; --text: #1f2733; --muted: #6b7686; --accent: #2563eb; --border: #d8dce3; --card: #f5f6f8; }
      @media (prefers-color-scheme: dark) {
        :root { --bg: #14181f; --text: #e6e9ef; --muted: #9aa4b2; --accent: #7aa7ff; --border: #2b323d; --card: #1a1f27; }
      }
      body { margin: 0; background: var(--bg); color: var(--text);
        font: 16px/1.6 -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
      main { max-width: 60rem; margin: 0 auto; padding: 32px 16px 56px; }
      h1 { font-size: 1.7rem; line-height: 1.25; margin: 0 0 8px; }
      .lede { color: var(--muted); margin: 0 0 28px; }
      a { color: var(--accent); }
      .tut { margin: 0 0 36px; padding: 0 0 28px; border-bottom: 1px solid var(--border); }
      .tut h2 { font-size: 1.2rem; margin: 0 0 4px; }
      .tut p { margin: 0 0 12px; color: var(--muted); }
      .num { display: inline-block; min-width: 1.6em; color: var(--accent); }
      .dur { white-space: nowrap; font-variant-numeric: tabular-nums; }
      .dur::before { content: '· '; }
      video { display: block; width: 100%; height: auto; border-radius: 6px; background: #0f172a; }
      small { display: block; margin-top: 8px; color: var(--muted); }
    </style>
  </head>
  <body>
    <main>
      <h1>Reading and editing the drone-swarm model</h1>
      <p class="lede">
        One silent video per layer of the model, captioned step by step: how to open each
        diagram, what it shows at that layer, and — in each — one element deleted before
        recording and added back on camera. The model opens in Sysprose, a browser modeller for
        a SysML v2–style notation: <a href="../app/?model=model/SurveillanceDroneSwarm.sysml">open the model</a>
        and follow along. Edits stay in your browser; how a change reaches the repository is in
        <a href="https://github.com/cosmindxu/mbse-workflow/blob/main/CONTRIBUTING.md#proposing-a-change-to-the-model">CONTRIBUTING.md</a>.
      </p>
{{ITEMS}}
      <small>
        The videos are recorded from the app by <code>scripts/record-tutorial.mjs</code> in
        Sysprose, from the scenarios in <code>docs/tutorials/scenarios/</code>; the captions are
        also available as subtitles (CC). Sysprose is a candidate, not a certified or
        conformance-tested implementation. SysML is a trademark of the Object Management Group.
      </small>
    </main>
  </body>
</html>
"""

if __name__ == "__main__":
    main()
