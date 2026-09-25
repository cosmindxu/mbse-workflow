#!/usr/bin/env python3
"""The front-page figure: what this workflow did to one drone swarm.

One claim, drawn: the architecture estimated 0.92 of the area under watch at
any moment; the brief's own duty cycle allows at most 0.40; every gate passed
the claim, simulating the model exposed it, and a gate now stops it. The
numbers are v7's; the grid is the brief's arithmetic, 4.8 of twelve aloft on
average, not a frame of the flight.

Two files, one geometry: GitHub picks the dark one through `<picture>` and a
`prefers-color-scheme` media query, so the figure reads on either ground.
Colours are written as presentation attributes because GitHub strips `<style>`
from SVG in a README, and nothing here relies on `currentColor`, which an
`<img>` cannot inherit.

    python3 docs/diagram/hero.py
"""
from __future__ import annotations

import pathlib

W, H = 1180, 492

LIGHT = dict(
    ink="#12282b", dim="#5d7478", rule="#cbd8d9", panel="#ffffff",
    ground="#f4f8f8", held="#0f766e", dark="#e3ebeb", warn="#b4341f",
    drone="#0f766e", accent="#0f766e", shadow="#dce6e6",
)
DARK = dict(
    ink="#e9f1f1", dim="#94a9ac", rule="#2b3c3e", panel="#16211f",
    ground="#0e1918", held="#2dd4bf", dark="#1c2b2a", warn="#f87171",
    drone="#2dd4bf", accent="#2dd4bf", shadow="#111c1b",
)


def drone(x: float, y: float, s: float, colour: str, opacity: float = 1.0) -> str:
    """A quadcopter, small enough to repeat and still read as one."""
    a = s * 0.62          # arm half-length
    r = s * 0.30          # rotor radius
    return f"""  <g transform="translate({x:.1f},{y:.1f})" opacity="{opacity}">
    <line x1="{-a:.1f}" y1="{-a:.1f}" x2="{a:.1f}" y2="{a:.1f}" stroke="{colour}" stroke-width="{s*0.13:.2f}" stroke-linecap="round"/>
    <line x1="{-a:.1f}" y1="{a:.1f}" x2="{a:.1f}" y2="{-a:.1f}" stroke="{colour}" stroke-width="{s*0.13:.2f}" stroke-linecap="round"/>
    <circle cx="{-a:.1f}" cy="{-a:.1f}" r="{r:.1f}" fill="none" stroke="{colour}" stroke-width="{s*0.10:.2f}"/>
    <circle cx="{a:.1f}" cy="{-a:.1f}" r="{r:.1f}" fill="none" stroke="{colour}" stroke-width="{s*0.10:.2f}"/>
    <circle cx="{-a:.1f}" cy="{a:.1f}" r="{r:.1f}" fill="none" stroke="{colour}" stroke-width="{s*0.10:.2f}"/>
    <circle cx="{a:.1f}" cy="{a:.1f}" r="{r:.1f}" fill="none" stroke="{colour}" stroke-width="{s*0.10:.2f}"/>
    <circle cx="0" cy="0" r="{s*0.26:.1f}" fill="{colour}"/>
  </g>"""


def figure(c: dict) -> str:
    out: list[str] = []
    add = out.append

    add(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" '
        f'font-family="ui-sans-serif, -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif">')
    add(f'  <rect width="{W}" height="{H}" rx="14" fill="{c["ground"]}"/>')

    # ── title ────────────────────────────────────────────────────────────
    add(f'  <text x="40" y="52" fill="{c["ink"]}" font-size="25" font-weight="650">'
        f'Every layer gated, then flown to find out</text>')
    add(f'  <text x="40" y="80" fill="{c["dim"]}" font-size="15">'
        f'Twelve drones over 25 km&#178;, authored layer by layer in a SysML-like dialect, gated at every step &#8212; and one estimate nobody had computed.</text>')

    # ── panel 1: the brief ───────────────────────────────────────────────
    px, py, pw, ph = 40, 108, 268, 322
    add(f'  <rect x="{px}" y="{py}" width="{pw}" height="{ph}" rx="11" fill="{c["panel"]}" stroke="{c["rule"]}"/>')
    add(f'  <text x="{px+20}" y="{py+34}" fill="{c["dim"]}" font-size="14" letter-spacing="1.3">THE BRIEF SETS</text>')
    # v7's own brief (examples/drone-swarm-v7/00-brief.md), the run this
    # figure reports. The current brief states a 20-minute swap and a
    # per-drone footprint; both arrived after v7 and belong to later runs.
    rows = [("12", "drones it can field"), ("25 km²", "area to keep watched"),
            ("40 / 60 min", "flight, then recharge"), ("≥ 0.9", "of the area, at any moment")]
    y = py + 76
    for value, label in rows:
        add(f'  <text x="{px+20}" y="{y}" fill="{c["ink"]}" font-size="19" font-weight="620">{value}</text>')
        add(f'  <text x="{px+20}" y="{y+19}" fill="{c["dim"]}" font-size="15">{label}</text>')
        y += 60

    # ── the layers, as a spine between brief and grid ────────────────────
    lx = px + pw + 34
    add(f'  <text x="{lx}" y="{py+34}" fill="{c["dim"]}" font-size="14" letter-spacing="1.3">AUTHORED</text>')
    for i, name in enumerate(["OA", "SA", "LA", "PA", "EPBS"]):
        by = py + 54 + i * 48
        add(f'  <rect x="{lx}" y="{by}" width="92" height="36" rx="8" fill="{c["panel"]}" stroke="{c["rule"]}"/>')
        add(f'  <text x="{lx+46}" y="{by+23}" fill="{c["ink"]}" font-size="14" font-weight="600" text-anchor="middle">{name}</text>')
        if i < 4:
            add(f'  <line x1="{lx+46}" y1="{by+36}" x2="{lx+46}" y2="{by+48}" stroke="{c["dim"]}" stroke-width="2"/>')
    add(f'  <text x="{lx+46}" y="{py+ph-6}" fill="{c["dim"]}" font-size="15" text-anchor="middle">every step gated</text>')

    # ── panel 2: the sector grid, as the duty cycle allows ──
    gx, gy = lx + 140, py
    gw, gh = 330, ph
    add(f'  <rect x="{gx}" y="{gy}" width="{gw}" height="{gh}" rx="11" fill="{c["panel"]}" stroke="{c["rule"]}"/>')
    add(f'  <text x="{gx+20}" y="{gy+34}" fill="{c["dim"]}" font-size="14" letter-spacing="1.3">WHAT THE DUTY CYCLE ALLOWS</text>')

    cols, rowsn = 4, 3
    cell, gap = 64, 10
    ox = gx + (gw - (cols * cell + (cols - 1) * gap)) / 2
    oy = gy + 56
    # The duty-cycle ceiling, drawn: not a frame of the flight.
    watched = {0, 3, 6, 9}
    # 4.8 of 12 is four tiles and four fifths of a fifth: drawn as a partly
    # filled tile, so a reader who counts the grid gets the printed 0.40.
    part = 11
    for i in range(cols * rowsn):
        cxp = ox + (i % cols) * (cell + gap)
        cyp = oy + (i // cols) * (cell + gap)
        held = i in watched
        add(f'  <rect x="{cxp:.1f}" y="{cyp:.1f}" width="{cell}" height="{cell}" rx="8" '
            f'fill="{c["held"] if held else c["dark"]}" opacity="{1 if held else 1}"/>')
        if held:
            add(drone(cxp + cell / 2, cyp + cell / 2, 22, c["panel"]))
        if i == part:
            add(f'  <clipPath id="part"><rect x="{cxp:.1f}" y="{cyp:.1f}" width="{cell}" '
                f'height="{cell}" rx="8"/></clipPath>')
            add(f'  <rect x="{cxp:.1f}" y="{cyp:.1f}" width="{0.8 * cell:.1f}" height="{cell}" '
                f'fill="{c["held"]}" clip-path="url(#part)"/>')
    add(f'  <text x="{gx+20}" y="{gy+gh-22}" fill="{c["dim"]}" font-size="14">'
        f'4.8 of 12 aloft on average: at most 0.40</text>')

    # ── panel 3: the claim against the ceiling ──────────────────────────
    rx = gx + gw + 34
    rw = W - rx - 40
    add(f'  <rect x="{rx}" y="{py}" width="{rw}" height="{ph}" rx="11" fill="{c["panel"]}" stroke="{c["rule"]}"/>')
    add(f'  <text x="{rx+20}" y="{py+34}" fill="{c["dim"]}" font-size="14" letter-spacing="1.3">AREA UNDER WATCH</text>')

    add(f'  <text x="{rx+20}" y="{py+82}" fill="{c["dim"]}" font-size="15">the architecture claimed</text>')
    add(f'  <text x="{rx+20}" y="{py+124}" fill="{c["ink"]}" font-size="40" font-weight="680">0.92</text>')
    add(f'  <text x="{rx+20}" y="{py+170}" fill="{c["dim"]}" font-size="15">one sector per drone: at most</text>')
    add(f'  <text x="{rx+20}" y="{py+212}" fill="{c["warn"]}" font-size="40" font-weight="680">0.40</text>')

    add(f'  <line x1="{rx+20}" y1="{py+234}" x2="{rx+rw-20}" y2="{py+234}" stroke="{c["rule"]}"/>')
    add(f'  <text x="{rx+20}" y="{py+258}" fill="{c["ink"]}" font-size="15" font-weight="620">'
        f'Every gate passed it</text>')
    for i, line in enumerate(["Simulating the model exposed it.",
                              "A gate now stops it."]):
        add(f'  <text x="{rx+20}" y="{py+280+i*20}" fill="{c["dim"]}" font-size="15">{line}</text>')

    # ── footer ───────────────────────────────────────────────────────────
    add(f'  <text x="40" y="{H-20}" fill="{c["dim"]}" font-size="15">'
        f'A SysML-like model &#183; every layer checked by Sysprose &#183; the physical layer flown in Gazebo with ArduPilot autopilots</text>')
    add('</svg>')
    return '\n'.join(out) + '\n'


def main() -> None:
    here = pathlib.Path(__file__).resolve().parent
    for name, palette in (("hero-light.svg", LIGHT), ("hero-dark.svg", DARK)):
        (here / name).write_text(figure(palette), encoding="utf-8")
        print(f"  {here / name}")


if __name__ == "__main__":
    main()
