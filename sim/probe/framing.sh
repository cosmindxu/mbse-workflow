#!/usr/bin/env bash
# One still through each camera, without flying anything.
#
# Composing a shot by recording a flight costs ten minutes an attempt, and the
# first two attempts were thrown away for reasons — the horizon in the wrong
# place, the subject too far off — that a single frame would have shown. This
# builds the world, renders it, grabs a frame per camera and stops. No
# autopilots, so the vehicles sit where they spawn: it answers where the
# horizon falls, how much ground is in frame and how big a vehicle is, which is
# all that framing is.
#
#   sg docker -c 'docker run --rm --device /dev/dri \
#     --group-add $(getent group render | cut -d: -f3) \
#     -v <repo>/sim:/sim mbse-sim:harmonic /sim/probe/framing.sh'
set -uo pipefail

COUNT=${COUNT:-12}
OUT=${OUT:-/sim/out/framing}
RESOLUTION=${RESOLUTION:-1920x1080}
FRAME=${FRAME:-60}
ALTITUDE=${ALTITUDE:-25}
CLOSEUP=${CLOSEUP:-}
CLOSEUP_RESOLUTION=${CLOSEUP_RESOLUTION:-1280x720}
CAMERA_HEIGHT=${CAMERA_HEIGHT:-}
CLOSEUP_HEIGHT=${CLOSEUP_HEIGHT:-}
TILE_SCALE=${TILE_SCALE:-1.0}
HORIZON=${HORIZON:-}
CLOSEUP_HORIZON=${CLOSEUP_HORIZON:-}
CLOSEUP_AT=${CLOSEUP_AT:-}
# Where the fleet is pinned for the still. It is not flying: this is a picture
# of where the aircraft fall in frame, and nothing else.
HOVER=${HOVER:-25}
# Seconds of recording per camera. The frame is pulled out of it afterwards,
# and the first frames of a Gazebo recording are the scene before it has been
# drawn — flat sky — so this has to be long enough to have a drawn frame in it.
SECONDS_EACH=${SECONDS_EACH:-6}

SHOTS="overview"
[ -n "$CLOSEUP" ] && SHOTS="$SHOTS closeup"
mkdir -p "$OUT"
give_back() { [ -d /sim/out ] && chown -R "$(stat -c %u:%g /sim)" /sim/out 2>/dev/null; }
cleanup() { [ -n "${GZ:-}" ] && kill "$GZ" 2>/dev/null; give_back; }
trap cleanup EXIT

# A coarse step: nothing is being flown, so physics fidelity buys nothing here.
python3 /sim/probe/fleet_world.py --count "$COUNT" --step 0.004 --out "$OUT" \
  --camera "$RESOLUTION" --fps 30 --flight-altitude "$ALTITUDE" \
  --frame-width "$FRAME" --hover "$HOVER" \
  --tile-scale "$TILE_SCALE" \
  ${HORIZON:+--horizon "$HORIZON"} ${CLOSEUP_HORIZON:+--closeup-horizon "$CLOSEUP_HORIZON"} \
  ${CAMERA_HEIGHT:+--camera-height "$CAMERA_HEIGHT"} \
  ${CLOSEUP_HEIGHT:+--closeup-height "$CLOSEUP_HEIGHT"} \
  ${CLOSEUP_AT:+--closeup-at "$CLOSEUP_AT"} \
  ${CLOSEUP:+--closeup "$CLOSEUP" --closeup-camera "$CLOSEUP_RESOLUTION"} \
 || exit 1
export GZ_SIM_RESOURCE_PATH="$OUT/models:${GZ_SIM_RESOURCE_PATH:-}"

gz sim -s -r --headless-rendering -v 1 "$OUT/fleet.sdf" > "$OUT/gz.log" 2>&1 &
GZ=$!
for _ in $(seq 1 180); do
  gz topic -l 2>/dev/null | grep -q '^/world/fleet/stats$' && break
  sleep 1
done
for shot in $SHOTS; do
  for _ in $(seq 1 60); do
    gz service -l 2>/dev/null | grep -q "/$shot/record" && break
    sleep 1
  done
done

for shot in $SHOTS; do
  clip="$OUT/$shot.mp4"
  gz service -s "/$shot/record" --reqtype gz.msgs.VideoRecord \
    --reptype gz.msgs.Boolean --timeout 5000 \
    --req "start: true, format: \"mp4\", save_filename: \"$clip\"" > /dev/null 2>&1
  sleep "$SECONDS_EACH"
  gz service -s "/$shot/record" --reqtype gz.msgs.VideoRecord \
    --reptype gz.msgs.Boolean --timeout 5000 --req 'stop: true' > /dev/null 2>&1
  for _ in $(seq 1 20); do [ -s "$clip" ] && break; sleep 1; done
  sleep 2
  if [ -s "$clip" ]; then
    # Every frame written over the same file, so what survives is the last
    # one. Seeking to the end instead lands on whatever frame the seek finds,
    # and on a short clip that was the blank one the scene starts with.
    ffmpeg -v error -i "$clip" -update 1 -y "$OUT/$shot.png" 2>&1 | tail -1
    rm -f "$clip"
    echo "  $OUT/$shot.png"
  else
    echo "  no frame through $shot; the recorder said:"
    grep -iE 'record|video|error' "$OUT/gz.log" | tail -5
  fi
done
