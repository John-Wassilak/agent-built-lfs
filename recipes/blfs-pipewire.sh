#!/bin/bash
# HAND-AUTHORED recipe from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/pipewire.html
# title  : pipewire-1.6.0
# rationale: Operator-requested, queued before Firefox. Built with just its
# core Recommended dep already present (PulseAudio, tier 11) -- the rest of
# the Recommended list (BlueZ, gstreamer, SBC, v4l-utils) is Bluetooth/video-
# capture/GStreamer integration this box has no current use for; skipped per
# the standing "verify it actually fits" policy rather than built
# reflexively. Wireplumber (its session manager) is the very next package in
# this same tier -- pipewire alone has no automatic device management.
# session-managers=[] because Wireplumber, not pipewire's old built-in
# media-session, is what actually gets configured.
set -e

mkdir build
cd build

meson setup .. \
  --prefix=/usr \
  --buildtype=release \
  -D session-managers="[]"
ninja

ninja install

echo "### pkg-config"
pkg-config --modversion libpipewire-0.3 2>&1 || true
