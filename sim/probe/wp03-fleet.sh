#!/usr/bin/env bash
# WP0.3 — what does a fleet cost, and at which physics step?
#
# One run is one cell of a table: N vehicles at a given `max_step_size`, flown
# together, with the real-time factor measured over a window in which the whole
# fleet is airborne, and the CPU split between the physics server and the
# autopilots. Run it for several N to get a curve rather than a point.
#
#   sg docker -c 'docker run --rm --device /dev/dri -v <repo>/sim:/sim \
#     mbse-sim:harmonic /sim/probe/wp03-fleet.sh 12 0.001'
#
# The fleet size is a brief budget. This probe decides the *step size*, never
# the number of vehicles.
set -uo pipefail

COUNT=${1:-12}
STEP=${2:-0.001}
ALTITUDE=${ALTITUDE:-20}
WINDOW=${WINDOW:-45}
CAMERA=${CAMERA:-}
OUT=${OUT:-/sim/out/wp03/n${COUNT}-step${STEP}${CAMERA:+-cam$CAMERA}}

mkdir -p "$OUT"
say() { printf '\n== %s ==\n' "$1"; }
# Everything below /sim is the user's working tree, mounted in. The container
# runs as root, so without this every generated file needs sudo to remove.
give_back() { [ -d /sim/out ] && chown -R "$(stat -c %u:%g /sim)" /sim/out 2>/dev/null; }
cleanup() {
  [ -n "${STATS:-}" ] && kill "$STATS" 2>/dev/null
  for pid in ${SITLS:-}; do kill "$pid" 2>/dev/null; done
  [ -n "${GZ:-}" ] && kill "$GZ" 2>/dev/null
  give_back
}
trap cleanup EXIT

say "the world: $COUNT vehicles, ${STEP}s step"
python3 /sim/probe/fleet_world.py --count "$COUNT" --step "$STEP" --out "$OUT" \
  ${CAMERA:+--camera "$CAMERA"} | tee "$OUT/world.txt" || exit 1
export GZ_SIM_RESOURCE_PATH="$OUT/models:${GZ_SIM_RESOURCE_PATH:-}"

say "gazebo"
# With no camera the server has nothing to draw and the measurement is the
# fleet alone; with one, --headless-rendering puts the render on the GPU
# through EGL and the measurement includes it. Both are wanted, separately.
if [ -n "$CAMERA" ]; then
  gz sim -s -r --headless-rendering -v 3 "$OUT/fleet.sdf" > "$OUT/gz.log" 2>&1 &
else
  gz sim -s -r -v 3 "$OUT/fleet.sdf" > "$OUT/gz.log" 2>&1 &
fi
GZ=$!
for _ in $(seq 1 90); do
  gz topic -l 2>/dev/null | grep -q '^/world/fleet/stats$' && break
  sleep 1
done
if ! gz topic -l 2>/dev/null | grep -q '^/world/fleet/stats$'; then
  echo "gazebo never came up:"; tail -20 "$OUT/gz.log"; exit 1
fi

say "autopilots"
# Launched directly rather than through sim_vehicle.py: twelve of those all
# funnel through run_in_terminal_window.sh and share one log path. `-I n`
# offsets both the MAVLink port (5760+10n) and the JSON backend port
# (9002+10n), which is what the generated models were given.
SITLS=""
for n in $(seq 0 $((COUNT - 1))); do
  instance_dir="$OUT/sitl/$n"
  mkdir -p "$instance_dir"
  ( cd "$instance_dir" && exec /opt/ardupilot/build/sitl/bin/arducopter \
      --model JSON --speedup 1 --slave 0 \
      --defaults /opt/ardupilot/Tools/autotest/default_params/copter.parm,/opt/ardupilot/Tools/autotest/default_params/gazebo-iris.parm \
      --sim-address=127.0.0.1 -I"$n" ) > "$instance_dir/sitl.log" 2>&1 &
  SITLS="$SITLS $!"
done
echo "started $COUNT autopilot(s)"

say "flying the fleet"
gz topic -e -t /world/fleet/stats > "$OUT/stats-all.txt" 2>/dev/null &
STATS=$!
python3 /sim/probe/fleet_fly.py --count "$COUNT" --altitude "$ALTITUDE" \
  --hold "$WINDOW" > "$OUT/fly.txt" 2>&1 &
FLY=$!

# The measurement window opens only once the fleet is up: a factor that
# includes twelve EKFs settling and twelve climbs is not the factor a scenario
# would run at.
for _ in $(seq 1 400); do
  grep -q '^FLEET_READY' "$OUT/fly.txt" 2>/dev/null && break
  kill -0 $FLY 2>/dev/null || break
  sleep 1
done
grep -E '^\[fleet\]|^FLEET_READY' "$OUT/fly.txt" 2>/dev/null

say "measuring, $WINDOW s with the fleet airborne"
gz topic -e -t /world/fleet/stats > "$OUT/stats-window.txt" 2>/dev/null &
WINDOW_STATS=$!
python3 /sim/probe/cpu.py "$WINDOW" | tee "$OUT/cpu.txt"
kill $WINDOW_STATS 2>/dev/null
wait $FLY 2>/dev/null
FLEW=$?

say "results"
python3 /sim/probe/rtf.py < "$OUT/stats-window.txt" | tee "$OUT/rtf-window.txt"
tail -2 "$OUT/fly.txt"

say "verdict"
printf 'N=%s step=%s camera=%s %s\n' "$COUNT" "$STEP" "${CAMERA:-none}" "$(head -1 "$OUT/rtf-window.txt")"
printf 'fleet: %s\n' "$(grep '^RESULT' "$OUT/fly.txt" 2>/dev/null)"
printf 'cpu: %s\n' "$(grep 'all processes' "$OUT/cpu.txt" 2>/dev/null)"
exit "$FLEW"
