#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Header-mostly JSON library, needed by Hyprland's own build.
set -e

cmake -B build -D CMAKE_INSTALL_PREFIX=/usr -D BUILD_TESTING=OFF -D CMAKE_BUILD_TYPE=Release
cmake --build build
cmake --install build

