#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. The wlroots-successor rendering/backend layer Hyprland is built on -- needs hyprutils, hyprwayland-scanner, libdrm, libdisplay-info, libinput, libseat (from seatd), mesa, pixman, wayland, wayland-protocols (all already built).
set -e

cmake -B build -D CMAKE_INSTALL_PREFIX=/usr -D CMAKE_BUILD_TYPE=Release
cmake --build build
cmake --install build

