#!/usr/bin/env python3
"""A world with N autopilot-driven quads, for measuring what N costs.

This is a *probe* world, not the one T-05 generates. It exists to answer one
question — how many vehicles this host can fly at once, and at which physics
step — so by default it carries nothing that would confuse the measurement:
no cameras, no runway mesh, no scenery. Flat ground, a sun, and N vehicles on a
grid. `--camera` adds the one overview shot and the render engine back, because
"what does the fleet cost" and "what does drawing it cost" are separate
questions and WP4 needs both answered.

Each vehicle is a copy of the stock `iris_with_ardupilot` model with its own
`fdm_port_in`, because the plugin's port is baked into the model and SITL
instance `n` speaks on `9002 + 10n`. The copies are written to a generated
resource directory rather than merged into the world, which keeps the plugin's
internally-scoped names (`iris_with_standoffs::rotor_0_joint`) valid without
depending on how `<include merge="true">` resolves scopes.

    python3 fleet_world.py --count 12 --step 0.001 --out /sim/out/wp03/n12-1ms
"""
from __future__ import annotations

import argparse
import math
import pathlib
import re
import shutil
import sys

SOURCE_MODEL = pathlib.Path("/opt/ardupilot_gazebo/models/iris_with_ardupilot")
# SITL instance n binds the JSON backend to this port; the plugin must agree or
# the two halves of the vehicle never meet.
FDM_PORT_BASE = 9002
FDM_PORT_STRIDE = 10
SPACING_M = 10.0
# The camera's own field of view, and how far above the subject it sits. A
# shallow depression keeps the drones against the sky rather than flattened
# onto the ground, which is what makes their separation readable.
HORIZONTAL_FOV = 1.047  # 60 degrees, matching the sensor below
# How high the camera stands, as a fraction of the altitude the fleet flies at.
# Below 1.0 the camera is under the flight and looks up, which is the whole
# difference between a legible shot and an illegible one: from above, a dark
# quadcopter is a speck on a green field, and from below it is a silhouette
# against the sky. The first recording made that mistake at both focal lengths.
CAMERA_HEIGHT = 0.30
# Where the horizon sits, as a fraction of the way down the frame. Aiming by
# the horizon rather than at a height is the only formulation that survives a
# change of lens or resolution: "look at 29 m" put the horizon off the bottom
# of the frame and returned two stills of flat blue.
HORIZON = 0.72

# The sensors system initialises the render engine, so it is only present when
# there is something to render. WP4's video needs it; a measurement of what the
# fleet itself costs does not, and including it would measure the GPU instead.
SENSORS_SYSTEM = """    <plugin
      filename="gz-sim-sensors-system"
      name="gz::sim::systems::Sensors">
      <render_engine>ogre2</render_engine>
    </plugin>
"""

# One camera watching the fleet from off to one side and above, rather than a
# camera per vehicle. An angled view rather than a plan view: from directly
# overhead, twelve quadcopters at the same altitude are twelve identical dots
# and the rotation is unreadable.
#
# A world may carry more than one of these, each with its own recorder service,
# because two shots of one flight are two views of the same events while two
# runs are two different flights. `--closeup` adds a tight second shot: the
# wide one is the honest overview and makes every aircraft small, and at any
# real scale a viewer needs one frame where a drone looks like a drone.
#
# The recorder is a server-side system, so it works with no GUI and no display:
# it is driven by a service call, which is what lets a headless run produce a
# file. Without it there is rendering but nothing to show for it.
SHOT_CAMERA = """    <model name="{id}">
      <static>true</static>
      <pose>{x:.1f} {y:.1f} {height:.1f} 0 {pitch:.4f} {yaw:.4f}</pose>
      <link name="link">
        <sensor name="{id}_camera" type="camera">
          <always_on>1</always_on>
          <update_rate>{fps}</update_rate>
          <topic>{id}</topic>
          <camera>
            <horizontal_fov>1.047</horizontal_fov>
            <image><width>{width}</width><height>{image_height}</height></image>
            <clip><near>0.5</near><far>4000</far></clip>
          </camera>
          <plugin filename="gz-sim-camera-video-recorder-system"
            name="gz::sim::systems::CameraVideoRecorder">
            <service>/{id}/record</service>
            <use_sim_time>true</use_sim_time>
            <fps>{fps}</fps>
          </plugin>
        </sensor>
      </link>
    </model>
"""

# One tile per member, under where it sits. An unbroken plane gives a camera
# nothing to judge motion or distance against: the first recording was four
# dark specks on an unbroken grey field, with no horizon and no scale. These
# are also what a sector looks like, which is what the world T-05 generates
# draws in this place.
SECTOR_TILE = """    <model name="sector_{index}">
      <static>true</static>
      <pose>{x:.1f} {y:.1f} 0.02 0 0 0</pose>
      <link name="link">
        <visual name="visual">
          <geometry><box><size>{size:.1f} {size:.1f} 0.04</size></box></geometry>
          <material>
            <ambient>{shade}</ambient>
            <diffuse>{shade}</diffuse>
          </material>
        </visual>
      </link>
    </model>
"""

MODEL_CONFIG = """<?xml version="1.0"?>
<model>
  <name>{name}</name>
  <version>1.0</version>
  <sdf version="1.9">model.sdf</sdf>
  <description>Probe copy of iris_with_ardupilot on FDM port {port}.</description>
</model>
"""

WORLD = """<?xml version="1.0" ?>
<!-- Generated by sim/probe/fleet_world.py — {count} vehicles, {step} s step.
     A probe world for WP0.3: nothing in it that would be measured instead of
     the thing under measurement. -->
<sdf version="1.9">
  <world name="fleet">
    <physics name="probe" type="ignore">
      <max_step_size>{step}</max_step_size>
      <real_time_factor>1.0</real_time_factor>
    </physics>
    <plugin filename="gz-sim-physics-system"
      name="gz::sim::systems::Physics">
    </plugin>
    <plugin filename="gz-sim-user-commands-system"
      name="gz::sim::systems::UserCommands">
    </plugin>
    <plugin filename="gz-sim-scene-broadcaster-system"
      name="gz::sim::systems::SceneBroadcaster">
    </plugin>
    <!-- The IMU system is not optional: the ArduPilot plugin reads
         iris_with_standoffs::imu_link::imu_sensor and sends it to SITL. -->
    <plugin filename="gz-sim-imu-system"
      name="gz::sim::systems::Imu">
    </plugin>
{sensors}
    <spherical_coordinates>
      <latitude_deg>-35.363262</latitude_deg>
      <longitude_deg>149.165237</longitude_deg>
      <elevation>584</elevation>
      <heading_deg>0</heading_deg>
      <surface_model>EARTH_WGS84</surface_model>
    </spherical_coordinates>

    <light type="directional" name="sun">
      <cast_shadows>false</cast_shadows>
      <pose>0 0 10 0 0 0</pose>
      <diffuse>0.8 0.8 0.8 1</diffuse>
      <specular>0.2 0.2 0.2 1</specular>
      <direction>-0.5 0.1 -0.9</direction>
    </light>

    <!-- No `<sky>`: Gazebo's skybox renders as a pale wash that a dark
         quadcopter disappears into. A plain background colour gives a clean
         horizon and a silhouette. -->
    <scene>
      <ambient>0.45 0.47 0.5 1</ambient>
      <background>0.35 0.58 0.85</background>
      <shadows>true</shadows>
    </scene>

    <!-- `static` is a child element in SDF, not an attribute. Written as an
         attribute it is silently ignored (sdformat warns and moves on), the
         ground becomes a dynamic body and falls, and the vehicle falls with
         it. An IMU in free fall reads no gravity, so the EKF never
         initialises and every arm attempt is refused with
         "Arm: System not initialised". -->
    <model name="ground">
      <static>true</static>
      <link name="link">
        <collision name="collision">
          <geometry><plane><normal>0 0 1</normal><size>4000 4000</size></plane></geometry>
          <surface><friction><ode><mu>1.0</mu><mu2>1.0</mu2></ode></friction></surface>
        </collision>
        <visual name="visual">
          <geometry><plane><normal>0 0 1</normal><size>4000 4000</size></plane></geometry>
          <material>
            <ambient>0.25 0.30 0.22 1</ambient>
            <diffuse>0.33 0.40 0.28 1</diffuse>
          </material>
        </visual>
      </link>
    </model>

{tiles}
{vehicles}
{camera}
  </world>
</sdf>
"""

VEHICLE = """    <include>
      <uri>model://{name}</uri>
      <pose>{x:.1f} {y:.1f} {z:.3f} 0 0 0</pose>
{static}    </include>
"""

# `--hover` pins the fleet at altitude and makes it static, so a still shows
# where the aircraft actually land in frame. Nothing flies in that world and
# nothing may be measured from it; it exists so that composing a shot costs a
# render instead of a flight.
STATIC = "      <static>true</static>\n"


def shot(name: str, subject_width: float, flight_altitude: float,
         width: int, height: int, fps: int, camera_height: float = 0.0,
         horizon: float = HORIZON, at: tuple[float, float, float] | None = None) -> str:
    """One camera, placed at the distance that fits `subject_width` in frame.

    The camera is composed rather than aimed: the ground line falls `horizon`
    of the way down the frame and the fleet reads against the sky above it.
    Pushing `horizon` up tilts the camera further back, which is how a close
    shot keeps aircraft in frame without losing the ground.

    Aiming directly at the fleet instead (`horizon = 0`) is available and was
    how the close shot was first written, but every steep aim it produced came
    back as an empty frame — the background colour and nothing else — although
    the fleet was inside the frustum by construction. The cause was not
    established. Shots are composed in the shallow range that renders.

    `at` overrides the placement and stands the camera where it is told,
    facing the middle of the grid. How large an aircraft looks is set by how
    close it passes and nothing else, so a shot that wants one to fill the
    frame has to be taken from inside the formation rather than from outside
    it with a tighter frame.
    """
    # half-width / tan(half the horizontal field of view)
    distance = (subject_width / 2) / math.tan(HORIZONTAL_FOV / 2) * 1.15
    camera_z = camera_height or flight_altitude * CAMERA_HEIGHT
    if at is not None:
        x, y, camera_z = at
        yaw = math.atan2(-y, -x)
    else:
        x, y = -distance / math.sqrt(2), -distance / math.sqrt(2)
        yaw = math.pi / 4  # looking back at the grid from one corner
    # The vertical field follows from the horizontal one and the frame's shape,
    # so composition has to be expressed in it rather than in the horizontal.
    half_vertical = math.atan(math.tan(HORIZONTAL_FOV / 2) * height / width)
    if horizon:
        # Elevation that puts the horizon `horizon` of the way down the frame.
        elevation = half_vertical * (2 * horizon - 1)
    else:
        elevation = math.atan2(flight_altitude - camera_z, distance)
    return SHOT_CAMERA.format(
        id=name, x=x, y=y, height=camera_z,
        pitch=-elevation,  # negative pitch is nose-up
        yaw=yaw, width=width, image_height=height, fps=fps,
    )


def grid(count: int) -> list[tuple[float, float]]:
    """Poses on as square a grid as `count` allows, centred on the origin."""
    columns = math.ceil(math.sqrt(count))
    rows = math.ceil(count / columns)
    origin_x = -(columns - 1) * SPACING_M / 2
    origin_y = -(rows - 1) * SPACING_M / 2
    return [
        (origin_x + (n % columns) * SPACING_M, origin_y + (n // columns) * SPACING_M)
        for n in range(count)
    ]


def vehicle_model(source: str, name: str, port: int) -> str:
    """The stock model with its identity and its FDM port replaced."""
    patched, model_names = re.subn(
        r'<model name=(["\'])iris_with_ardupilot\1',
        f'<model name="{name}"',
        source,
        count=1,
    )
    if model_names != 1:
        raise SystemExit("could not find the model name in the source model.sdf")
    patched, ports = re.subn(
        r"<fdm_port_in>\d+</fdm_port_in>",
        f"<fdm_port_in>{port}</fdm_port_in>",
        patched,
        count=1,
    )
    if ports != 1:
        raise SystemExit("could not find fdm_port_in in the source model.sdf")
    return patched


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--count", type=int, required=True)
    parser.add_argument("--step", type=float, default=0.001)
    parser.add_argument("--out", type=pathlib.Path, required=True)
    parser.add_argument("--source", type=pathlib.Path, default=SOURCE_MODEL)
    parser.add_argument(
        "--camera",
        metavar="WIDTHxHEIGHT",
        help="add one overview camera and the sensors system, e.g. 1280x720; "
             "this is the configuration WP4's video runs in, and it is what "
             "makes the measurement a render measurement rather than a fleet one",
    )
    parser.add_argument("--fps", type=int, default=30, help="camera and recording frame rate")
    parser.add_argument(
        "--frame-width", type=float, default=0.0,
        help="metres of world across the frame; 0 fits the whole fleet",
    )
    parser.add_argument(
        "--flight-altitude", type=float, default=20.0,
        help="how high the fleet will fly — the camera is framed on that volume, "
             "not on the ground the vehicles start from",
    )
    parser.add_argument(
        "--closeup", type=float, default=0.0, metavar="METRES",
        help="add a second, tighter camera holding this many metres across the "
             "frame, recording to /closeup/record — one flight, two shots",
    )
    parser.add_argument(
        "--closeup-camera", default="1280x720", metavar="WIDTHxHEIGHT",
        help="resolution of the close shot (default 1280x720)",
    )
    parser.add_argument(
        "--camera-height", type=float, default=0.0, metavar="METRES",
        help="how high each camera stands; 0 takes it from the flight altitude",
    )
    parser.add_argument(
        "--closeup-height", type=float, default=0.0, metavar="METRES",
        help="how high the close camera stands; 0 follows --camera-height",
    )
    parser.add_argument(
        "--hover", type=float, default=0.0, metavar="METRES",
        help="pin the fleet at this altitude, static — for composing a shot "
             "without flying it; such a world cannot be flown or measured",
    )
    parser.add_argument(
        "--horizon", type=float, default=HORIZON,
        help=f"where the ground line falls down the frame (default {HORIZON})",
    )
    parser.add_argument(
        "--closeup-horizon", type=float, default=0.0,
        help="the same for the close shot; 0 follows --horizon",
    )
    parser.add_argument(
        "--closeup-at", metavar="X,Y,Z",
        help="stand the close camera here, facing the middle of the grid, "
             "instead of outside the formation looking in",
    )
    parser.add_argument(
        "--tile-scale", type=float, default=1.0,
        help="spread the ground tiles by this much, to cover where the fleet "
             "flies to rather than only where it launches from",
    )
    args = parser.parse_args()

    if args.count < 1:
        raise SystemExit("a fleet of fewer than one vehicle is not a fleet")
    source = (args.source / "model.sdf").read_text()

    models = args.out / "models"
    if models.exists():
        shutil.rmtree(models)
    models.mkdir(parents=True)

    poses = grid(args.count)
    includes = []
    for n, (x, y) in enumerate(poses):
        name = f"iris_ap_{n}"
        port = FDM_PORT_BASE + FDM_PORT_STRIDE * n
        directory = models / name
        directory.mkdir()
        (directory / "model.sdf").write_text(vehicle_model(source, name, port))
        (directory / "model.config").write_text(MODEL_CONFIG.format(name=name, port=port))
        includes.append(VEHICLE.format(
            name=name, x=x, y=y, z=args.hover or 0.195,
            static=STATIC if args.hover else "",
        ))

    def resolution(text: str) -> tuple[int, int]:
        try:
            width, height = (int(v) for v in text.lower().split("x", 1))
        except ValueError:
            raise SystemExit(f"a resolution is WIDTHxHEIGHT, not {text!r}")
        return width, height

    sensors = ""
    camera = ""
    if args.camera:
        width, height = resolution(args.camera)
        sensors = SENSORS_SYSTEM
        # Framed on the volume the fleet actually occupies, not on the ground
        # it sits over. The first recording put the camera far enough back to
        # hold a hundred metres of empty field, and four quadcopters came out
        # six pixels across: the shot has to be composed for the subject.
        #
        # The subject is the grid, as wide as the vehicles are spread, and as
        # tall as they climb. The camera is then placed at the distance that
        # fits that box in a 60-degree field of view, with a margin.
        span = max(abs(x) for x, _ in poses) * 2 + SPACING_M if poses else SPACING_M
        # How wide a slice of the world the frame holds. Framing on the whole
        # fleet is the honest overview and makes each aircraft small — at the
        # forerunner's real scale, twelve drones over 5 km, it makes them
        # invisible. `--frame-width` overrides it for a close shot, and WP4
        # needs markers or overlays rather than a better lens.
        subject_width = args.frame_width or max(span + SPACING_M, args.flight_altitude * 1.2)
        camera = shot("overview", subject_width, args.flight_altitude,
                      width, height, args.fps, args.camera_height, args.horizon)
        if args.closeup:
            close_width, close_height = resolution(args.closeup_camera)
            # The close shot is tilted further back than the wide one: at
            # this range the aircraft sit higher in the frame, and a horizon
            # composed for the wide shot would put them off the top of it.
            at = None
            if args.closeup_at:
                try:
                    cx, cy, cz = (float(v) for v in args.closeup_at.split(","))
                except ValueError:
                    raise SystemExit(f"--closeup-at wants X,Y,Z, not {args.closeup_at!r}")
                at = (cx, cy, cz)
            camera += shot("closeup", args.closeup, args.flight_altitude,
                           close_width, close_height, args.fps,
                           args.closeup_height or args.camera_height,
                           args.closeup_horizon or args.horizon, at)

    # A tile under each member, alternating so that motion across them reads.
    shades = ('0.46 0.52 0.40 1', '0.24 0.29 0.22 1')
    # Tiles under where the fleet ends up, not only where it starts: with
    # `--tile-scale` matching the flight's spread, the checkerboard is the
    # ground the members actually cross, and crossing it is what makes the
    # motion readable.
    scale = args.tile_scale
    tiles = "".join(
        SECTOR_TILE.format(index=n, x=x * scale, y=y * scale,
                           size=SPACING_M * scale * 0.92,
                           shade=shades[(n + (n // max(1, math.ceil(math.sqrt(args.count))))) % 2])
        for n, (x, y) in enumerate(poses)
    )

    world = args.out / "fleet.sdf"
    world.write_text(
        WORLD.format(
            count=args.count, step=args.step, vehicles="".join(includes),
            sensors=sensors, camera=camera, tiles=tiles,
        )
    )
    print(
        f"{world} — {args.count} vehicles, step {args.step} s"
        + (f", overview camera {args.camera}" if args.camera else ", no camera")
        + (f", closeup {args.closeup_camera} over {args.closeup:g} m" if args.closeup else "")
    )
    print(f"models under {models}; FDM ports {FDM_PORT_BASE}..{FDM_PORT_BASE + FDM_PORT_STRIDE * (args.count - 1)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
