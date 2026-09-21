#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/highway.html
# title  : highway-1.3.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: S 13.0 platform. Package Information Download (HTTP):
#   ctx: https://github.com/google/highway/archive/1.3.0/highway-1.3.0.tar.gz Download MD5 sum:
#   ctx: 6c913a4c4ba849a3306d45318f66078d Download size: 3.5 MB Estimated disk space required: 28
#   ctx: MB Estimated build time: 0.6 SBU (with parallelism=4) highway Dependencies Required
#   ctx: CMake-4.2.3 Installation of highway Install highway by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_BUILD_TYPE=Release  \
      -D BUILD_TESTING=OFF         \
      -D BUILD_SHARED_LIBS=ON      \
      -G Ninja ..                  &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: This package does come with a test suite, but it requires gtest, which is not in BLFS.
#   ctx: Now, as the root user:
ninja install

