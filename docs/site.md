# The model site

**https://cosmindxu.github.io/mbse-workflow/** opens the v9 drone-swarm model
in Sysprose. It is built and deployed by `.github/workflows/deploy-pages.yml`;
nothing on it is written by hand except the files in `site/` — the landing page,
the tutorials page, the privacy page and, once Google Drive is set up,
`drive.json` — and the tutorials' scenarios.

## What is deployed

```
/                          site/index.html — forwards to the app at once; its
                           body is what shows without JavaScript, or with `?stay`
/hero-light.svg  /hero-dark.svg
/app/                      the Sysprose app (its `dist/`), built at SYSPROSE_REF
/app/drive.json            site/drive.json when it exists (Google Drive on); else
                           the build's placeholder, which leaves Google Drive off
/app/model/SurveillanceDroneSwarm.sysml
                           examples/drone-swarm-v9/SurveillanceDroneSwarm.sysml, as committed
/app/docs/LICENSES.html    from the Sysprose build: MIT, and EPL-2.0 for its standard-library data
/tutorials/                site/tutorials.html, with the videos, subtitles and posters of
                           docs/tutorials/ — see its README for how they are recorded
/privacy/                  site/privacy.html — privacy and terms (`#terms`), for
                           students and for Google's consent screen
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

On a push to `main` that touches the v9 model, `site/`, the hero figures,
`docs/tutorials/` or the workflow — so a `resume` that re-derives the model republishes it — and on
demand from the Actions tab.

## Moving the Sysprose pin

`SYSPROSE_REF` in the workflow is a full commit of `cosmindxu/sysprose`. The
site changes only when that line does. To move it: pick the commit, check it
opens the model (`npm run build && npm run preview` in Sysprose, copy the model
to `dist/model/`, open `http://localhost:4173/?model=model/SurveillanceDroneSwarm.sysml`),
and change the one line. The tutorials show the app at the pin, so re-record
them from the new commit (`docs/tutorials/README.md`) when the screens they
show have changed.

This pin is separate from `sysprose.expected_commit` in `config/workflow.yaml`,
which records the commit the workflow's checks were calibrated against.

## Google Drive

Sysprose can open and save `.sysml` files in a student's own Google Drive
(**Drive ▾** on its toolbar; what a student sees is in Sysprose's
[user guide, §8.1](https://github.com/cosmindxu/sysprose/blob/main/docs/USER-GUIDE.md#81-google-drive-optional),
once the feature is on Sysprose's `main`).
It is off unless the deployed site supplies a `drive.json` next to the app.
From the commit that added the feature on, Sysprose's build ships a
placeholder there that names no client, so a site that does nothing has no
**Drive ▾** button and fetches nothing from Google. It needs a `SYSPROSE_REF`
at or after that commit.

**Not configured yet.** `site/drive.json` does not exist until the Google
Cloud project below has been created; until then the workflow keeps the
build's placeholder (`if [ -f site/drive.json ]`), and Google Drive is off on
the site. The current pin (`65dd95d`) also predates the feature, so turning it
on needs `SYSPROSE_REF` moved as well. `site/drive.json.example` shows the
shape, with three ids that are each deliberately invalid — copied as it is, the
app logs *drive.json is present but invalid* in the console and leaves the
feature off.

**To turn it on**: do the console steps below, then

```
cp site/drive.json.example site/drive.json
```

fill in the three ids, commit and push `site/drive.json` (a push under
`site/**` redeploys), and put the client ID on the privacy page
(`site/privacy.html`, `#client-id`) in the same commit. Then check the
privacy page against real Google (its step-10 comment lists what to confirm).

```json
{
  "clientId": "<the OAuth client ID>.apps.googleusercontent.com",
  "apiKey": "<the API key, AIza…>",
  "appId": "<the project number>",
  "privacyUrl": "https://cosmindxu.github.io/mbse-workflow/privacy/",
  "supportUrl": "https://github.com/cosmindxu/mbse-workflow/issues"
}
```

`clientId` and `privacyUrl` are required; `apiKey` and `appId` come together
or not at all (without them there is no **Browse Drive…**, Google's file
picker); `supportUrl` is optional. A file that is present but invalid leaves
the feature off and says why in the browser console.

**The ids are public by design.** The client ID travels with every sign-in
request and the API key and project number with every picker request, so
committing them hides nothing. What limits their use is set at Google: the
OAuth client admits only the origins listed below, and the API key is
restricted to the Google Picker API and to the site's address,
`https://docs.google.com/*` (the picker's own frame calls with it) and the
local preview. The only scope the app asks for is `drive.file` — the files a
student makes or chooses with the app.

**The Google Cloud console** (once, by the maintainer; nothing here is in the
repository):

1. Create a project. Its **project number** (dashboard → Project info) is
   `appId`.
2. APIs & Services → Library: enable the **Google Drive API** and the **Google
   Picker API**.
3. Google Auth Platform → **Branding**: app name `Sysprose`; a user support
   email; no logo (a logo brings Google's brand check); app home page
   `https://cosmindxu.github.io/mbse-workflow/?stay`; privacy policy
   `https://cosmindxu.github.io/mbse-workflow/privacy/`; terms of service
   `https://cosmindxu.github.io/mbse-workflow/privacy/#terms`; authorized
   domain `cosmindxu.github.io`; a developer contact email. Both pages must be
   live before this step, so the privacy page ships before `drive.json` does.
4. **Audience**: External; start in *Testing* with test users, then **Publish
   app** once the manual check has passed. `drive.file` is a non-sensitive
   scope, so there is no verification queue. While the project is in testing,
   any account not on the test-user list meets Google's *Access blocked* page.
5. **Data access**: add `https://www.googleapis.com/auth/drive.file`, nothing
   else.
6. **Clients** → Create → Web application; authorized JavaScript origins
   `https://cosmindxu.github.io`, `http://localhost:4173`, `http://localhost`;
   no redirect URIs. The client ID is `clientId`.
7. APIs & Services → Credentials → **API key**, restricted to websites
   `https://cosmindxu.github.io/*`, `https://docs.google.com/*`,
   `http://localhost:4173/*` and to the Google Picker API. The key is `apiKey`.

**The `?stay` homepage.** The site's root forwards to the app at once, and
Google wants an app's homepage to describe the app and link its privacy
policy rather than send the visitor elsewhere. With `?stay` in the address
(`/?stay`, `/?stay=1`, `/?x=y&stay` — not `/?staying`) the landing page does not
forward, and its footer links the privacy page. If the console refuses a query
string there, register `https://cosmindxu.github.io/mbse-workflow/tutorials/`
instead, which links the privacy page too.

**To rotate** a client ID or key: create the new one in the console, edit
`site/drive.json` (and the client ID on the privacy page), and push. The app
reads `drive.json` afresh on the next visit while online; an offline visit uses
the copy its service worker kept.

**To turn it off**: delete `site/drive.json` and push; the build's placeholder
comes back on the next deploy. Deleting the OAuth client in the console stops
new sign-ins, whatever the site serves.

**Schools.** A Google Workspace for Education account designated as under 18 is
blocked from third-party apps that its school has not allowed. The school's
administrator allows the app in the Admin console → Security → Access and data
control → API controls → Manage third-party app access → Add app → by OAuth
client ID, with *Limited* access (enough for `drive.file`). The privacy page
prints the client ID for them.

## Changes to the model

The site does not write anywhere. Edits in the browser stay in that browser —
or, with Google Drive on, in a file in the student's own Drive, which is theirs
and reaches no one else unless they share it; changes reach the repository as
commits and pull requests — see
[CONTRIBUTING.md](../CONTRIBUTING.md#proposing-a-change-to-the-model).
