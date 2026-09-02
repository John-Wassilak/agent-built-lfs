#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Wayland protocol definitions for the Hyprland ecosystem, meson-only, no other deps.
set -e

meson setup --prefix=/usr --buildtype=release build .
ninja -C build
ninja -C build install

