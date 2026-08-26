#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/spirv-tools.html
# title  : SPIRV-Tools-1.4.341.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ive/vulkan-sdk-1.4.341.0/SPIRV-Tools-vulkan-sdk-1.4.341.0.tar.gz Download MD5 sum:
#   ctx: a5f6164b806514cf7a0fc333b50b5e6d Download size: 3.3 MB Estimated disk space required: 63
#   ctx: MB Estimated build time: 0.6 SBU (with tests; both using parallelism=8) SPIRV-Tools
#   ctx: Dependencies Required CMake-4.2.3 and SPIRV-Headers-1.4.341.0 Installation of
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

