#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/multimedia/libplacebo.html
# title  : libplacebo-7.360.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: d MD5 sum: e0fa1b52f8d7b7ba51373e9a639ca966 Download size: 844 KB Estimated disk space
#   ctx: required: 38 MB Estimated build time: 0.2 SBU (With tests) libplacebo Dependencies
#   ctx: Required Glad-2.0.8 Recommended Glslang-16.5.0 and Vulkan-Loader-1.4.357.0 Optional
#   ctx: Little CMS-2.19.1 libunwind-1.8.3, dovi_tool, Nuklear, and xxHash Installation of
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

