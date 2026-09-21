#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/libplacebo.html
# title  : libplacebo-7.360.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 20426294cdb752b0bc0 Download size: 844 KB Estimated disk space required: 46 MB Estimated
#   ctx: build time: 0.1 SBU (With tests, both using parallelism=4) libplacebo Dependencies
#   ctx: Required Glad-2.0.8 Recommended Glslang-16.2.0 and Vulkan-Loader-1.4.341.0 Optional
#   ctx: Little CMS-2.18 libunwind-1.8.3, dovi_tool, Nuklear, and xxHash Installation of
#   ctx: libplacebo Install libplacebo by running the following commands:
mkdir build &&
cd    build &&

meson setup ..            \
      --prefix=/usr       \
      --buildtype=release \
      -D tests=true       \
      -D demos=false      &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install

