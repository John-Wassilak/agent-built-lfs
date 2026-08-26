#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Provides libseat, the session/seat abstraction aquamarine (Hyprland's backend layer) needs -- backed by this system's existing systemd-logind rather than the standalone seatd daemon (libseat-logind=systemd, server=disabled: no separate daemon needed when logind is already present). Arch's official seatd PKGBUILD as reference.
set -e

mkdir build
meson setup --prefix=/usr --buildtype=release \
      -D libseat-logind=systemd \
      -D server=disabled \
      -D man-pages=disabled \
      . build &&
ninja -C build
ninja -C build install

