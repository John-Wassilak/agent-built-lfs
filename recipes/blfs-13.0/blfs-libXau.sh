#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/libXau.html
# title  : libXau-1.0.12
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 0 platform. Package Information Download (HTTP):
#   ctx: https://www.x.org/pub/individual/lib/libXau-1.0.12.tar.xz Download MD5 sum:
#   ctx: 4c9f81acf00b62e5de56a912691bd737 Download size: 276 KB Estimated disk space required:
#   ctx: 2.9 MB (with test) Estimated build time: less than 0.1 SBU (with test) libXau
#   ctx: Dependencies Required xorgproto-2025.1 Installation of libXau Install libXau by running
#   ctx: the following commands:
./configure $XORG_CONFIG &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

