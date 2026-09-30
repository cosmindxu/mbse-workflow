# The model site

**https://cosmindxu.github.io/mbse-workflow/** opens the v9 drone-swarm model
in Sysprose. It is built and deployed by `.github/workflows/deploy-pages.yml`;
nothing on it is written by hand except `site/index.html`.

## What is deployed

```
/                          site/index.html — forwards to the app at once; its
                           body is what shows without JavaScript
/hero-light.svg  /hero-dark.svg
/app/                      the Sysprose app (its `dist/`), built at SYSPROSE_REF
/app/model/SurveillanceDroneSwarm.sysml
                           examples/drone-swarm-v9/SurveillanceDroneSwarm.sysml, as committed
/app/docs/LICENSES.html    from the Sysprose build: MIT, and EPL-2.0 for its standard-library data
```

The root forwards to

```
app/?model=model/SurveillanceDroneSwarm.sysml&source=<CONTRIBUTING.md#proposing-a-change-to-the-model>
```

`?model=` is Sysprose's own loader: it fetches the file, opens it as the
session's model, and shows a strip naming the file with a **Propose a change**
link to `?source=`. The path is relative, so the fetch is same-origin and needs
nothing from the app's content-security policy. Nothing is persisted: each visit
fetches the model again, so the site shows what is committed. Sysprose's own
site accepts the same link with an absolute URL on `raw.githubusercontent.com`:

```
https://cosmindxu.github.io/sysprose/?model=https://raw.githubusercontent.com/cosmindxu/mbse-workflow/main/examples/drone-swarm-v9/SurveillanceDroneSwarm.sysml
```

## When it rebuilds

On a push to `main` that touches the v9 model, `site/`, the hero figures or the
workflow — so a `resume` that re-derives the model republishes it — and on
demand from the Actions tab.

## Moving the Sysprose pin

`SYSPROSE_REF` in the workflow is a full commit of `cosmindxu/sysprose`. The
site changes only when that line does. To move it: pick the commit, check it
opens the model (`npm run build && npm run preview` in Sysprose, copy the model
to `dist/model/`, open `http://localhost:4173/?model=model/SurveillanceDroneSwarm.sysml`),
and change the one line.

This pin is separate from `sysprose.expected_commit` in `config/workflow.yaml`,
which records the commit the workflow's checks were calibrated against.

## Changes to the model

The site does not write anywhere. Edits in the browser stay in that browser;
changes reach the repository as commits and pull requests — see
[CONTRIBUTING.md](../CONTRIBUTING.md#proposing-a-change-to-the-model).
