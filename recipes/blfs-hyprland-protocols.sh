#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Wayland protocol definitions for the Hyprland ecosystem, no
# compiled code and no deps beyond the build tool.
#
# Build system changed at 0.8.0 (2026-10-16): upstream dropped meson.build and ships a
# CMakeLists.txt instead, so the old `meson setup` line fails before doing anything
# ("Neither source directory 'build' nor build directory '.' contain a build file
# meson.build", laptop, 2026-11-18). The CMake build installs the same things to the
# same places: the protocol XMLs under /usr/share/hyprland-protocols/protocols and
# hyprland-protocols.pc under /usr/share/pkgconfig. The command line follows Arch's
# 0.8.0 PKGBUILD. 0.8.0 is needed by xdg-desktop-portal-hyprland 1.5.0 for
# hyprland-workspace-image-capture-source-v1.xml.
set -e

cmake -B build -S . -W no-author \
      -D CMAKE_BUILD_TYPE=None \
      -D CMAKE_INSTALL_PREFIX=/usr
cmake --build build
cmake --install build
