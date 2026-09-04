#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/cairomm-1.16.html
# title  : libcairomm-1.16 (cairomm-1.18.0)
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: -1.18.0.tar.xz Download MD5 sum: 4c7afc4ab5177655724ea4b31794db30 Download size: 620 KB
#   ctx: Estimated disk space required: 25 MB (with tests) Estimated build time: 0.2 SBU (with
#   ctx: tests) libcairomm-1.16 Dependencies Required Cairo-1.18.4 and libsigc++-3.6.0
#   ctx: Recommended Boost-1.90.0 (for tests) Optional Doxygen-1.16.1 Installation of
#   ctx: libcairomm-1.16 Install Cairomm-1.16 by running the following commands:
mkdir bld &&
cd    bld &&

meson setup ..             \
      --prefix=/usr        \
      --buildtype=release  \
      -D build-tests=false &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To run the test suite, run: ninja test. Now, as the root user:
ninja install

