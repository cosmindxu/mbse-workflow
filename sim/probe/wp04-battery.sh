#!/usr/bin/env bash
# WP0.4 — is the duty cycle the autopilot's, or does the model have to keep it?
#
# D4 divides a 40-minute endurance by a declared time scale, so a member flies
# for four minutes of simulated time at factor 10. Two ways that can be true:
# the autopilot's own battery runs out then and trips its own failsafe, or it
# does not and the coordination node has to track charge itself. This says
# which, with numbers.
#
#   measure the hover draw, then size a battery for the scaled endurance:
#     sg docker -c 'docker run --rm -v <repo>/sim:/sim mbse-sim:harmonic \
#       /sim/probe/wp04-battery.sh measure'
#   then verify the failsafe fires where that sizing says it should:
#     sg docker -c 'docker run --rm -v <repo>/sim:/sim mbse-sim:harmonic \
#       /sim/probe/wp04-battery.sh watch 1.35'
set -uo pipefail

MODE=${1:-measure}
CAPACITY_AH=${2:-}
ENDURANCE=${ENDURANCE:-240}   # 40 min at a declared time scale of 10
WINDOW=${WINDOW:-90}
OUT=${OUT:-/sim/out/wp04/$MODE}

mkdir -p "$OUT"
say() { printf '\n== %s ==\n' "$1"; }
# Everything below /sim is the user's working tree, mounted in. The container
# runs as root, so without this every generated file needs sudo to remove.
give_back() { [ -d /sim/out ] && chown -R "$(stat -c %u:%g /sim)" /sim/out 2>/dev/null; }
cleanup() {
  [ -n "${SITL:-}" ] && kill "$SITL" 2>/dev/null
  [ -n "${GZ:-}" ] && kill "$GZ" 2>/dev/null
  give_back
}
trap cleanup EXIT

say "a world with one vehicle"
python3 /sim/probe/fleet_world.py --count 1 --step 0.001 --out "$OUT" \
  | tee "$OUT/world.txt" || exit 1
export GZ_SIM_RESOURCE_PATH="$OUT/models:${GZ_SIM_RESOURCE_PATH:-}"
gz sim -s -r -v 1 "$OUT/fleet.sdf" > "$OUT/gz.log" 2>&1 &
GZ=$!
for _ in $(seq 1 90); do
  gz topic -l 2>/dev/null | grep -q '^/world/fleet/stats$' && break
  sleep 1
done

say "the autopilot"
DEFAULTS=/opt/ardupilot/Tools/autotest/default_params/copter.parm,/opt/ardupilot/Tools/autotest/default_params/gazebo-iris.parm
if [ -n "$CAPACITY_AH" ]; then
  # A battery sized to run out at the scaled endurance, and a failsafe that
  # acts on what it has used rather than on a voltage curve: consumed-mAh is
  # the honest trigger when the capacity is the thing being scaled.
  #
  # BATT_LOW_MAH is the *remaining* mAh at which the low action fires, so it is
  # set to a tenth of the pack — a reserve, as a real operator would keep.
  CAPACITY_MAH=$(python3 -c "print(int(float('$CAPACITY_AH') * 1000))")
  RESERVE_MAH=$(python3 -c "print(int(float('$CAPACITY_AH') * 1000 * 0.10))")
  cat > "$OUT/battery.parm" <<PARM
SIM_BATT_CAP_AH $CAPACITY_AH
BATT_CAPACITY $CAPACITY_MAH
BATT_LOW_MAH $RESERVE_MAH
BATT_FS_LOW_ACT 2
BATT_FS_VOLTSRC 0
PARM
  DEFAULTS="$DEFAULTS,$OUT/battery.parm"
  echo "battery: ${CAPACITY_AH} Ah, low action RTL with ${RESERVE_MAH} mAh in reserve"
  cat "$OUT/battery.parm"
fi

mkdir -p "$OUT/sitl"
( cd "$OUT/sitl" && exec /opt/ardupilot/build/sitl/bin/arducopter \
    --model JSON --speedup 1 --slave 0 --defaults "$DEFAULTS" \
    --sim-address=127.0.0.1 -I0 ) > "$OUT/sitl/sitl.log" 2>&1 &
SITL=$!
for _ in $(seq 1 60); do
  ss -ltn 2>/dev/null | grep -q ':5760' && break
  sleep 1
done

say "flying"
if [ "$MODE" = "measure" ]; then
  python3 /sim/probe/battery.py --measure "$WINDOW" --endurance "$ENDURANCE" \
    | tee "$OUT/battery.txt"
else
  # Long enough to outlast the endurance even at the measured factor, so a
  # failsafe that never fires is a finding rather than a timeout.
  LIMIT=$(python3 -c "print(int($ENDURANCE * 2.5))")
  python3 /sim/probe/battery.py --watch --endurance "$ENDURANCE" \
    --watch-limit "$LIMIT" | tee "$OUT/battery.txt"
fi
RESULT=${PIPESTATUS[0]}

say "verdict"
grep '^RESULT' "$OUT/battery.txt" 2>/dev/null || echo "no result line"
exit "$RESULT"
