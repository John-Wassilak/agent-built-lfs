#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Provides libseat, the session/seat abstraction
# aquamarine (Hyprland's backend layer) needs. Originally built
# logind-only (server=disabled), on the assumption systemd-logind was
# sufficient -- wrong: this system has no PAM installed at all, so
# systemd-logind never learns a session exists (confirmed via `loginctl
# list-sessions` showing zero, always, including from an active SSH
# login) and libseat's logind backend has nothing to attach to. Rebuilt
# 2026-08-26 with the standalone seatd server enabled -- it depends only
# on libc, not PAM, which is exactly the case this project's earlier
# "logind is already present" reasoning didn't account for. Both backends
# stay compiled into libseat (auto-detected at runtime, seatd first via
# contrib/systemd/seatd.service's `-g seat` socket-group grant) so a
# future PAM install wouldn't need yet another rebuild. Arch's official
# seatd PKGBUILD as reference.
set -e

mkdir build
meson setup --prefix=/usr --buildtype=release \
      -D libseat-logind=systemd \
      -D libseat-seatd=enabled \
      -D server=enabled \
      -D man-pages=disabled \
      . build &&
ninja -C build
ninja -C build install

install -v -m644 -D contrib/systemd/seatd.service \
  /usr/lib/systemd/system/seatd.service

# `-g seat` in the unit above grants socket access to this group, not to
# individual users -- create it and enroll the desktop-using accounts.
# video/input are the classic device-group fallback (harmless alongside
# seatd; some tools still probe them directly).
getent group seat >/dev/null || groupadd -r seat
usermod -aG video,input,seat john

systemctl daemon-reload
systemctl enable --now seatd

