#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/libepoxy.html
# title  : libepoxy-1.5.10
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: https://download.gnome.org/sources/libepoxy/1.5/libepoxy-1.5.10.tar.xz Download MD5 sum:
#   ctx: 10c635557904aed5239a4885a7c4efb7 Download size: 220 KB Estimated disk space required: 13
#   ctx: MB (with tests) Estimated build time: 0.1 SBU (with tests) libepoxy Dependencies
#   ctx: Required Mesa-25.3.5 Optional Doxygen-1.16.1 (for documentation) Installation of
#   ctx: libepoxy Install libepoxy by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install

