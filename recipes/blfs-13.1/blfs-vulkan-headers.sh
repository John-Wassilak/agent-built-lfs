#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/x/vulkan-headers.html
# title  : Vulkan-Headers-1.4.357.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: p/Vulkan-Headers/archive/vulkan-sdk-1.4.357.0/Vulkan-Headers-vulkan-sdk-1.4.357.0.tar.gz
#   ctx: Download MD5 sum: 64a23bb12e95a2017004d72569132929 Download size: 3.3 MB Estimated disk
#   ctx: space required: 122 MB Estimated build time: less than 0.1 SBU (with tests)
#   ctx: Vulkan-Headers Dependencies Required CMake-4.4.2 Installation of Vulkan-Headers Install
#   ctx: Vulkan-Headers by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr -G Ninja .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install

