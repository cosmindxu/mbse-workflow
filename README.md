# mbse-workflow

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/diagram/hero-dark.svg">
  <img alt="Twelve sectors over a twenty-five square kilometre area, four and four-fifths of them lit: what the brief's duty cycle allows, 4.8 of 12 drones aloft on average. The brief for this run fixes twelve drones, 25 km², about 40 minutes of flight then 60 of recharge, and asks for at least 0.9 of the area under watch at any moment. LLM agents wrote a SysML-like model layer by layer, and a deterministic checker gated every layer. The architecture claimed 0.92 of the area under watch; at one sector per drone, the brief's numbers allow at most 0.40. Every gate passed the claim; simulating the model exposed it, and a gate now stops it." src="docs/diagram/hero-light.svg">
</picture>

An LLM-agent workflow that authors a **layered, SysML-like model** and gates
every step on a **Sysprose** check.

The numbers in the picture come out of `examples/drone-swarm-v7` and its brief;
the sector grid draws the ceiling that brief's duty cycle sets, not a frame of
the flight. The 0.92 passed every check the model had, because none compared it
with the duty cycle. Turning the model into a simulation exposed it:
[the forerunner](docs/plans/swarm-3d-forerunner.md) records how, and a gate it
produced now stops it.

<p align="center">
  <a href="docs/media/drone-swarm.mp4"><img src="docs/media/drone-swarm.gif" width="600" alt="A 36-second clip, from idea to simulation. A person writes the brief in plain English; AI agents write the model layer by layer, a deterministic checker gating each layer; a deterministic generator builds the 3D simulation; building it exposes an estimate of 0.92 of the area watched where the brief allows at most 0.40, at one sector per drone. A gate now stops it."></a>
  <br>
  <sub>From idea to simulation, in 36 seconds. Click for the full-quality video. The drone footage is a test flight shot for the clip, not the generated simulation.</sub>
</p>

The layers follow a well-established layered MBSE method, chosen because its
layer transitions are mechanical enough to be a script: what one layer owes the
next is carried by code, and the agents enrich it rather than invent it.

```
mbse-workflow run --brief briefs/drone-swarm.md --out runs/drone --mode autonomous
```

produces `runs/drone/<System>.sysml` — one file, one model, checked — plus an
audit packet for every step.

## What it actually does

```
SEED ─ brief → mission, function sentence, measures, package Common
  │
  ├─ (optional) requirement intake, infrastructure intake
  │
  OA ── author ──► check ──► repair ──┐
  │                                   │  every check is a Sysprose command
  ├─ T-01 generate SA from OA         │  plus a post-condition scoped to the
  SA ── author ──► check ──► repair ──┤  layer being written; blocking findings
  │                                   │  go back to the agent, bounded
  ├─ T-02 generate LA from SA         │
  LA ── functions ─► 2 architectures ─► score ─► choose ─► write the trade-off in
  │                                   │
  ├─ T-03 generate PA from LA         │
  PA ── 2 architectures ─► score ─► choose
  │
  EPBS ── configuration items
  │
  verification (bonus, never blocks) ──► final audit
```

The layer activities decide the **order** of the steps and what each one is
**checked against**. Nothing here role-plays an engineer.

## The two things that make it more than a prompt chain

**Every step is gated on a real check.** A step's post-condition is a Sysprose
command *and* a predicate scoped to the layer being written — `trace --relation
allocate` exits 0 on a layer where nothing is allocated, so the command alone
gates nothing. The predicates are calibrated against a hand-written, validated
model: every one of them clears it, so a finding is about the model under
construction and not about this project's taste.

**What the model writes is composed, not pasted.** `src/model/statements.ts`
reads a fragment as the declarations it makes, so an answer is deduplicated by
declared name against what the scope already holds, Common additions are
flattened and hoisted, a placeholder component is stripped with every statement
that names it, and brace walks skip comments and strings. Each guard was written
after a live run paid for its absence, and the raw answer that caused it is the
regression fixture.

**The transitions are scripts, not prompts.** `T-01..T-04` read the layer above
and emit the next one with every realization link already written — an activity
becomes a function, an interaction becomes a flow, an entity becomes an actor.
The agent that follows enriches; it never invents the carry-over. All four
generated layers load clean inside their real prefix, and that is a test.

## Layout of a run

```
runs/drone/
  00-brief.md            what SEED settled: mission, environment, capabilities, measures
  brief.json             the same, machine-readable
  fragments/             one file per layer — what an agent writes, what a person edits
    0_Kinds.sysml  1_Common.sysml  3_OA.sysml  4_SA.sysml  5_LA.sysml  6_PA.sysml  7_EPBS.sysml
    5_LA.alt-1.sysml  5_LA.alt-2.sysml        the architectures that were compared
  build/                 assembled models, one per layer — derived, never edited
  audit/<step>/          verdict.json, one payload per check, fragment.diff, rationale.md,
                         and the model's raw answers (*.raw-section.*.txt, *.repair-N.raw.txt)
  audit/<step>/alt-<k>/  the same, per architecture compared
  audit/final/           the closure table, the coverage, the reviewability measures, the CLI witness
  gates/                 gate requests and the decisions people made
  state.json             where the run got to; what a resume reads
  <System>.sysml         the model
```

Sysprose is one file, one model — no imports, no workspace. References between
layers point upward only, which is what makes "layers 0..n" a valid model on its own:
that is the file each step is checked against, and it is why a per-layer
authoring prompt is possible at all.

## Humans in the loop

The same run is autonomous or reviewed depending on which gates are armed —
there is no second workflow for "with a person in it".

| Mode | Gates | Use |
|---|---|---|
| `autonomous` | seed, final | produce it, audit it afterwards |
| `gated` | seed, both architecture choices, final | a person picks the architecture |
| `reviewed` | every layer | a person reads each layer |
| `contributor` | as `gated`, plus fragment edits | a person writes parts of it |

A step that cannot be repaired **stops the run**, and opens its gate first when
it has one — S00, S10, S21, S33, S42, S50 and S70 do; the transitions and the
two alternatives steps do not. Either way the run does not continue: approving
the gate of a blocked step records the decision and stops, because the next
layer would be derived from a layer the checks refused. The way on is to edit
the fragment and `resume`, which re-checks that layer and re-derives the ones
below it.

A reviewer's comment is written into the model as a `#prompt` element, so the
author that runs again reads it, and the audit keeps it. Two steps rewrite the
very file it lands in — SEED rewrites `Common`, and EVALUATE copies the chosen
alternative over the layer — so the comment is also kept in `state.json` and
put into those two prompts by name. A rejection at G-LA or G-PA still re-scores
the same two alternatives: it cannot ask for a third, and it cannot pick the
other one, because the weighted score chooses.

**A person's edit is honoured, not rewritten.** Every step records the hash of
each fragment it was checked against. On `resume`, the first layer whose
fragment changed on disk is **re-checked** — never re-authored, which would hand
the edit back to the model — and repaired only as far as the checker demands;
every later layer is invalidated and re-derived, because it was written to
realise a version of the edited one that no longer exists. Granularity is the
layer: the state file keeps hashes, not copies.

**The model has to be readable by the person who did not write it.** Every
layer must document at least `limits.doc_coverage_min` (0.8) of its elements or
the step blocks; the final audit reports doc coverage per layer, the elements no
doc or trace explains, and the review surface — the lines a reviewer had to
read at each step, counted from the packet's diff.

```
mbse-workflow gate --out runs/drone --gate G-LA --approve
mbse-workflow gate --out runs/drone --gate G-LA --reject "split the coordination component"
```

## Commands

| | |
|---|---|
| `run --brief <file> --out <dir>` | start a run |
| `resume --out <dir>` | continue where it stopped |
| `status --out <dir>` | what each step did, and what it cost |
| `gate --out <dir> --gate <G> --approve\|--reject "<why>"` | answer a gate |
| `check --out <dir> --layer LA` | re-run a layer's checks against what is on disk |

Useful flags: `--mode`, `--unattended`, `--llm fake`, `--model`, `--budget-usd`,
`--from-step`, `--requirements <file>`, `--infrastructure <file>`.

## What it runs on

- **Node 22**, TypeScript through `tsx`, no build step.
- **Sysprose** at `~/sysprose` (or `$SYSPROSE_DIR`), driven **in process** — one
  standard-library parse per process, ~170 ms per model load against ~3 s for a
  CLI spawn. The published payloads are reproduced exactly, so anything in a
  packet can be re-derived with the CLI; the final audit does exactly that, as
  an independent witness.
- **`claude` CLI in headless mode** for the agents: one prompt, one structured
  answer, no tools, no second turn. (`--bare` is *not* used: it answers "Not
  logged in" headless.)
- One Sysprose process at a time on this host — the checks are serialised behind
  a lock. Model calls are not.

## Settings

`config/workflow.yaml` holds the knobs, the limits and the model choices. The
knobs are the ones the decision record fixed:

| Knob | Default | What it turns on |
|---|---|---|
| `modes_states` | on | states must be reachable, from SA down |
| `interfaces` | on | ports and connections are checked |
| `variability` | on | design options are tagged `#Variant` |
| `safety` | on | every layer states the hazards it adds as `#Hazard` requirements — a hazard stated above is satisfied by its path, never restated — and from SA down every hazard stated so far is satisfied by what mitigates it or tagged `#Accepted` with its reason |
| `views` | off | `expose` does not exist in this dialect; the packet replaces views |
| `verification` | on | the solver lanes run and report, and never block |
| `requirements_intake` | off | on when the customer supplies requirements |
| `infrastructure_intake` | off | on for a brownfield customer |

**Populations.** When the brief describes several identical members that
interact — a swarm, a fleet — SEED records a `population` and the coordination
and command-and-control functions it names, and the whole run is held to it with
no knob to turn: OA shows at least two representatives exchanging (`oa.members`);
OA names the brief's functions as tagged action definitions (`oa.namedFunctions`), and
T-01 merges what the members each perform into one system function of that name; SA
carries them tagged `#Coordination`/`#C2`, counted by definition from there down; LA and PA
instantiate CV-16 — one `#Member part def`, `part fleet : M [N]`, two
representatives and a peer interface between them (`replicas.memberPair`);
alternative 1 is built ground-centric and alternative 2 distributed
(`alt.c2Placement`), and the trade-off scores what each keeps doing when the
ground link drops and when the ground node fails. The final audit has a
`## The fleet` table. Every one of these is silent for a brief without a
population.

**Measures.** Each measure of effectiveness is a `#MoE attribute` in Common with
a `require constraint` holding it to its target. Every architecture states what it
achieves as `#Estimate attribute <measure> :> Common::<measure> = <worst case>`, with
its basis in the doc (CV-17, gated by `moe.estimated`). The evaluator bounds each
alternative's own estimate for its worst case and scores 1 per target met, 0 per
miss, ½ when undecided; the reports are kept in `audit/<step>/alt-<k>/`, and the final
audit has a `## Measures` table. The estimates are the architectures' own claims, so
the evaluating model is shown both bases side by side to challenge them.

**What the brief fixes by name.** A brief can name hazards it already knows, the
operating modes of its members, the fields its items carry, and rules the system
never breaks. SEED extracts each, and nothing is invented where the brief is
silent. The run is then held to them, every gate silent without them:
- each hazard is stated at SA under that name (`hazards.fromBrief`);
- each mode is a state of its owner's machine (`modes.fromBrief`);
- each item is an `item def` in Common with those attributes (`common.itemFields`);
- each rule (CV-18) is a `#Rule requirement` at SA and a checked property on the
  owner's state machine from SA down (`rules.carried`).

A rule is one of three kinds a model checker decides — wins until, preceded by, can
always return. It is written as a `@SysproseVerification::PropertyPattern` whose doc
names the rule. A rule some run breaks blocks the step with that run (`rules.hold`).
A number the brief fixes rather than asks the design to achieve (the fleet it can
field) is a `budget`: held by its requirement, never estimated or scored.

The **step table is not a setting**: a step's checks and post-conditions are the
workflow itself and live in `src/spec/steps.ts`, drift-tested against the design.

## Examples

`examples/` holds complete runs, kept under version control as they were
produced — fragments, every audit packet, the raw model answers, the final
model and the CLI witness — so a reader can follow one from brief to model
without re-running it.

| Run | Brief | Result |
|---|---|---|
| `examples/drone-swarm-v7/` | `briefs/drone-swarm.md` (sensing, links, oversight, 8 known hazards, 5 modes, 4 rules), from SEED | the brief's hazards, modes, rules and items carried by name from SEED to PA (2026-09-17); every carried rule holds on the model checker, 20 of 20 machines; 14 scored measures decided at both layers; trade-offs 0.67 vs 0.90 (LA) and 0.75 vs 0.88 (PA), distributed chosen; CLI-clean, 30/32 requirements with the 2 open accepted hazards; 40.43 USD over 21 calls |

| `examples/drone-swarm-v8/` | `briefs/drone-swarm.md` after the findings below (a cruise speed, what one drone keeps under watch, a 20-minute battery swap rather than a 60-minute charge), from SEED | the first run whose coverage estimate is arithmetic the brief supports rather than a literal nobody could check (2026-09-18); 32 calls, 21.45 USD |

| `examples/drone-swarm-v9/` | `briefs/drone-swarm.md`, from SEED | the first run with all four gates armed from the start, and the first whose trade-offs were real comparisons — two viable alternatives at both layers (2026-09-19); 21 calls, 10.82 USD |

**Three are kept, and they say different things.** v7 is the run the findings came
from — its `areaUnderWatchShare = 0.92` is what the brief's duty cycle rules
out at one sector per drone (at most 0.40, and every simulated run fell far short of 0.92), and what
`moe.dutyCycleBound` now blocks. It is read directly by
`test/integration/simulation-v7.test.ts`, which proves T-05 against a model a
run actually produced. **v7 does not pass today's gates, and that is the point
of keeping it.** v8 is the run that fixed the brief: same brief with the two
facts v7 was missing, and it clears both estimate gates — but only one
alternative survived at each layer, so neither of its trade-offs was a
comparison, which is what prompted the fourth gate.

v9 is the current reference. Every gate was armed before it started rather than
replayed afterwards, and both alternatives survived at both layers, so the
comparison gates had something to act on. They did: **ten of its LA measures and
six of its PA measures scored both alternatives identically.** At LA the measures
dimension — the largest single input to the decision, weighted 0.40 — read 0.29
for both alternatives and discriminated nothing at all; the choice was made
entirely on review, structure and resilience. That table would previously have
read as a considered comparison across four dimensions.

The earlier runs, v1 to v6, are not part of this repository; `examples/` holds
v7, v8 and v9.

A run's `audit/final/README.md` is the place to start reading.

## Tests

```
npm run record-fixtures   # once: rebuild the fixtures from the local study corpus
npm test                  # unit + integration, no model calls
npm run typecheck
```

The reference model and the payloads recorded from it come from a study corpus
that **stays local** and is never committed here. Every test that needs it skips
itself when it is absent; `MBSE_APPROACHES_DIR` says where it is.

`test:live` makes one real model call and is opt-in (`MBSE_LIVE=1`).

When a step fails in a live run, the raw answer is in
`audit/<step>/*.raw-section.*.txt` (or `*.repair-N.raw.txt`): recompose it
offline and read Sysprose's verdict on the exact text before theorising.

## Honest limits

- Two commands the design lists need an argument the step table cannot give:
  `bounds` needs `--measure`, so the evaluation step runs it per measure per
  alternative, on the alternative's own `#Estimate`; `check-behaviour` needs
  `--element`, so the bonus step sweeps every state machine — its own properties,
  or, for a machine written to come back to the state it opens at, that every
  reachable configuration can get back there.
- A measure is decided over what an architecture states, not over a computation:
  the estimate is a claim with a documented basis, checked for consistency by the
  solver. Until 2026-09-16 the measures term was a constant 0.5 in every trade-off
  (the evaluator read a field `bounds` does not emit), so no example before v5 was
  decided on its measures.
- The dialect has no `expose`, no `allocation def`, no time triggers, no guarded
  successions; `variation`/`variant` parse but carry no meaning. The house rules
  in `src/spec/conventions.ts` say what to write instead, and every one of them
  was measured rather than assumed.
- The reference model clears every gate but one: it is a thin thread and never
  implements two of its logical functions. That is asserted by name in the tests
  rather than allowed for.
- This project writes **spec-shaped** model text — written from the published
  specification. It is not a conformance claim, and neither is Sysprose's.
