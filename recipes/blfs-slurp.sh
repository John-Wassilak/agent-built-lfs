#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. hyprshot's own dependency list names it ("to select what to
# screenshot"). Deps (cairo, wayland, libxkbcommon) all already built (libxkbcommon by
# BLFS itself, tier 8). man-pages is a meson `feature: auto` option that quietly no-ops
# without scdoc, not installed and not needed just for this. Version and sha256 match
# Arch's own PKGBUILD (slurp 1.5.0) byte for byte.
set -e

meson setup --prefix=/usr --buildtype=release . build
ninja -C build install

echo "### version"
slurp -h 2>&1 | head -1 || true
