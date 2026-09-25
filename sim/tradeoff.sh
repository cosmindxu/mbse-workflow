#!/usr/bin/env bash
# Stage 2 — the architecture decision, run rather than argued.
#
# v7's trade-off was where coordination is decided. Alternative 1 puts the
# deciding calls on the ground and estimates that the watch holds 0.55 of the
# area when the ground link is lost; alternative 2 puts them on the drones and
# estimates 0.91. Both are claims in a document.
#
# This runs the same scenario twice, changing one thing — where the decision is
# made — and cutting the ground link at the same moment in both. Everything else
# is identical: the same generated world, the same fleet, the same timeline, the
# same measures. What comes out is two numbers where there were two claims.
#
#   sim/tradeoff.sh examples/drone-swarm-v7            # live
#   sim/tradeoff.sh examples/drone-swarm-v7 --offline  # in seconds
set -uo pipefail

RUN=${1:?usage: sim/tradeoff.sh <run directory> [--offline]}
shift || true
OFFLINE=""
[ "${1:-}" = "--offline" ] && OFFLINE="--offline"

INTO=${INTO:-sim/out/$(basename "$RUN")}
STAMP=$(date +%Y%m%dT%H%M%S)
CUT_AT=${CUT_AT:-300}
DURATION=${DURATION:-}
MEMBERS=${MEMBERS:-}
ARM_TIMEOUT=${ARM_TIMEOUT:-900}
IMAGE=${IMAGE:-mbse-sim:harmonic}

say() { printf '\n== %s ==\n' "$1"; }

say "generate once — both runs fly the same world"
npx tsx src/cli.ts simulate --out "$RUN" --into "$INTO" >/dev/null || exit 1

fly() {
  local where=$1 out="$INTO/tradeoff-$STAMP/$1"
  mkdir -p "$out"
  local flags="--run /sim/${INTO#sim/} --out /sim/${out#sim/} --coordination $where"
  flags="$flags --cut-ground-at $CUT_AT --arm-timeout $ARM_TIMEOUT $OFFLINE"
  [ -n "$MEMBERS" ] && flags="$flags --members $MEMBERS"
  [ -n "$DURATION" ] && flags="$flags --duration $DURATION"

  say "coordination decided $where, ground link cut at ${CUT_AT}s"
  if [ -n "$OFFLINE" ]; then
    python3 sim/runtime/run.py --run "$INTO" --out "$out" --coordination "$where" \
      --cut-ground-at "$CUT_AT" $OFFLINE \
      ${MEMBERS:+--members "$MEMBERS"} ${DURATION:+--duration "$DURATION"} | tail -6
  elif id -nG | tr ' ' '\n' | grep -qx docker; then
    docker run --rm -v "$PWD/sim:/sim" "$IMAGE" python3 -u /sim/runtime/run.py $flags | tail -6
  else
    sg docker -c "docker run --rm -v $PWD/sim:/sim $IMAGE python3 -u /sim/runtime/run.py $flags" | tail -6
  fi
}

fly onboard
fly ground

say "the trade-off, measured"
python3 - "$INTO/tradeoff-$STAMP" <<'PY'
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
rows = {}
for where in ("onboard", "ground"):
    path = root / where / "results.json"
    if not path.exists():
        print(f"  {where}: no result — the run did not finish")
        continue
    results = json.loads(path.read_text())
    rows[where] = {m["measure"]: m for m in results["measures"]}

names = {"areaUnderWatchShare": "watch, whole run",
         "groundLinkLossAreaUnderWatchShare": "watch after the link is cut"}
print()
print(f"  {'measure':32} {'decided on board':>18} {'decided on the ground':>22}")
for measure, label in names.items():
    on = rows.get("onboard", {}).get(measure, {}).get("simulated")
    gr = rows.get("ground", {}).get(measure, {}).get("simulated")
    fmt = lambda v: f"{v:.4f}" if isinstance(v, (int, float)) else "—"
    print(f"  {label:32} {fmt(on):>18} {fmt(gr):>22}")
print()
print(f"  runs: {root}")
PY
