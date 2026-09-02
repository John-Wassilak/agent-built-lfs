#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Needs pixman (already built). Foundation library for the rest of the Hyprland ecosystem.
set -e

cmake -W no-dev -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/usr -D BUILD_TESTING=False -S . -B build
cmake --build build
cmake --install build

