#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Region/window selector, needed by hyprshot --
# operator-requested alongside alacritty. Deps: cairo, wayland-client,
# wayland-cursor, wayland-protocols, xkbcommon (all already built).
set -e

meson setup --prefix=/usr --buildtype=release . build
ninja -C build
ninja -C build install

echo "### version"
slurp -h 2>&1 | head -1 || true
