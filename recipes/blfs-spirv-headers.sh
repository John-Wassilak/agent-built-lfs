#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/spirv-headers.html
# title  : SPIRV-Headers-1.4.341.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: oup/SPIRV-Headers/archive/vulkan-sdk-1.4.341.0/SPIRV-Headers-vulkan-sdk-1.4.341.0.tar.gz
#   ctx: Download MD5 sum: 38bcd69036ec1443ac19b417bef8685e Download size: 552 KB Estimated disk
#   ctx: space required: 4.6 MB Estimated build time: less than 0.1 SBU SPIRV-Headers
#   ctx: Dependencies Required CMake-4.2.3 Installation of SPIRV-Headers Install SPIRV-Headers by
#   ctx: running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr -G Ninja .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
ninja install

