#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/util-macros.html
# title  : util-macros-1.20.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: www.x.org/pub/individual/util/util-macros-1.20.2.tar.xz Download MD5 sum:
#   ctx: 5f683a1966834b0a6ae07b3680bcb863 Download size: 84 KB Estimated disk space required: 524
#   ctx: KB Estimated build time: less than 0.1 SBU util-macros Dependencies Required Xorg build
#   ctx: environment (should be set for the following instructions to work) Installation of
#   ctx: util-macros Install util-macros by running the following commands:
./configure $XORG_CONFIG

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make install

