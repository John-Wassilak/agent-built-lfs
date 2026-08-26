#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/libva.html
# title  : libva-2.23.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Us or later and Intel Arc GPUs), and Mesa-25.3.5 (providing the r600, radeonsi, and
#   ctx: nouveau VA API drivers, for the ATI/AMD Radeon HD 2xxx GPUs and later, and supported
#   ctx: NVIDIA GPUs; there is a circular dependency, read the Mesa page for information on how
#   ctx: to break it) Optional Doxygen-1.16.1, Wayland-1.24.0, and intel-gpu-tools Installation
#   ctx: of libva Install libva by running the following commands:
cd build &&

meson setup --prefix=$XORG_PREFIX --buildtype=release &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
ninja install

