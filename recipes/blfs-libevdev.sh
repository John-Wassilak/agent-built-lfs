#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Required by libinput. Arch's official libevdev PKGBUILD as reference. tests=disabled added after a real build failure: the option defaults to enabled and hard-requires the Check unit test framework, not installed.
set -e

mkdir build && cd build
meson setup --prefix=/usr --buildtype=release -D documentation=disabled -D tests=disabled .. &&
ninja
ninja install

