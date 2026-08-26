#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Needs hyprutils, cairo, pango, libjpeg-turbo, libpng, libwebp, libjxl, librsvg (all already built).
set -e

cmake -B build -D CMAKE_INSTALL_PREFIX=/usr -D CMAKE_BUILD_TYPE=Release
cmake --build build
cmake --install build

