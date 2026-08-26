#!/bin/bash
# HAND-AUTHORED recipe from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/mpv.html
# title  : mpv-0.41.0
# rationale: Required: alsa-lib, FFmpeg, libass, libplacebo, Mesa, PulseAudio
# (all already built by this point in tier 13/prior tiers). Recommended:
# libjpeg-turbo, libva, luajit, uchardet (all already built), Vulkan-Loader
# (tier 4). desktop-file-utils/GTK3 icon-cache update step skipped -- this is
# an SSH-driven headless build, no interactive desktop session to benefit
# from it, matching this project's standing policy of not installing
# Recommended conveniences that don't fit a headless server.
set -e

mkdir build
cd build

meson setup --prefix=/usr \
  --buildtype=release \
  -D x11=enabled \
  ..
ninja

ninja install

echo "### version"
mpv --version 2>&1 | head -1 || true
