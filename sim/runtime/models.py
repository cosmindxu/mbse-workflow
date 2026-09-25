#!/usr/bin/env python3
"""One vehicle model per member, made from the airframe the image carries.

T-05 decides how many vehicles there are, where they start and which port each
one speaks on, and writes that into `fleet.yaml` and the world. It cannot make
the models themselves: the stock airframe lives in the runtime image, and the
generator runs on a host that has never seen it.

So this is the other half, and it runs where the airframe is. For each instance
in `fleet.yaml` it copies `iris_with_ardupilot` and rewrites two things — the
model's name, and the `fdm_port_in` the ArduPilot plugin listens on.

It is a copy rather than a wrapper on purpose. A model that merge-includes the
stock one and overrides the port looks right, loads without complaint, and is
inert: the plugin does not come through, the world holds airframes no autopilot
is attached to, and the only symptom is that SITL never receives a JSON frame.
Copying the model is uglier and works.

    python3 models.py --fleet /sim/out/v7/fleet.yaml --into /sim/out/v7/models
"""
from __future__ import annotations

import argparse
import os
import pathlib
import re
import shutil
import sys

import yaml

STOCK_AIRFRAME = pathlib.Path("/opt/ardupilot_gazebo/models")

MODEL_CONFIG = """<?xml version="1.0"?>
<model>
  <name>{name}</name>
  <version>1.0</version>
  <sdf version="1.9">model.sdf</sdf>
  <description>{description}</description>
</model>
"""


class MaterialiseRefused(Exception):
    """Something the fleet file promised is not here to be made."""


def vehicle_model(source: str, name: str, port: int) -> str:
    """The stock airframe under a new name, listening on its own port."""
    patched, names = re.subn(
        r"<model name=([\"'])[A-Za-z0-9_]+\1", f'<model name="{name}"', source, count=1
    )
    if names != 1:
        raise MaterialiseRefused("no model name in the stock airframe's model.sdf")
    patched, ports = re.subn(
        r"<fdm_port_in>\d+</fdm_port_in>",
        f"<fdm_port_in>{port}</fdm_port_in>",
        patched,
        count=1,
    )
    if ports != 1:
        # Better to stop than to write twelve vehicles that all listen on 9002:
        # they would load, and only one of them would ever fly.
        raise MaterialiseRefused(
            "no <fdm_port_in> in the stock airframe — every instance would share a port"
        )
    return patched


def materialise(fleet_path: pathlib.Path, into: pathlib.Path,
                airframes: pathlib.Path = STOCK_AIRFRAME) -> list[str]:
    fleet = yaml.safe_load(fleet_path.read_text())
    instances = fleet.get("instances") or []
    if not instances:
        raise MaterialiseRefused(f"{fleet_path} lists no instances")

    airframe = fleet.get("airframe", "iris_with_ardupilot")
    source_path = airframes / airframe / "model.sdf"
    if not source_path.is_file():
        raise MaterialiseRefused(
            f"the airframe {airframe} is not in {airframes} — this has to run "
            "inside the runtime image, where it exists"
        )
    source = source_path.read_text()

    if into.exists():
        shutil.rmtree(into)
    into.mkdir(parents=True)

    made: list[str] = []
    seen_ports: set[int] = set()
    for instance in instances:
        name = instance.get("model") or f"member_{instance['id']}"
        port = instance["fdm_port"]
        if port in seen_ports:
            raise MaterialiseRefused(f"two instances claim FDM port {port}")
        seen_ports.add(port)

        directory = into / name
        directory.mkdir()
        (directory / "model.sdf").write_text(vehicle_model(source, name, port))
        (directory / "model.config").write_text(
            MODEL_CONFIG.format(
                name=name,
                description=(
                    f"Member {instance['id']} of {fleet.get('fleet_usage', 'the fleet')}, "
                    f"FDM port {port}, MAVLink {instance.get('mavlink_port', '?')}."
                ),
            )
        )
        made.append(name)

    # The runtime is root inside a container and `into` is usually a directory
    # on the user's machine; without this every generated model needs sudo to
    # remove. Hand it back to whoever owns the tree it was written into.
    try:
        owner = into.parent.stat()
        for path in [into, *into.rglob("*")]:
            os.chown(path, owner.st_uid, owner.st_gid)
    except (OSError, PermissionError):
        pass  # not root, or not ours to give: not worth failing a run over

    return made


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fleet", type=pathlib.Path, required=True)
    parser.add_argument("--into", type=pathlib.Path, required=True)
    parser.add_argument("--airframes", type=pathlib.Path, default=STOCK_AIRFRAME)
    args = parser.parse_args()
    try:
        made = materialise(args.fleet, args.into, args.airframes)
    except MaterialiseRefused as refusal:
        print(f"[models] refused: {refusal}", file=sys.stderr)
        return 1
    print(f"[models] {len(made)} vehicle model(s) in {args.into}: {made[0]}..{made[-1]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
