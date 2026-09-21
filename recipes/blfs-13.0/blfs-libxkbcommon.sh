#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libxkbcommon.html
# title  : libxkbcommon-1.13.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: t the name of its top-level directory (that Git does not track). libxkbcommon
#   ctx: Dependencies Required xkeyboard-config-2.46 (runtime) Recommended libxcb-1.17.0,
#   ctx: Wayland-1.24.0, and wayland-protocols-1.47 Optional Doxygen-1.16.1 (for generating the
#   ctx: documentation) and Xvfb (from Xorg-Server-21.1.21 or Xwayland-24.1.9) Installation of
#   ctx: libxkbcommon Install libxkbcommon by running the following commands:
mkdir build &&
cd    build &&

meson setup ..             \
      --prefix=/usr        \
      --buildtype=release  \
      -D enable-docs=false &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, ensure Xvfb and xkeyboard-config-2.46 are available, then issue:
#   ctx: ninja test. Now, as the root user:
ninja install

