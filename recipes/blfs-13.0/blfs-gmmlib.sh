#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/gmmlib.html
# title  : gmmlib-22.8.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ect and consistent (i.e. it shouldn't change when using the browser instead of a tool
#   ctx: like wget). Our tag and the upstream release tag are on the same commit, so we've not
#   ctx: introduced any change to the tarball content except the name of its top-level directory
#   ctx: (that Git does not track). gmmlib Dependencies Required CMake-4.2.3 Installation of
#   ctx: gmmlib Install gmmlib by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr \
      -D BUILD_TYPE=Release        \
      -G Ninja                     \
      -W no-dev ..                 &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: The test suite is normally run by ninja unless -D RUN_TEST_SUITE=NO is passed to cmake.
#   ctx: Now, as the root user:
ninja install

