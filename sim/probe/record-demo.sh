#!/usr/bin/env bash
# A clip of the fleet flying, recorded headless.
#
# This is *not* the forerunner demo, and it decides nothing. It has no
# handover, no recharge rotation, no injected loss and no monitors — those are
# WP2 to WP4, and they run in `sim/runtime/run.py`. What this shows is that the
# stack renders and records without a display: N autopilots arm and fly, filmed
# by a camera in the world and written to an mp4 by Gazebo's own recorder.
#
# The flight is a choice. The default climbs and holds, which is what a
# measurement wants. `FLY=/sim/probe/swarm_fly.py` spreads the fleet to its
# sectors in deconfliction layers, which is what a camera wants — footage, not
# evidence.
#
#   sg docker -c 'docker run --rm --device /dev/dri \
#     --group-add $(getent group render | cut -d: -f3) \
#     -v <repo>/sim:/sim mbse-sim:harmonic /sim/probe/record-demo.sh 12'
set -uo pipefail

COUNT=${1:-12}
RESOLUTION=${RESOLUTION:-1280x720}
# Gazebo's recorder encodes mp4, avi or ogv directly. ALSO transcodes the
# result into any other container ffmpeg can write, comma separated, e.g.
# ALSO=avi,webm,gif — useful when the clip has to play somewhere particular.
FORMAT=${FORMAT:-mp4}
ALSO=${ALSO:-}
ALTITUDE=${ALTITUDE:-20}
HOLD=${HOLD:-40}
FPS=${FPS:-30}
# Which flight to film. The default takes off and holds, which is what a
# measurement wants; `FLY=/sim/probe/swarm_fly.py` flies the swarm shape the
# model describes, which is what a camera wants. FLY_ARGS goes to it verbatim.
FLY=${FLY:-/sim/probe/fleet_fly.py}
FLY_ARGS=${FLY_ARGS:-}
# Metres across a second, tighter frame, recorded from the same flight. Two
# shots of one flight are two views of the same events; two runs would be two
# different flights.
CLOSEUP=${CLOSEUP:-}
CLOSEUP_RESOLUTION=${CLOSEUP_RESOLUTION:-1280x720}
CAMERA_HEIGHT=${CAMERA_HEIGHT:-}
CLOSEUP_HEIGHT=${CLOSEUP_HEIGHT:-}
TILE_SCALE=${TILE_SCALE:-1.0}
HORIZON=${HORIZON:-}
CLOSEUP_HORIZON=${CLOSEUP_HORIZON:-}
CLOSEUP_AT=${CLOSEUP_AT:-}
# Metres of world across the frame. Unset fits the whole fleet in; a small
# number is a close shot of one or two aircraft.
FRAME=${FRAME:-}
OUT=${OUT:-/sim/out/demo}
case "$FORMAT" in
  mp4|avi|ogv) ;;
  *) echo "Gazebo's recorder writes mp4, avi or ogv; $FORMAT is not one of them."
     echo "Record in one of those and add the rest through ALSO=$FORMAT."; exit 2 ;;
esac
VIDEO="$OUT/fleet-${COUNT}.${FORMAT}"
SHOTS="overview"
[ -n "$CLOSEUP" ] && SHOTS="$SHOTS closeup"
video_for() { [ "$1" = overview ] && echo "$VIDEO" || echo "$OUT/${1}-${COUNT}.${FORMAT}"; }

mkdir -p "$OUT"
say() { printf '\n== %s ==\n' "$1"; }
# Everything below /sim is the user's working tree, mounted in. The container
# runs as root, so without this every generated file needs sudo to remove.
give_back() { [ -d /sim/out ] && chown -R "$(stat -c %u:%g /sim)" /sim/out 2>/dev/null; }
cleanup() {
  for pid in ${SITLS:-}; do kill "$pid" 2>/dev/null; done
  [ -n "${GZ:-}" ] && kill "$GZ" 2>/dev/null
  give_back
}
trap cleanup EXIT

say "the world: $COUNT vehicles, camera $RESOLUTION at ${FPS}fps"
python3 /sim/probe/fleet_world.py --count "$COUNT" --step 0.001 --out "$OUT" \
  --camera "$RESOLUTION" --fps "$FPS" --flight-altitude "$ALTITUDE" \
  ${FRAME:+--frame-width "$FRAME"} \
  --tile-scale "$TILE_SCALE" \
  ${HORIZON:+--horizon "$HORIZON"} ${CLOSEUP_HORIZON:+--closeup-horizon "$CLOSEUP_HORIZON"} \
  ${CAMERA_HEIGHT:+--camera-height "$CAMERA_HEIGHT"} \
  ${CLOSEUP_HEIGHT:+--closeup-height "$CLOSEUP_HEIGHT"} \
  ${CLOSEUP_AT:+--closeup-at "$CLOSEUP_AT"} \
  ${CLOSEUP:+--closeup "$CLOSEUP" --closeup-camera "$CLOSEUP_RESOLUTION"} || exit 1
export GZ_SIM_RESOURCE_PATH="$OUT/models:${GZ_SIM_RESOURCE_PATH:-}"

say "gazebo, headless, rendering on the GPU"
gz sim -s -r --headless-rendering -v 2 "$OUT/fleet.sdf" > "$OUT/gz.log" 2>&1 &
GZ=$!
# Loading N vehicle models and initialising the render engine can outlast a
# short wait, and a timeout here looks exactly like a crash. Be patient.
for _ in $(seq 1 240); do
  gz topic -l 2>/dev/null | grep -q '^/world/fleet/stats$' && break
  sleep 1
done
if ! gz topic -l 2>/dev/null | grep -q '^/world/fleet/stats$'; then
  echo "gazebo never came up:"; tail -20 "$OUT/gz.log"; exit 1
fi
# The recorder only exists once the sensor has been created, which happens on
# the first render pass rather than at load.
for shot in $SHOTS; do
  for _ in $(seq 1 60); do
    gz service -l 2>/dev/null | grep -q "/$shot/record" && break
    sleep 1
  done
done

say "autopilots"
SITLS=""
for n in $(seq 0 $((COUNT - 1))); do
  mkdir -p "$OUT/sitl/$n"
  ( cd "$OUT/sitl/$n" && exec /opt/ardupilot/build/sitl/bin/arducopter \
      --model JSON --speedup 1 --slave 0 \
      --defaults /opt/ardupilot/Tools/autotest/default_params/copter.parm,/opt/ardupilot/Tools/autotest/default_params/gazebo-iris.parm \
      --sim-address=127.0.0.1 -I"$n" ) > "$OUT/sitl/$n/sitl.log" 2>&1 &
  SITLS="$SITLS $!"
done

say "arming (this takes a while for a full fleet — it is not a hang)"
# shellcheck disable=SC2086  # FLY_ARGS is a list of arguments, not one string
python3 "$FLY" --count "$COUNT" --altitude "$ALTITUDE" \
  --hold "$HOLD" $FLY_ARGS > "$OUT/fly.txt" 2>&1 &
FLY_PID=$!
# Start the camera when the fleet is armed rather than at launch: nobody wants
# two and a half minutes of twelve drones sitting still.
for _ in $(seq 1 400); do
  grep -qE '^\[fleet\] armed' "$OUT/fly.txt" 2>/dev/null && break
  kill -0 $FLY_PID 2>/dev/null || break
  sleep 1
done
grep -E '^\[fleet\]' "$OUT/fly.txt" 2>/dev/null

say "recording"
for shot in $SHOTS; do
  gz service -s "/$shot/record" \
    --reqtype gz.msgs.VideoRecord --reptype gz.msgs.Boolean --timeout 5000 \
    --req "start: true, format: \"$FORMAT\", save_filename: \"$(video_for "$shot")\"" 2>&1 | tail -2
done

wait $FLY_PID 2>/dev/null
FLEW=$?
grep -E '^\[fleet\] ' "$OUT/fly.txt" 2>/dev/null

say "stopping the recording"
for shot in $SHOTS; do
  gz service -s "/$shot/record" \
    --reqtype gz.msgs.VideoRecord --reptype gz.msgs.Boolean --timeout 5000 \
    --req 'stop: true' 2>&1 | tail -2
done
# The file is finalised when the recorder flushes, which is not instant.
for _ in $(seq 1 30); do
  [ -s "$VIDEO" ] && break
  sleep 1
done
sleep 3

say "the clip"
for shot in $SHOTS; do
  [ "$shot" = overview ] && continue
  other=$(video_for "$shot")
  if [ -s "$other" ]; then ls -lh "$other" | awk '{print "  " $9, $5}'
  else echo "  no $shot clip was written"; fi
done
if [ -s "$VIDEO" ]; then
  ls -lh "$VIDEO" | awk '{print $9, $5}'
  ffprobe -v error -show_entries format=duration,size \
    -show_entries stream=codec_name,width,height,r_frame_rate \
    -of default=noprint_wrappers=1 "$VIDEO" 2>&1 | head -10

  # Everything else is a transcode of the one recording, never a second run:
  # two runs of a simulation are two different flights.
  IFS=',' read -ra EXTRA <<< "$ALSO"
  for target in "${EXTRA[@]:-}"; do
    [ -z "$target" ] && continue
    other="$OUT/fleet-${COUNT}.${target}"
    case "$target" in
      gif)
        # A palette pass, or the result is a smeared mess at any useful size.
        ffmpeg -v error -y -i "$VIDEO" -vf "fps=12,scale=720:-1:flags=lanczos,palettegen" \
          "$OUT/palette.png" 2>&1 | tail -2
        ffmpeg -v error -y -i "$VIDEO" -i "$OUT/palette.png" \
          -lavfi "fps=12,scale=720:-1:flags=lanczos[v];[v][1:v]paletteuse" "$other" 2>&1 | tail -2
        ;;
      avi)
        ffmpeg -v error -y -i "$VIDEO" -c:v mpeg4 -q:v 4 "$other" 2>&1 | tail -2 ;;
      webm)
        ffmpeg -v error -y -i "$VIDEO" -c:v libvpx-vp9 -crf 32 -b:v 0 "$other" 2>&1 | tail -2 ;;
      *)
        ffmpeg -v error -y -i "$VIDEO" "$other" 2>&1 | tail -2 ;;
    esac
    [ -s "$other" ] && ls -lh "$other" | awk '{print "  also:", $9, $5}'
  done
else
  echo "no video was written; the recorder said:"
  grep -iE 'record|video|error' "$OUT/gz.log" | tail -10
  exit 1
fi
exit "$FLEW"
