#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. First of the Hyprland-ecosystem packages (all confirmed in Arch's official 'extra' repo, none in AUR, same pattern as htop) -- generates Wayland protocol bindings, needed to build aquamarine and Hyprland itself.
set -e

cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build
cmake --build build
cmake --install build

