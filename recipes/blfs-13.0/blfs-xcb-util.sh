#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/xcb-util.html
# title  : xcb-util-0.4.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Information Download (HTTP): https://xcb.freedesktop.org/dist/xcb-util-0.4.1.tar.xz
#   ctx: Download MD5 sum: 34d749eab0fd0ffd519ac64798d79847 Download size: 261 KB Estimated disk
#   ctx: space required: 2.6 MB Estimated build time: less than 0.1 SBU xcb-util Dependencies
#   ctx: Required libxcb-1.17.0 Optional Doxygen-1.16.1 (for documentation) Installation of
#   ctx: xcb-util Install xcb-util by running the following commands:
./configure $XORG_CONFIG &&
make

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make install

