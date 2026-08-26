#!/bin/bash
# Standard way to start Hyprland from a physical console login (no display
# manager). Run this after logging in on a real VT -- it will not work over
# SSH (no local seat/DRM master to hand off).
#
# XDG_RUNTIME_DIR is normally created by pam_systemd on login; this system
# has no PAM, so a static systemd-tmpfiles.d rule
# (/etc/tmpfiles.d/xdg-runtime-john.conf) creates /run/user/1000 at every
# boot instead. Set here too as a defensive fallback in case that rule is
# ever missing.
set -e

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=Hyprland

exec Hyprland
