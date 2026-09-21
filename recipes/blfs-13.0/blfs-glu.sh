#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/glu.html
# title  : GLU-9.0.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ckage is known to build and work properly using an LFS 13.0 platform. Package
#   ctx: Information Download (HTTP): https://archive.mesa3d.org/glu/glu-9.0.3.tar.xz Download
#   ctx: MD5 sum: 06a4fff9179a98ea32ef41b6d83f6b19 Download size: 216 KB Estimated disk space
#   ctx: required: 5.9 MB Estimated build time: 0.2 SBU GLU Dependencies Required Mesa-25.3.5
#   ctx: Installation of GLU Install GLU by running the following commands:
mkdir build &&
cd    build &&

meson setup ..              \
      --prefix=$XORG_PREFIX \
      --buildtype=release   \
      -D gl_provider=gl     \
      -D default_library=shared &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
ninja install

