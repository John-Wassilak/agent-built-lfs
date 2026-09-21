#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/spirv-tools.html
# title  : SPIRV-Tools-1.4.357.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ive/vulkan-sdk-1.4.357.0/SPIRV-Tools-vulkan-sdk-1.4.357.0.tar.gz Download MD5 sum:
#   ctx: c357eec1e33bc95e650aa4c8efdd3b13 Download size: 3.4 MB Estimated disk space required: 80
#   ctx: MB Estimated build time: 0.6 SBU (with tests; both using parallelism=8) SPIRV-Tools
#   ctx: Dependencies Required CMake-4.4.2 and SPIRV-Headers-1.4.357.0 Installation of
#   ctx: SPIRV-Tools Install SPIRV-Tools by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr     \
      -D CMAKE_BUILD_TYPE=Release      \
      -D SPIRV_WERROR=OFF              \
      -D BUILD_SHARED_LIBS=ON          \
      -D SPIRV_TOOLS_BUILD_STATIC=OFF  \
      -D SPIRV-Headers_SOURCE_DIR=/usr \
      -G Ninja .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install

