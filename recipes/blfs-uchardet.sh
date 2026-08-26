#!/bin/bash
# HAND-AUTHORED recipe from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/uchardet.html
# title  : uchardet-0.0.8
# rationale: Recommended dependency of mpv (tier 14). Required: CMake
# (already built, tier 1).
set -e

mkdir build
cd build

cmake -D CMAKE_INSTALL_PREFIX=/usr \
      -D BUILD_STATIC=OFF \
      -D CMAKE_POLICY_VERSION_MINIMUM=3.5 \
      -W no-dev ..
make

make install

echo "### pkg-config"
pkg-config --modversion uchardet 2>&1 || true
