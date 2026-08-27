#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for redshift.
# source: github.com/jonls/redshift, release v1.12.
# Rationale: X11 blue-light filter, wlsunset's replacement after
# abandoning Hyprland/Wayland (see AWESOME-X11-PLAN.md Phase 3).
# --disable-gui/--disable-geoclue2/--disable-drm: no GTK tray icon or
# automatic geolocation wanted (matches wlsunset's original config,
# which used a fixed lat/long); DRM adjustment method is the Wayland
# path, irrelevant now. --enable-randr/--enable-vidmode: the two X11
# gamma-adjustment methods actually usable here.
set -e

./configure --prefix=/usr --disable-geoclue2 --disable-gui --disable-drm --enable-randr --enable-vidmode
make
make install
