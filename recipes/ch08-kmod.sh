#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/kmod.html
# title  : 8.60. Kmod-34.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Kmod package contains libraries and utilities for loading kernel modules Approximate
#   ctx: build time: less than 0.1 SBU Required disk space: 6.7 MB 8.60.1. Installation of Kmod
#   ctx: Prepare Kmod for compilation:
mkdir -p build
cd       build

meson setup --prefix=/usr ..    \
            --buildtype=release \
            -D manpages=false

# --- block 1 --------------------------------------------------
#   ctx: The meaning of the configure options: -D manpages=false This option disables generating
#   ctx: the man pages which requires an external program. Compile the package:
ninja

# --- block 2 --------------------------------------------------
#   ctx: The test suite of this package requires raw kernel headers (not the “sanitized” kernel
#   ctx: headers installed earlier), which are beyond the scope of LFS. Now install the package:
ninja install

