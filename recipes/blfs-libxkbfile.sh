#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in this BLFS mirror, and not listed in xwayland.html's documented dependency list either -- discovered only via a real xwayland meson configure failure ('Dependency xkbfile not found'); its meson.build hard-requires it with no required:false guard, unlike the adjacent libbsd-overlay and xkbcomp checks in the same block, which are genuinely optional. Arch's official libxkbfile PKGBUILD as reference (meson-based, needs libx11 and xorgproto, both already built).
set -e

mkdir build && cd build
meson setup --prefix=/usr --buildtype=release .. &&
ninja
ninja install

