#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/pangomm2.html
# title  : Pangomm-2.56.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ackage Information Download (HTTP):
#   ctx: https://download.gnome.org/sources/pangomm/2.56/pangomm-2.56.1.tar.xz Download MD5 sum:
#   ctx: f3003015d87cb56c9cf731fa7a920a24 Download size: 728 KB Estimated disk space required: 11
#   ctx: MB Estimated build time: 0.2 SBU Pangomm Dependencies Required libcairomm-1.18.0,
#   ctx: GLibmm-2.86.0 and Pango-1.57.0 Installation of Pangomm Install Pangomm by running the
#   ctx: following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
ninja install

