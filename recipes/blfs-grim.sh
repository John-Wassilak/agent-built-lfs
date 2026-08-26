#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Screenshot capture, needed by hyprshot --
# operator-requested alongside alacritty. Deps: libpng, libjpeg-turbo,
# pixman, wayland-client (all already built).
set -e

meson setup --prefix=/usr --buildtype=release . build
ninja -C build
ninja -C build install

echo "### version"
grim -h 2>&1 | head -1 || true
