#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/x/glslang.html
# title  : glslang-16.5.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: //github.com/KhronosGroup/glslang/archive/16.5.0/glslang-16.5.0.tar.gz Download MD5 sum:
#   ctx: 79e949d6d50cc167e7d5307afb04c41a Download size: 4.4 MB Estimated disk space required:
#   ctx: 191 MB (with tests) Estimated build time: 0.4 SBU (with parallelism=4; with tests)
#   ctx: Glslang Dependencies Required CMake-4.4.2 and SPIRV-Tools-1.4.357.0 Installation of
#   ctx: Glslang Install Glslang by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr     \
      -D CMAKE_BUILD_TYPE=Release      \
      -D ALLOW_EXTERNAL_SPIRV_TOOLS=ON \
      -D BUILD_SHARED_LIBS=ON          \
      -D GLSLANG_TESTS=ON              \
      -G Ninja .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install

