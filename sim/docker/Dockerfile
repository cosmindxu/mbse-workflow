# The runtime the model flies in: Gazebo Harmonic plus ArduPilot SITL.
#
# Pinned to 24.04 because Harmonic ships for noble and not for the 26.04 host
# this is built on. Everything is a release tag or a commit — an image that
# floats on `main` cannot be the thing a report reproduces.
#
# Build (the host user needs the docker group):
#   sg docker -c 'docker build -t mbse-sim:harmonic sim/docker'
# Rendering is hardware EGL through /dev/dri, so run with:
#   --device /dev/dri --group-add <gid of render>
FROM ubuntu:24.04

ARG ARDUPILOT_TAG=Copter-4.7.1
ARG ARDUPILOT_GAZEBO_SHA=082a0fe231f6e63bc8d1598f1cba461d9e2ea7f5
ARG JOBS=8

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    ARDUPILOT_HOME=/opt/ardupilot

# Gazebo Harmonic, the Mesa userspace that drives the iGPU, and the build tools.
# radeonsi comes from libgl1-mesa-dri: without it EGL falls back to llvmpipe and
# the render is software, which is correct but far too slow for twelve vehicles.
RUN apt-get update -qq \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg lsb-release \
 && curl -fsSL https://packages.osrfoundation.org/gazebo.gpg \
      -o /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg \
 && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable noble main" \
      > /etc/apt/sources.list.d/gazebo-stable.list \
 && apt-get update -qq \
 && apt-get install -y --no-install-recommends \
      gz-harmonic \
      libgz-sim8-dev rapidjson-dev \
      build-essential cmake git pkg-config \
      libegl1 libgl1-mesa-dri libglvnd0 mesa-utils \
      python3 python3-dev python3-pip python3-venv \
      libtool ccache gawk socat net-tools iproute2 procps \
      ffmpeg \
 && rm -rf /var/lib/apt/lists/*

# ArduPilot's own tooling. empy is pinned because waf's code generation breaks
# on 4.x of it; the rest is what SITL and the agents speak MAVLink with.
RUN pip3 install --no-cache-dir --break-system-packages \
      "empy==3.3.4" pexpect future lxml \
      pymavlink MAVProxy pyyaml

# SITL itself. A shallow clone with shallow submodules: the full history plus
# every submodule is several gigabytes and none of it is needed to build.
RUN git clone --depth 1 --branch "${ARDUPILOT_TAG}" \
      --recurse-submodules --shallow-submodules \
      https://github.com/ArduPilot/ardupilot.git "${ARDUPILOT_HOME}" \
 && cd "${ARDUPILOT_HOME}" \
 && ./waf configure --board sitl \
 && ./waf copter -j"${JOBS}" \
 && rm -rf "${ARDUPILOT_HOME}/build/sitl/.lock-waf"* \
 && find "${ARDUPILOT_HOME}/build" -name '*.o' -delete

# What the plugin needs beyond Gazebo itself. Its own layer, after the
# ArduPilot build rather than with the rest of apt, so adding one of these does
# not throw away the twenty minutes of waf above.
# OpenCV and GStreamer are not optional: the camera and gimbal plugins are
# built unconditionally and both are `REQUIRED` in the plugin's CMakeLists.
# cppzmq is gz-transport's own interface dependency, and it is a *recommended*
# package — `--no-install-recommends` above leaves it out, and the plugin then
# fails to generate on a `CPPZMQ::CPPZMQ` target that nothing provides.
RUN apt-get update -qq \
 && apt-get install -y --no-install-recommends \
      libopencv-dev \
      libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
      cppzmq-dev \
 && rm -rf /var/lib/apt/lists/*

# The bridge: Gazebo models a quad, SITL flies it, they talk over the JSON
# backend. The plugin is what makes the two the same vehicle.
# Harmonic is the plugin's default branch; named anyway, so the image does not
# depend on that default staying put.
ENV GZ_VERSION=harmonic
RUN git clone https://github.com/ArduPilot/ardupilot_gazebo.git /opt/ardupilot_gazebo \
 && cd /opt/ardupilot_gazebo \
 && git checkout -q "${ARDUPILOT_GAZEBO_SHA}" \
 && cmake -B build -S . -DCMAKE_BUILD_TYPE=RelWithDebInfo \
 && cmake --build build -j"${JOBS}"

ENV GZ_SIM_SYSTEM_PLUGIN_PATH=/opt/ardupilot_gazebo/build \
    GZ_SIM_RESOURCE_PATH=/opt/ardupilot_gazebo/models:/opt/ardupilot_gazebo/worlds:/sim/out \
    PATH="/opt/ardupilot/Tools/autotest:${PATH}" \
    ARDUPILOT_HOME=/opt/ardupilot
# Headless: no X, no Wayland. The EGL device platform is the one that reaches
# the GPU — surfaceless silently lands on llvmpipe on this host.
ENV EGL_PLATFORM=device \
    GZ_PARTITION=mbse

WORKDIR /sim
CMD ["bash"]
