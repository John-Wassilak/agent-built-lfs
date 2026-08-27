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
#
# Rebuilt 2026-08-26 with -D vdpau=enabled, as part of the X11/NVIDIA
# migration's real VDPAU verification (see BUILD-REPORT.md's Phase 4
# testing). This alone wasn't enough -- mpv's own vdpau.c/vo_vdpau.c
# call into FFmpeg's shared libavutil for the actual VDPAU device
# management (AVHWDeviceContext), and this system's ffmpeg was built
# without --enable-vdpau (see blfs-ffmpeg.sh's matching note). Confirmed
# working only after both were rebuilt.
#
# Rebuilt again 2026-08-27 with -D wayland=disabled. Real bug: this
# recipe never set the wayland option, so meson left it on its default
# (auto), which silently linked libwayland-client/cursor/egl as hard
# DT_NEEDED dependencies of both `mpv` and `libmpv.so` because wayland
# was present at build time (Hyprland era). Removing the wayland
# package that same night left both binaries unable to start at all --
# not caught immediately because the already-running mpv session (if
# any) keeps its old, already-loaded copy in memory. Caught by a
# system-wide `ldd | grep "not found"` sweep while verifying the
# Firefox build's live desktop.
set -e

mkdir build
cd build

meson setup --prefix=/usr \
  --buildtype=release \
  -D x11=enabled \
  -D vdpau=enabled \
  -D wayland=disabled \
  ..
ninja

ninja install

echo "### version"
mpv --version 2>&1 | head -1 || true
