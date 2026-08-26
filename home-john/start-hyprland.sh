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

# GLX vendor selection (for XWayland/X11 apps) is NOT file-based like EGL's
# vendor.d JSONs -- libglvnd's libGLX.so normally queries the X server per
# screen via the GLX_EXT_libglvnd server extension. XWayland doesn't
# implement that extension, so without this the query fails and any GLX
# call falls through with no vendor loaded. __GLX_VENDOR_LIBRARY_NAME is
# libglvnd's documented fallback for exactly this case -- checked once at
# libGLX.so init time, no config file involved. "mesa" matches the vendor
# name Mesa registered itself under (libGLX_mesa.so.0, same name as the
# EGL vendor's 50_mesa.json).
export __GLX_VENDOR_LIBRARY_NAME=mesa

LOG="$HOME/hyprland.log"
[ -f "$LOG" ] && mv -f "$LOG" "$LOG.old"

# start-hyprland is Hyprland's own watchdog binary (installed by the
# Hyprland package itself, tier 10) -- launching the bare Hyprland binary
# directly, as this script originally did, prints "WARNING: Hyprland is
# being launched without start-hyprland. This is highly advised against."
# at startup. start-hyprland forwards anything after `--` to Hyprland
# itself; nothing extra needed here since our config lives at the default
# ~/.config/hypr/hyprland.lua location.
exec start-hyprland > "$LOG" 2>&1
