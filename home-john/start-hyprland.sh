#!/bin/bash
# Standard way to start Hyprland from a physical console login (no display
# manager). Run this after logging in on a real VT -- it will not work over
# SSH: Hyprland needs to become DRM master of a real seat/VT with a
# monitor attached, and an SSH session's pty has no VT association at all
# for seatd/aquamarine to take over.
#
# XDG_RUNTIME_DIR is normally created by pam_systemd on login; this system
# has no PAM, so a static systemd-tmpfiles.d rule
# (/etc/tmpfiles.d/xdg-runtime-john.conf) creates /run/user/1000 at every
# boot instead. /etc/profile's own book-documented fallback
# (XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/xdg-$USER}) already runs by the
# time this script does and sets it first -- since it's never pre-set by
# anything, that fallback always wins, pointing at a /tmp/xdg-john that
# nothing ever creates. Force the real value here rather than deferring to
# whatever's already set.
set -e

export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=Hyprland

LOG="$HOME/hyprland.log"
[ -f "$LOG" ] && mv -f "$LOG" "$LOG.old"

exec Hyprland > "$LOG" 2>&1
