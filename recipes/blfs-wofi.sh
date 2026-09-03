#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. App launcher, operator-requested for the SUPER+D
# keybinding mirrored from the operator's real dotfiles. Bundles its own
# wlr-layer-shell protocol code (proto/) rather than depending on the
# separate gtk-layer-shell library -- confirmed by reading meson.build and
# grepping the source before assuming gtk-layer-shell was needed. Real
# deps: gtk+-3.0, wayland-client, gio-unix-2.0 (all already built).
set -e

meson setup --prefix=/usr --buildtype=release . build
ninja -C build
ninja -C build install

echo "### version"
wofi --version 2>&1 || true
