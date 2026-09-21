#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/wayland.html
# title  : Wayland-1.26.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: f6820635765a952ec5f34fbb Download size: 600 KB Estimated disk space required: 9.0 MB
#   ctx: (with tests) Estimated build time: less than 0.1 SBU (with tests) Wayland Dependencies
#   ctx: Required libxml2-2.15.3 Optional Doxygen-1.18.0, Graphviz-15.1.1 and xmlto-0.0.29 (to
#   ctx: build the API documentation) and mdBook (to build the manual pages) Installation of
#   ctx: Wayland Install Wayland by running the following commands:
mkdir build &&
cd    build &&

meson setup ..            \
      --prefix=/usr       \
      --buildtype=release \
      -D documentation=false &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: env -u XDG_RUNTIME_DIR ninja test. Now, as the root user:
ninja install

