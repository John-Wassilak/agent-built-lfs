#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Needs hyprlang, hyprtoolkit, hyprutils, libdrm, pixman.
set -e

cmake -B build -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/usr
cmake --build build
cmake --install build

