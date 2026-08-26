#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. XWayland's embedded X server needs it to compile
# the X11 keymap for its virtual keyboard -- discovered via a real failure
# testing Hyprland: "sh: /usr/bin/xkbcomp: No such file or directory",
# "XKB: Failed to compile keymap", "Fatal server error: Failed to activate
# virtual core keyboard". Needs: x11, xkbfile (libxkbfile, tier 9), xproto
# (xorgproto) -- all already built.
set -e

meson setup --prefix=/usr --buildtype=release . build
ninja -C build
ninja -C build install

echo "### version"
xkbcomp -version 2>&1 || true
