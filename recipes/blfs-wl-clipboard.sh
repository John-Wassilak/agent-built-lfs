#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Provides wl-copy/wl-paste -- operator-requested
# for clipboard history (cliphist's autostart lines watch these) and used
# directly by hyprshot. Only real dep is wayland-client (already built).
set -e

meson setup --prefix=/usr --buildtype=release . build
ninja -C build
ninja -C build install

echo "### version"
wl-copy --version 2>&1 || true
