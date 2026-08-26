#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/glslang.html
# title  : glslang-16.2.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: //github.com/KhronosGroup/glslang/archive/16.2.0/glslang-16.2.0.tar.gz Download MD5 sum:
#   ctx: ae3884b31012a68146f45822444d6211 Download size: 4.1 MB Estimated disk space required:
#   ctx: 185 MB (with tests) Estimated build time: 0.4 SBU (with parallelism=4; with tests)
#   ctx: Glslang Dependencies Required CMake-4.2.3 and SPIRV-Tools-1.4.341.0 Installation of
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

