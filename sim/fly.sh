#!/usr/bin/env bash
# WP6 — from model to flight, in one command.
#
# Generate the simulation from a finished run, materialise the vehicles, start
# the world and the autopilots, fly the scenario, and leave a report and a
# replay behind. Everything it does is one of the steps below, so any of them
# can still be run alone.
#
#   sim/fly.sh examples/drone-swarm-v7                 # the whole thing, live
#   sim/fly.sh examples/drone-swarm-v7 --offline       # no Gazebo, seconds
#   MEMBERS=4 DURATION=300 sim/fly.sh <run>            # a smaller, shorter run
#
# The generation half runs on the host, because that is where the model and
# Sysprose are. The flying half runs in the image, because that is where Gazebo
# and the autopilots are. That split is not a preference: the stock airframe
# exists only inside the image, and the model exists only outside it.
set -uo pipefail

RUN=${1:?usage: sim/fly.sh <run directory> [--offline]}
shift || true
OFFLINE=""
[ "${1:-}" = "--offline" ] && OFFLINE="--offline"

INTO=${INTO:-sim/out/$(basename "$RUN")}
OUT=${OUT:-$INTO/run-$(date +%Y%m%dT%H%M%S)}
MEMBERS=${MEMBERS:-}
DURATION=${DURATION:-}
ARM_TIMEOUT=${ARM_TIMEOUT:-900}
IMAGE=${IMAGE:-mbse-sim:harmonic}

say() { printf '\n== %s ==\n' "$1"; }

say "generate the simulation from the model"
npx tsx src/cli.ts simulate --out "$RUN" --into "$INTO" || exit 1

FLAGS="--run /sim/${INTO#sim/} --out /sim/${OUT#sim/} --arm-timeout $ARM_TIMEOUT $OFFLINE"
[ -n "$MEMBERS" ] && FLAGS="$FLAGS --members $MEMBERS"
[ -n "$DURATION" ] && FLAGS="$FLAGS --duration $DURATION"

if [ -n "$OFFLINE" ]; then
  say "fly it offline — no Gazebo, no autopilots"
  # Offline needs nothing from the image, so it runs here and takes seconds.
  python3 sim/runtime/run.py --run "$INTO" --out "$OUT" $OFFLINE \
    ${MEMBERS:+--members "$MEMBERS"} ${DURATION:+--duration "$DURATION"}
  STATUS=$?
else
  say "fly it: Gazebo, one autopilot per member, the scenario's own timeline"
  # Docker needs the group. A shell that predates `usermod -aG docker` reaches
  # the daemon through `sg docker`, which is why this is not a bare `docker`.
  if id -nG | tr ' ' '\n' | grep -qx docker; then
    docker run --rm -v "$PWD/sim:/sim" "$IMAGE" python3 -u /sim/runtime/run.py $FLAGS
  else
    sg docker -c "docker run --rm -v $PWD/sim:/sim $IMAGE python3 -u /sim/runtime/run.py $FLAGS"
  fi
  STATUS=$?
fi

say "what it left"
if [ -f "$OUT/README.md" ]; then
  ls -1 "$OUT" | sed 's/^/  /'
  echo
  sed -n '/^## Claimed against simulated/,/^$/p;/^| `/p' "$OUT/README.md" | head -12
  echo
  echo "  report: $OUT/README.md"
  echo "  replay: $OUT/replay.html"
else
  echo "  no report: the run did not get far enough to have one."
  echo "  $OUT"
fi
exit "$STATUS"
