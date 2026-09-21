#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/abseil-cpp.html
# title  : Abseil-cpp-20260107.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Download (HTTP):
#   ctx: //github.com/abseil/abseil-cpp/releases/download/20260107.1/abseil-cpp-20260107.1.tar.gz
#   ctx: Download MD5 sum: d032877f03483884299c50f527f3983e Download size: 2.2 MB Estimated disk
#   ctx: space required: 34 MB Estimated build time: 0.2 SBU (Using parallelism=4) Abseil-cpp
#   ctx: Dependencies Required CMake-4.2.3 Installation of Abseil-cpp Install Abseil-cpp by
#   ctx: running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr   \
      -D CMAKE_BUILD_TYPE=Release    \
      -D CMAKE_SKIP_INSTALL_RPATH=ON \
      -D ABSL_PROPAGATE_CXX_STD=ON   \
      -D BUILD_SHARED_LIBS=ON        \
      -G Ninja ..                    &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
ninja install

