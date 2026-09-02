#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Needed by hyprlang and hyprcursor. Arch's official tomlplusplus PKGBUILD as reference (meson-based).
set -e

meson setup --prefix=/usr --buildtype=release build .
ninja -C build
ninja -C build install

