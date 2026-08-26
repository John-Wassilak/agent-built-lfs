#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Needed by hyprwire. Arch's official pugixml PKGBUILD as reference.
set -e

cmake -B build -S . -W no-dev -D CMAKE_BUILD_TYPE=None -D BUILD_SHARED_LIBS=ON -D CMAKE_INSTALL_PREFIX=/usr
cmake --build build
cmake --install build

