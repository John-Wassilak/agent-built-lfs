#!/bin/bash
# HAND-AUTHORED recipe -- host-specific fork of the shared recipes/blfs-pipewire.sh.
# source : book/blfs-13.0/multimedia/pipewire.html
# title  : pipewire-1.6.0
#
# Forked 2026-09-09: the shared recipe's `-D bluez5=enabled` (added 2026-09-04,
# "operator-requested Bluetooth audio" per that file's own header) is laptop-specific --
# laptop built bluez/sbc ahead of pipewire (its own packages.py seq 130.1-130.3)
# specifically to satisfy it. This box was already decided the opposite way, earlier and
# separately (BUILD-REPORT.md, 2026-08-26: pipewire "built without the optional BlueZ/
# gstreamer/v4l-utils chain, none of which this box has a current use for") -- server has
# never built bluez/sbc at all, so `enabled` (a hard requirement, by design, per the
# shared file's own long comment on why `auto` would silently drop support instead) hits
# a real configure failure here: "Dependency 'bluez' not found". `disabled` matches this
# box's actual, already-documented decision; the ALSA half (`-D alsa=enabled`, needed by
# both hosts) is unchanged.
set -e

mkdir build
cd build

meson setup .. \
  --prefix=/usr \
  --buildtype=release \
  -D session-managers="[]" \
  -D alsa=enabled \
  -D bluez5=disabled
ninja

ninja install

echo "### pkg-config"
pkg-config --modversion libpipewire-0.3 2>&1 || true
