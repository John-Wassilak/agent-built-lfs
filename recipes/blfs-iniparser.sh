#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Undocumented hard dependency of hyprtoolkit -- discovered via a real CMake configure failure ('required packages were not found: iniparser'), not mentioned in any Hyprland-ecosystem PKGBUILD's depends array since Arch's hyprtoolkit package itself doesn't declare it explicitly either (a transitive pkg-config probe, not a packaging-level dependency). Arch's official iniparser PKGBUILD as reference -- BUILD_STATIC_LIBS=false matches Arch's own build() flags.
set -e

cmake -S . -B build -D CMAKE_INSTALL_PREFIX=/usr -D BUILD_STATIC_LIBS=false
cmake --build build
cmake --install build

