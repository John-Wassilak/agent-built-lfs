#!/bin/bash
# Standard way to start Hyprland from a physical console login (no display
# manager, by design -- see hosts/laptop/CLAUDE.md). Companion to server's
# overlay/home/john/start-awesome.sh, same log-redirection pattern.
#
# XDG_RUNTIME_DIR is normally created by pam_systemd at login; this box has
# no PAM either (same gap server hit). systemd's own tmpfiles rule only
# creates /run/user itself (0755 root root), not the per-uid subdirectory --
# fixed with a static /etc/tmpfiles.d/xdg-runtime-john.conf
# (`d /run/user/1000 0700 john john -`), applied 2026-09-03. Force the real
# value here rather than trusting /etc/profile's own fallback
# (recipes/blfs-shell-startup-files.sh: XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/xdg-$USER}),
# which already ran by the time this script does.
set -e

export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=Hyprland

# No __GLX_VENDOR_LIBRARY_NAME override needed here, unlike server's
# abandoned Hyprland attempt on nouveau/NVIDIA: this host's mesa was built
# with glvnd=disabled (hosts/laptop/blfs-overrides.json) -- iris is the
# only GPU vendor present, so there is nothing for libglvnd to dispatch
# between and no GLX_EXT_libglvnd query to fail under XWayland.

LOG="$HOME/hyprland.log"
[ -f "$LOG" ] && mv -f "$LOG" "$LOG.old"

mkdir -p "$HOME/screens"

# start-hyprland is Hyprland's own watchdog binary (installed by the
# Hyprland package itself) -- launching the bare Hyprland binary directly
# prints "WARNING: Hyprland is being launched without start-hyprland. This
# is highly advised against." Config lives at the default
# ~/.config/hypr/hyprland.conf (symlinked to ~/Config, this user's separate
# dotfiles repo -- not part of agent-built-lfs), so nothing extra needed
# after `--`.
exec start-hyprland > "$LOG" 2>&1
