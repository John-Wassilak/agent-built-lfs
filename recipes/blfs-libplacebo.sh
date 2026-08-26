#!/bin/bash
# HAND-AUTHORED recipe from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/libplacebo.html
# title  : libplacebo-7.360.0
# rationale: Required by mpv (tier 14), optional HDR/color-space dep for ffmpeg
# (tier 13, not enabled there -- ffmpeg's book recipe doesn't flag it on by
# default and this project follows the book's documented command as-is).
# Required: Glad (built just before this in the same batch). Recommended:
# Glslang, Vulkan-Loader (both already built, tier 1/4).
set -e

mkdir build
cd build

meson setup .. \
  --prefix=/usr \
  --buildtype=release \
  -D tests=true \
  -D demos=false
ninja

ninja install

echo "### pkg-config"
pkg-config --modversion libplacebo 2>&1 || true
