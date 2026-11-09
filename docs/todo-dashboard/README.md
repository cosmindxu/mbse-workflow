# Open-items dashboard for Sysprose's TODO.md

The dashboard (a claude.ai Artifact, not hosted here) charts how Sysprose's `TODO.md` evolves along `main`'s first-parent history: open items by severity (FALSE, WEAKER, POLISH, HELD), items found, closed and narrowed per merge, and the entries open now with their class, SysML v2 view and origin.

This folder holds what generates it, so it survives the working directory it was built in.

| File | Role |
|---|---|
| `refresh.py` | Entry point: re-extracts when `TODO.md`'s head moved; `--force` always; `--commit k=url ...` records uploaded blob URLs. |
| `entries.py` | Walks `TODO.md` history, pairs entries across rewrites, writes `entries.json` and `counts.json` (regenerated, not kept). |
| `series2.py` | Applies the audit corrections and joins severity classes (`classified.json`, `labels_extra.json`, `label_overrides.json`, `corrections_extra.json`); writes `timeline.json`, `entries_final.json`. |
| `datasets.py` | Builds the four `ds_*.json` datasets the page reads (adds `classes.json`, `views.json`, `origin_extra.json`). |
| `ds_*.json` | The current datasets (timeline, windows, origin, open) as of Sysprose `b700e85`. |
| `index.html` | The page source. |

Run from this folder with Sysprose checked out at `/home/xcos/sysprose` (the path is set in `entries.py` and `refresh.py`): `python3 refresh.py --force`.

Notes:
- A keyword rule labels entries no pass has classified; those ids are reported as `provisional_ids`. `label_overrides.json` corrects them.
- `origin.json` (the origin classification) was lost; the origin dataset keeps its previous rows until it is regenerated.
- A severity of FALSE means a known wrong answer. A rollup of abstentions is WEAKER.
