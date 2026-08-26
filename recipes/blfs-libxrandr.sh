#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in this BLFS mirror. Discovered when vulkan-loader's cmake configure failed: 'required packages were not found: xrandr' -- vulkan-loader's X11 WSI backend needs the RandR extension library to enumerate displays. Needs libxext, libxrender, libx11 (all already built). Arch's official libxrandr PKGBUILD as reference.
set -e

./configure $XORG_CONFIG
make
make install

