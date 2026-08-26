#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Needed by Hyprland itself, depends on abseil-cpp (already built). Arch's official re2 PKGBUILD as reference -- source there is a git tag clone, used here as GitHub's equivalent tag-tarball instead.
set -e

cmake -B build -S . -W no-dev -D CMAKE_BUILD_TYPE=None -D CMAKE_INSTALL_PREFIX=/usr -D BUILD_SHARED_LIBS=ON
cmake --build build
cmake --install build

