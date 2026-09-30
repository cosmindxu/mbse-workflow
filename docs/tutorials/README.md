# Tutorials

Seven silent, subtitled videos — one per layer of the drone-swarm model — on
how to read and edit its diagrams in Sysprose. They are published at
**https://cosmindxu.github.io/mbse-workflow/tutorials/**.

| # | Video | What it covers |
|---|---|---|
| 1 | `1-start-here.mp4` | Opening the model from its link; the Explorer, the views, scoping a diagram to one layer, moving a box and Auto-layout, the whole-model views |
| 2 | `2-foundations.mp4` | Kinds (the model's keywords) and Common (what every layer shares) |
| 3 | `3-oa.mp4` | OA — operational analysis |
| 4 | `4-sa.mp4` | SA — system analysis |
| 5 | `5-la.mp4` | LA — logical architecture |
| 6 | `6-pa.mp4` | PA — physical architecture |
| 7 | `7-epbs.mp4` | EPBS — end-product breakdown |

Each video goes through every diagram that has content at its layer, one caption
per step, and shows one edit: an element deleted before recording is added back
on camera — placed from the palette, named and typed in Properties, connected
with a palette tool — so the diagram ends as it started. A caption says when something is not
re-entered. Captions sit in a band below the app, so they never cover it; the
same text ships as WebVTT (`N-*.vtt`) for players that show subtitles.

## How they are made

Nothing is edited by hand. Each video is recorded from a scenario in
`scenarios/` by Sysprose's recorder, which drives a running build of the app
with a visible pointer, on elements named by qualified name, and fails if a
target is missing rather than clicking air:

```
# in a Sysprose checkout, with the model next to the build:
npm run build && mkdir -p dist/model && cp <this repo>/examples/drone-swarm-v9/SurveillanceDroneSwarm.sysml dist/model/
npm run preview &
node scripts/record-tutorial.mjs --scenario <this repo>/docs/tutorials/scenarios/4-sa.json \
  --app http://localhost:4173/ --out <this repo>/docs/tutorials
```

It needs Playwright's Chromium and `ffmpeg` built with libass. Then

```
python3 docs/tutorials/make-page.py
```

rewrites `site/tutorials.html` from the scenarios and the videos' real
durations. Record with the Sysprose commit the site is built from
(`SYSPROSE_REF` in `.github/workflows/deploy-pages.yml`), so the videos show
the app visitors get.
