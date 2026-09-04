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

# Wait for systemd's own /run/user/$UID tmpfs before creating anything in there.
#
# This box has no PAM, so `loginctl enable-linger john` (2026-09-04) is what
# starts user@$UID.service at boot -- and that pulls in
# user-runtime-dir@$UID.service, whose whole job is to mount a fresh tmpfs at
# /run/user/$UID. If Hyprland wins that race it puts wayland-N, hypr/ and
# ssh-agent into the plain directory the tmpfiles rule made, systemd then mounts
# over the top, and every one of those sockets is invisible from that moment on.
# Hyprland itself keeps running on already-open fds, so nothing crashes and
# nothing logs -- but no new Wayland client can connect. That is exactly what
# happened when linger was enabled mid-session, and it presents as "alacritty
# and wofi won't open" with a perfectly healthy-looking compositor.
#
# In practice systemd wins by a mile (the user manager starts during boot, well
# before anyone finishes typing a password at the getty), so this loop normally
# exits on its first check. It only matters on a slow or unusual boot. Bounded at
# ~10s and non-fatal: if the mount never appears we carry on with the plain
# directory rather than refusing to start a desktop over it.
if [ -e "/var/lib/systemd/linger/$USER" ]; then
        for _ in $(seq 1 50); do
                mountpoint -q "$XDG_RUNTIME_DIR" && break
                sleep 0.2
        done
        mountpoint -q "$XDG_RUNTIME_DIR" ||
                echo "start-hyprland: warning: $XDG_RUNTIME_DIR is not a mountpoint;" \
                     "user-runtime-dir@$(id -u).service may mount over it later and" \
                     "hide this session's sockets" >&2
fi

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
