# Contributing

## Looking at the model

**https://cosmindxu.github.io/mbse-workflow/** opens the drone-swarm model
(`examples/drone-swarm-v9/SurveillanceDroneSwarm.sysml`) in Sysprose, a browser
modeller. Every view — general, interconnection, action, state, requirement,
tree, the tables, 3D — is drawn from that one text file; the Explorer on the
left lists the layers as packages, top to bottom: `Kinds`, `Common`, `OA`, `SA`,
`LA`, `PA`, `EPBS`.

The [video tutorials](https://cosmindxu.github.io/mbse-workflow/tutorials/)
walk through every diagram, one layer at a time.

You can change anything in the browser. The changes live in that browser tab:
reloading the page fetches the published model again. **Save** keeps a copy in
the browser; **Export → SysML** downloads the file you changed.

## Proposing a change to the model

Changes reach the repository through GitHub, under its usual permissions:
collaborators push to a branch, everyone else forks and opens a pull request.

Edit the **fragment**, not the assembled model. `SurveillanceDroneSwarm.sysml`
and `build/` are regenerated from `fragments/`, so an edit to them is lost on
the next run. Each top-level package of the model is one fragment:

| Package in the model | Fragment in `examples/drone-swarm-v9/fragments/` |
|---|---|
| `Kinds` | `0_Kinds.sysml` |
| `Common` | `1_Common.sysml` |
| `OA` | `3_OA.sysml` |
| `SA` | `4_SA.sysml` |
| `LA` | `5_LA.sysml` |
| `PA` | `6_PA.sysml` |
| `EPBS` | `7_EPBS.sysml` |

`5_LA.alt-*` and `6_PA.alt-*` are the architectures that were compared and not
chosen; they are a record, not a place to edit.

1. Make the change in the browser if that is where you found it, then carry it
   into the fragment of the package it sits in — the text between that
   package's braces is the fragment's content. Or edit the fragment directly,
   on GitHub (the pencil on the file) or in a clone.
2. In a clone, check the layer you changed. This runs the same gate the
   workflow ran, and calls no language model:

   ```
   mbse-workflow check --out examples/drone-swarm-v9 --layer PA
   ```

   A `blocking` verdict means the step would stop there; the findings say why.
3. Open the pull request, and say which layer you changed and why.

A layer below the one you changed was written to realise the old version of
it, so merging your edit is not the end: a maintainer runs

```
mbse-workflow resume --out examples/drone-swarm-v9
```

which re-checks your layer — it is honoured, never re-authored — and
re-derives every layer below it, then commits the result. That step calls the
language model and costs money, so it is not expected of a contributor.

## Changing the workflow

Code changes are ordinary pull requests: `npm run typecheck` and `npm test`
must pass. Both need a Sysprose checkout at `~/sysprose` (or `$SYSPROSE_DIR`).
The checks were calibrated against the commit `config/workflow.yaml` pins; on
another commit they still run, with a note saying so.

## The site

The site is built by `.github/workflows/deploy-pages.yml` from a pinned Sysprose
commit and the v9 model; `docs/site.md` says how it fits together. It bundles
Sysprose (MIT) and its standard-library data (EPL-2.0) — the site's
[licences page](https://cosmindxu.github.io/mbse-workflow/app/docs/LICENSES.html)
lists them. Sysprose reads a SysML v2–style notation and is not a certified or
conformance-tested implementation.
