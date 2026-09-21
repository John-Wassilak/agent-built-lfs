#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/libxkbcommon.html
# title  : libxkbcommon-1.13.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: t except the name of its top-level directory (that Git does not track). libxkbcommon
#   ctx: Dependencies Required xkeyboard-config-2.48 (runtime) Recommended libxcb-1.17.0,
#   ctx: Wayland-1.26.0, and wayland-protocols-1.49 Optional Doxygen-1.18.0 (for generating the
#   ctx: documentation) and Xvfb (from Xorg-Server-21.1.24 or Xwayland-24.1.13) Installation of
#   ctx: libxkbcommon Fix an issue introduced in libxkbcommon-1.13.2:
patch -Np1 -i ../libxkbcommon-1.13.2-upstream_fix-1.patch

# --- block 1 --------------------------------------------------
#   ctx: Install libxkbcommon by running the following commands:
mkdir build &&
cd    build &&

meson setup ..             \
      --prefix=/usr        \
      --buildtype=release  \
      -D enable-docs=false &&
ninja

# --- block 2 --------------------------------------------------
#   ctx: To test the results, ensure Xvfb and xkeyboard-config-2.48 are available, then issue:
#   ctx: ninja test. Now, as the root user:
ninja install

