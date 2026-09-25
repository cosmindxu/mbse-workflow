#!/usr/bin/env bash
# WP0.2 — does the stack fly, headless, on the GPU?
#
# Three questions, in the order that matters: is the render hardware (an
# llvmpipe answer changes the plan), does Gazebo hold real time with one
# vehicle, and do SITL and Gazebo agree that they are the same aircraft.
#
# Run inside the image:
#   sg docker -c 'docker run --rm --device /dev/dri -v <repo>/sim:/sim \
#     mbse-sim:harmonic /sim/probe/wp02-smoke.sh'
set -uo pipefail

WORLD=${WORLD:-iris_runway.sdf}
OUT=${OUT:-/sim/out/wp02}
mkdir -p "$OUT"

say() { printf '\n== %s ==\n' "$1"; }

say "the renderer"
# The device platform is the one that reaches the iGPU; anything saying
# llvmpipe here means the video would be software-rendered.
eglinfo 2>/dev/null \
  | sed -n '/^Device platform:/,/core profile version/p' \
  | grep -iE 'EGL driver name|core profile (vendor|renderer|version)' \
  | tee "$OUT/renderer.txt"
if grep -qi llvmpipe "$OUT/renderer.txt"; then
  echo "SOFTWARE RENDERING — stop and decide before building on this"
fi

say "gazebo, server only, headless"
gz sim -s -r --headless-rendering -v 3 "$WORLD" > "$OUT/gz.log" 2>&1 &
GZ=$!
trap 'kill $GZ 2>/dev/null; kill ${SITL:-0} 2>/dev/null' EXIT
for _ in $(seq 1 60); do
  WORLD_NAME=$(gz topic -l 2>/dev/null | sed -n 's#^/world/\([^/]*\)/stats$#\1#p' | head -1)
  [ -n "${WORLD_NAME:-}" ] && break
  sleep 1
done
if [ -z "${WORLD_NAME:-}" ]; then
  echo "gazebo never published a stats topic; last log lines:"; tail -20 "$OUT/gz.log"; exit 1
fi
echo "world: $WORLD_NAME"

# Not measured here: the ArduPilot plugin blocks each step waiting for a
# packet from SITL, so a factor taken before SITL connects measures the wait,
# not the physics. The baseline that means something is a world without the
# plugin, and it is taken at the end.

say "SITL"
cd /opt/ardupilot || exit 1
sim_vehicle.py -v ArduCopter -f gazebo-iris --model JSON \
  --no-rebuild --no-mavproxy -I0 > "$OUT/sitl.log" 2>&1 &
SITL=$!
# SITL without MAVProxy speaks on tcp:5760; wait for the port rather than
# guessing how long the autopilot takes to come up.
for _ in $(seq 1 60); do
  ss -ltn 2>/dev/null | grep -q ':5760' && break
  sleep 1
done

say "takeoff, with the clock recorded across the whole flight"
# Recording throughout rather than sampling after: the factor during a climb
# and the factor while the autopilot settles differ by more than a factor of
# three, and a snapshot picks whichever moment it lands in.
gz topic -e -t "/world/$WORLD_NAME/stats" > "$OUT/stats-flight.txt" 2>/dev/null &
STATS=$!
python3 /sim/probe/takeoff.py 10 tcp:127.0.0.1:5760 | tee "$OUT/takeoff.txt"
FLEW=${PIPESTATUS[0]}
kill $STATS 2>/dev/null
cp /tmp/ArduCopter.log "$OUT/arducopter.log" 2>/dev/null

say "real-time factor, one vehicle in lockstep with SITL"
python3 /sim/probe/rtf.py < "$OUT/stats-flight.txt" | tee "$OUT/rtf-flight.txt"

say "physics baseline, no autopilot in the loop"
# The lockstep pair has to be gone first: a baseline measured beside a server
# that is still stepping twelve vehicles measures the machine, not the physics.
kill $SITL 2>/dev/null; kill $GZ 2>/dev/null
wait $SITL 2>/dev/null; wait $GZ 2>/dev/null
gz sim -s -r --headless-rendering -v 1 shapes.sdf > "$OUT/gz-baseline.log" 2>&1 &
BASE=$!
sleep 8
BASE_WORLD=$(gz topic -l 2>/dev/null | sed -n 's#^/world/\([^/]*\)/stats$#\1#p' | grep -v "^$WORLD_NAME$" | head -1)
if [ -n "${BASE_WORLD:-}" ]; then
  timeout 20 gz topic -e -t "/world/$BASE_WORLD/stats" > "$OUT/stats-baseline.txt" 2>/dev/null
  python3 /sim/probe/rtf.py < "$OUT/stats-baseline.txt" | tee "$OUT/rtf-baseline.txt"
fi
kill $BASE 2>/dev/null

say "verdict"
echo "takeoff exit: $FLEW  (0 = flew and landed)"
grep -iE 'renderer' "$OUT/renderer.txt"
echo "in lockstep with one autopilot: $(head -1 "$OUT/rtf-flight.txt" 2>/dev/null)"
echo "physics alone:                  $(head -1 "$OUT/rtf-baseline.txt" 2>/dev/null)"
[ -d /sim/out ] && chown -R "$(stat -c %u:%g /sim)" /sim/out 2>/dev/null
exit "$FLEW"
