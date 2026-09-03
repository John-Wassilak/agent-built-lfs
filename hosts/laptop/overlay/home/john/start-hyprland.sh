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

# Correction 2026-09-03: this host's mesa actually has glvnd=enabled
# (hosts/laptop/blfs-overrides.json's blfs-mesa override -- reversed
# 2026-08-31 from an earlier glvnd=disabled call, once aquamarine's
# CMakeLists turned out to hard-require the GLVND-specific OpenGL::OpenGL
# CMake target). A start-hyprland.sh comment written earlier the same day
# claimed glvnd=disabled here -- wrong, fixed. Since libglvnd is real and
# active, the same GLX vendor gap server's own start-hyprland.sh documents
# applies here too, for any GLX-based (not GLES/EGL) app run through
# XWayland: XWayland doesn't implement the GLX_EXT_libglvnd server
# extension libGLX.so normally uses to pick a vendor per X screen, so
# without this it fails closed. "mesa" is the vendor name Mesa registers
# itself under (libGLX_mesa.so.0).
export __GLX_VENDOR_LIBRARY_NAME=mesa

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
