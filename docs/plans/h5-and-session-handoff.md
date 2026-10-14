# Handoff — the forerunner aftermath: H1, the follow-up batches, and the six decisions (H5 still open)

Date: 2026-10-12. Author: the opencode/deepseek agent that continued an interrupted Claude session.
Repos: `~/sysprose` (`github.com/cosmindxu/sysprose`, the modeler) and the mbse-workflow pair —
`~/Work/mbse-workflow-public` (`cosmindxu/mbse-workflow`, deploys the model site) and
`~/Work/mbse-workflow` (`cosmindxu/mbse-workflow-private`).

This document is for the next agent. It records (1) what this session realized, (2) what is left, and
(3) every detail needed to **re-evaluate, assess and re-design H5**, which is the one substantive
change that was attempted and deliberately reverted. Read it with the two binding plans
`~/.claude/plans/behaviour-in-app.md` and `~/.claude/plans/per-instance-check.md`, and `~/sysprose/TODO.md`.

> **Corrections, 2026-10-14** (a review of this session's work at Sysprose `5943654`; the full findings and the plan
> that supersedes this document's "what is remaining" are in the review's `close-open-items.md`). The text below is
> kept as written, with each wrong claim marked where it stands. In short:
> - §2.6 item 2 ("parse *more*, never less") is **false**: the parse-free certificate vouches for text the CLI
>   rejects (guard, trigger, effect, expression and metadata text are never checked).
> - §3.1's "likely root cause" is **wrong**: `reachingAssert` never runs on the chain. The solver-units regression
>   is the `quantityScopeFor` block in `units-eval.ts`.
> - §3.2's heading contradicts its body, §2.6 lists five of the six decisions, and §3.3 lists `docs/TEST-SUMMARY`
>   drift as untouched although it shipped in `0ac35a4`.
> - The H5 decision quoted in §3.1 is recorded only here (it reached this session through a conversation); it
>   awaits the user's confirmation (plan decision U4), and `per-instance-check.md` still says the opposite.
> - This is an internal session log; whether it stays in the public repository is plan decision U12.

---

## 1. The starting point — the interruption

A previous Claude session was working through a multi-feature plan (behaviour verification in the app;
per-instance readings; a solver-optimization port; a palette/diagram UX batch) via the
`sysprose-feature-dev` workflow. It hit the **Claude weekly API limit** mid-step (`behaviour S2b:finish`),
leaving **four git worktrees with uncommitted work** under
`/tmp/claude-1000/.../scratchpad/wt-*`, and a scattered set of plans in `~/.claude/plans/`.

The session was also running an **orchestrator** whose state is worth knowing: each feature is a branch
(`behaviour`, `ux`, `speed2`, `per-instance`, `speed`) built by per-step agents that implement → run two
adversarial reviews → run a full gate → commit one checkpoint per step; **merge, push and publish stay
with the coordinator**. The interruption did not corrupt anything; it only stopped the next paid call.

---

## 2. What was realized in this session

Everything below is committed and pushed. `sysprose` `main` is `5943654`; the mbse public/private are
`2163813` / `974e26d`.

### 2.1 The interrupted work, committed first

The four worktrees were committed on their branches (`~/sysprose`) so nothing was lost:
`behaviour S2b: rtc-gap` (`7f21925`), `ux: branch review` (`2c387ed`), `speed2 S1` (`66704a8`),
and the `speed` reference branch (`601783c`, kept, never merged — it is the exploratory predecessor of
`speed2`).

### 2.2 The four features completed and merged

Driven with parallel agents (one per independent branch), each step typecheck/lint/targeted-green:

- **`behaviour`** S1–S7 — the palette Reachability/Behaviour rows, the Checks-tab report, the state-view
  marks, the witness stepper, docs. (`be03cd7 … a42d15f`, plus the E9/E10 E2E fix `d1914b3`.)
- **`speed2`** S1–S2 — the solver optimizations (sparse Jacobian, shared scope, z3 witness printing).
  (`66704a8`, `79f7350`.)
- **`per-instance`** F3–F9 — the instance index, reporting core, per-instance readings, app presentation,
  shared/usage-owned rows, per-usage defaults, docs. (`c889e96 … 40f1f30`.)
- **`ux`** S1–S5 + the branch review (`2c387ed`).

The four were merged into `sysprose` `main` with merge commits `d595138` (ux), `3ab826a` (behaviour),
`607e783` (speed2), `0817541` (per-instance). The behaviour/ux merge needed real conflict resolution;
the one design fork was:

> **ux moved `reach`/`check-behaviour` off-thread into a Web Worker; behaviour judges them against the
> app's `loadHealth`, and the worker message carried only the model.** Chosen resolution (**option A**):
> compute `loadHealth()` on the main thread in `Palette.onRun`, thread it through the worker message
> (`src/ui/panels/checks-runner.ts`) into the worker's ctx (`src/ui/checks-offthread.ts`), so an
> off-thread run reads the same health the page would. See the `Palette.tsx`/`checks-runner.ts`/
> `checks-offthread.ts` changes in merge `3ab826a`.

The full gate was run **once on the merged `main`** (not per step): unit/integration/campaign, `build`,
and Playwright. Two integrated tests had to be re-pointed to the CLI's reach wording (`7131598`), and the
docs were regenerated (`fd894f6`).

### 2.3 H1 — the engine fix (`0c9d2bd`)

The one engine change of the session; it closes the "run-to-completion gap" the whole behaviour feature
was built around.

- **The gap:** the profile says a fired transition is followed by trigger-less (completion) transitions
  before any event (`src/semantics/mc/profile.ts`, `run-to-completion`), but the walk
  (`exploreMachine`, `src/semantics/mc/explore.ts`) and the property search (`search`,
  `src/semantics/mc/patterns.ts`) offered **every trigger at every configuration**. Their existential
  answers (`fail`, `covered`, `no way out`, `choice`, an undecided guard) could therefore sit on a run the
  profile forbids.
- **The fix:** at a configuration where a completion transition is **enabled or undetermined** (fail
  closed), offer **only** the completion transition. Implemented in both `exploreMachine` and `search`
  (via `stepCandidates`).
- **The interim guard deleted:** `src/semantics/mc/rtc-gap.ts` (−323 lines) and everything built to read
  it — the `checks/walk-only` row, the `walk-only` reach mark, the NOT COUNTED chip, `data-walk-only`, the
  report note, the witness caveat. (The plan's step 2b existed only to work around the gap.)
- **Verdicts corrected:** `spurious` and `guardTransient` now read `issues` (their unreachable states and
  dead transitions become findings, not walk-only rows); `a15` cover reads `not-covered` (undecided) and
  `a15` absence reads `pass` (holds).
- **Consequence on the reference model (v9):** its reach gained **2 unreachable + 9 dead** findings
  (diagnostics 12 → 23); one behaviour row flipped (still `undecided`).

### 2.4 The behaviour S7 follow-ups (`0475db6`)

Three of five shipped; see §3.2 for the two left.
- **A nested `state def` is walked as its own machine** — `regionDescendants` stops every machine-scoped
  traversal at a nested `StateDefinition`; `stateMachinesIn` keeps a nested `StateDefinition` as a root.
- **Dead / undecided transitions are marked on the diagram's edges** (`reachMarks.edgeMarks`,
  `src/diagram/edges.tsx`, legend).
- **The README "no control" audit** — `orphans`/`obligations` now name `palette-check-run`.

### 2.5 The per-instance follow-ups (`3e3b0ff`)

The three **false-verdict defects** the F1/F2 reviews had pinned in `KNOWN_FALSE` are **fixed** on all
four surfaces (check, literal, numeric/SMT, obligations):
- **`held-redef`** — a held redefinition's fall-through to the redefined feature's default now counts as
  unsafe.
- **the implicit-end-copy `endValue` defect** (`FanS2`'s `#bind`, `G340`, `assert-min`) — `endValue` reads
  the whole redefinition closure, so an assert inherited from a general definition is seen.
- **`ref-W9`** — `subjectOf` resolves a `ref` feature to the feature its value names.

Plus two follow-ups: the frame cap is now **per binding** (`BindingEnds.overCap`); and the Problems tab
names the producer (`Diagnostic.producer`, `Problems (N check · M solve)`).

### 2.6 The decisions (`5943654`)

After the user answered six open questions (this list records five of them; the sixth was not written down):

1. **Catalogue the `checks/*` codes — done.** Added a `checks` `DiagnosticSource` + a `checks/*` family to
   the Agent Diagnostics Contract, an entry per code with a documented **no-range**, and a test pinning
   `CHECK_META_CODES` to the catalogue. (`e3f06ad`.)
2. **Cheaper raw-value signal — done (parse-free validation too).** `src/text/health.ts`
   (`serializeUserModelSignals`) gives `loadHealth` a serializer-side raw-value flag + a **reference
   certificate**. A clean text is now parsed **zero** times; the pinned rename case is flagged
   not-faithful and still parses for the exact count. It is a **conservative certificate** — it can only
   make `loadHealth` parse *more*, never less. (`679a5e5`.) **Correction:** this is false. The certificate
   checks references and `value` only; a guard `true )`, an effect `}`, a trigger `go now` or a value
   `2; attribute rate = 3` gives health 0 and Reachability `holds`, while the CLI rejects the saved text
   (exit 1). There was no differential test for the claim.
3. **`sysprose-evidence/2` — done.** A v2 schema with a version discriminator + an `instance` facet;
   `attachEvidence` upgrades a legacy `R in X` v1 record, so one reading is one live obligation and the
   requirement's facet is the min over readings. (`05e45a4`.)
4. **Own-row naming — kept declined** (plan §I).
5. **H5 (assert over default) — attempted, then reverted.** (`075b306` then `ab965c7`.) See §3.1.

Reproduction of the gate used throughout: `NODE_OPTIONS=--max-old-space-size=8192 npx vitest run` (the
755-model differential OOMs at the default heap in this container; CI has more RAM and passes without the
bump), then `npm run build` and `npx playwright test`. Doc figures are regenerated with
`npm run test:report && npm run report` plus the hand-written `CONFORMANCE.md`/`TEST-REPORT.md` totals.

---

## 3. What is remaining

### 3.1 H5 — "an asserted equation overrides a default" (the one big revert)

**The decision the user took:** a per-instance read under an enclosing assert reads the asserted value and
decides its rows; the `enclosing-assert` abstention stays only where the value is genuinely undecided.
Relatedly, **extend the per-instance frame walk to non-usage holders** (a `bind` at package level or
between two definition features — probe `w4`, and `h2p0`/`h2c0`, classes D/E).

**What the attempt implemented** (the `075b306` diff — study it, it is the starting point, not the answer):
- `definedName` in `src/semantics/defining-equation.ts` reads an asserted equation's **dotted** defined
  name (`assert constraint { p.x == 3.0 }`), not only a bare one.
- `assertOverridesDefault` (+ `changedByAssert`/`reachingAssert`) makes an asserted equation of an
  **enclosing** context stand over the feature's own `default`; `carrier`/`sameIn` read the value in the
  context it is read in.
- `endValue` reads an asserted definition **before** the value loop (so the assert wins).
- A **package-level / definition-feature `bind`** is matched to the usage's instance path
  (`featureAtPath` + `boundSourceIn`), so the value it carries is read per instance.
- `evaluate-model.ts` (`answerFor`, `valueDefinedByEquation`) and `units-eval.ts` carry the same rules.
- `test/integration/verification.differential.test.ts` moved ~15 rows to the corrected four-surface
  verdict (`R1::q1::tie`, `GA6::Q::qa`, `GA5B`, `GA7::Q::pl`, `R13`/`R13b`, `W4::c2`, `B1`, `B3`,
  `R8::p::d50`, `N2`, …).

**Why it was reverted (`ab965c7`):** it **regressed the solver**. Three `test/unit/semantics.solver-units`
cases fail — a 70-long **asserted chain** (`attribute x_i; assert constraint d_i { x_i == x_{i-1} + 1.0 }`,
`constraint chk { x70 <= 80.0 }`) stops solving: the check reads `unknown`. Bisected: reverting `075b306`
alone restores 131/131 green, so the regression is entirely H5.

**Correction (verified 2026-10-14): the paragraph below is wrong.** `reachingAssert` never runs on the chain.
The regression is the new block in `units-eval.ts` `quantityScopeFor` (~1440): it derives inside a constraint
body scope and for value-less features, so the x70 chain goes past `MAX_DERIVATION_DEPTH` and the result is
`unknown`. Dropping its `|| !hasStatedValue(...)` term gives solver-units 131/131, and the differential then stays
green apart from 8 I3 rows, each back at its HEAD value.

**The likely root cause (original text, WRONG — see the correction above):** `reachingAssert` walks from `contextId` up its owning
feature names and returns the first owner whose equations define `chain…​.name`. For the chain, the assert
`d_i` is owned by the **same** package the name is read in — a *local* assert — yet the walk can still
match it and re-route the reading through `defineIn(model, reaching.at, …)`, which the solver then cannot
resolve. The fix must **distinguish a local assert from an enclosing one**: only an assert owned by a
strict owner (through at least one usage hop) should be read this way, and never when the name is already
defined by a same-owner equation.

**The other H5 sub-items and their blockers (from the attempt's analysis):**
- **`h2p0`/`h2c0`** (`attribute :>> load = L`-style redefinitions reading the *enclosing definition's*
  `L`) are blocked by a **missing lexical outer-scope resolution** generally: the tool reads
  `package Lex { attribute K = 7.0; part def A { attribute x = K; } }` as `Lex::A::x` unknown. A narrower
  fix was tried and produced a **false** verdict on `S5::P::c` (the generic `Q::p` misread at `q1`'s 50),
  so it was reverted. A correct rule must handle an assert whose **right** side is the name
  (`assert { p.x == L }`) bidirectionally.
- **classes D/E** (`b4c`'s imposed `w == y+1`; `n4`–`n6`'s `x*x == -1`, `x³−2x == 2`, `x/(1+x²) == 0.4`;
  `s2-usage-assert-leak`'s inequality-only `v >= 5`) need a **nonlinear / implicit solver** or a
  modelling decision — H5 and the frame walk give them nothing.
- **Enclosing-assert *equality* reads** (`R1::top1`, `R1::P::c in q1::p`): the check and literal became
  `F`, but the numeric surface stayed `T` (it solves the default independently) and SMT stayed
  `inconsistent-axioms`, a **cross-surface clash**. Completing it needs `src/semantics/solver.ts` and
  `src/semantics/obligations.ts` to honour assert-over-default in an enclosing *instance* too — outside
  the files the first attempt touched.

**Design guidance for the re-do:** treat this as its own gated step on a branch (the session used
`todo-batch`/`decisions` branches off `main`), with the differential four-surface table as the acceptance
oracle. The key invariants to hold: (a) an assert overrides only a `default`, never a plain `=` value
(that stays the strict-KerML contradiction another guard reports); (b) a **local** assert is not an
enclosing one; (c) the solver and SMT must agree with the check and literal, or the row must abstain — a
clash is worse than an abstention. Add the solver/SMT sides **in the same step**, not after.

### 3.2 The two behaviour S7 items: both closed (nothing left to decide)

- **Catalogue the rest of the app rows** — done for `checks/*`; nothing further.
- **The cheaper raw-value signal** — done (parse-free). The only residual is the conservative
  certificate's coverage (references emitted from attributes other than `attrs.type`; parser recovery
  changing a raw value's parsed form), which is documented in `src/text/health.ts`.

(So §3.2 of behaviour S7 is effectively closed; the open items are the H5 ones in §3.1.)

### 3.3 The rest of `sysprose/TODO.md` (untouched by this session)

The full list is `~/sysprose/TODO.md`. Beyond the H5 family, the notable untouched items include: running
the palette's solver checks in-page (COOP/COEP vs Google Drive); scoping more checks to the selection;
`h2p0`… (`solver`, above); **stop a composite's last-active child from multiplying the walk's
configurations** (`hashConfig`); the z3-timeout-floor guard; register row W2's per-step producer;
inherited-contract-clause display; a batch of persistence/library-integration items (api-json round
trips, library-writer guards); the hub-led `OA` crossings; and tied centrality ranks. (`docs/TEST-SUMMARY`
drift as a CI step is **not** in this list: it shipped in `0ac35a4`.) Read the file; most are concrete and
independent. Note that 22 of its 47 items had already shipped and were still listed when this was written.

### 3.4 The recurring coordinator chores

- **Tutorial-stills review at each sysprose pin bump** — never actually done (the note has been "no
  at-rest changes"). Now more relevant after H1, since v9's displayed reach/behaviour verdicts changed.
- **The calibration cycle** for every new sysprose commit (see §4).
- **Google Drive** on the site is still unconfigured (needs a Google Cloud project; `site/drive.json`).

---

## 4. The calibration cycle (what to run for any new `sysprose` commit)

Both mbse-workflow repos, per new pinned commit (`0c9d2bd`, `735f915`, `5943654` are worked examples):

1. Public: set `SYSPROSE_REF` (`.github/workflows/deploy-pages.yml`) to the full commit and
   `config/workflow.yaml: expected_commit` to the short one; `npm run record-fixtures` + `npm test` (the
   corpus is live at `~/sysprose`; the reference model is the oracle, fix predicates, not the tool).
2. Public: re-run v9's audit — `npm run mbse-workflow -- resume --out examples/drone-swarm-v9
   --from-step S60 --unattended` (S60/S70 are `CHECK`/`AUDIT` — **no model calls**).
3. Private: mirror the pin commit (`git format-patch -1` → `git am`) and **re-run its own v9 audit** (it
   records the private repo's absolute paths, so a patch copy will not apply).
4. Push both. The public push redeploys the site; the sysprose push runs CI. (CI took ~28 min; the Pages
   deploy ~1–2 min.)

## 5. Key references

- Plans: `~/.claude/plans/behaviour-in-app.md`, `~/.claude/plans/per-instance-check.md`.
- Action files: `~/sysprose/TODO.md`, `ROADMAP.md`, `RESEARCH.md` (move items, don't copy).
- Project rules: `~/sysprose/CLAUDE.md` (claims guard, Agent Diagnostics Contract, doc-counts pins).
- The H5 attempt to re-read: `git -C ~/sysprose show 075b306` (implementation + differential) and
  `ab965c7` (the revert). The failing oracle: `test/unit/semantics.solver-units.test.ts` cases
  *"solves a chain of definitions nested past the cap"*, *"…with the check written above it (G6b)"*,
  *"…from a free check at its end"*.
- The four-surface acceptance table: `test/integration/verification.differential.test.ts`.

## 6. Process caveats this session carried (so you can weigh its evidence)

- Per-step commits were typecheck/lint/**targeted**-test green; the **full gate ran once per batch** on a
  merged branch, not at every step. Treat the batched merges as the validated unit.
- The local gate needs `NODE_OPTIONS=--max-old-space-size=8192` for the differential; CI does not.
- Long local runs must be launched **inside `tmux`** (a plain detached `&`/`setsid` process is killed when
  the tool call ends); the session's runners are in `/tmp/opencode/*.sh`.
