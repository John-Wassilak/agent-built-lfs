#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/wayland.html
# title  : Wayland-1.24.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ted disk space required: 7.0 MB (with tests) Estimated build time: less than 0.1 SBU
#   ctx: (with tests) Wayland Dependencies Required libxml2-2.15.1 Optional Doxygen-1.16.1,
#   ctx: Graphviz-14.1.2 and xmlto-0.0.29 (to build the API documentation) and docbook-xml-4.5,
#   ctx: docbook-xsl-nons-1.79.2 and libxslt-1.1.45 (to build the manual pages) Installation of
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

