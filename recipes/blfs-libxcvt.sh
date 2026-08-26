#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/libxcvt.html
# title  : libxcvt-0.1.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: d (HTTP): https://www.x.org/pub/individual/lib/libxcvt-0.1.3.tar.xz Download MD5 sum:
#   ctx: 7fb9c51d33a680f724f34da41768b1d0 Download size: 12 KB Estimated disk space required: 440
#   ctx: KB Estimated build time: less than 0.1 SBU libxcvt Dependencies Required Xorg build
#   ctx: environment (should be set for the following instructions to work) Installation of
#   ctx: libxcvt Install libxcvt by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=$XORG_PREFIX --buildtype=release .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
ninja install

