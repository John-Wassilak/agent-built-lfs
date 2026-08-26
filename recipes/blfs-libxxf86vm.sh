#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in this BLFS mirror. Discovered when mesa's meson configure failed: 'Dependency xxf86vm not found' -- the X11 platform's video-mode-switching support. Arch's official libxxf86vm PKGBUILD as reference.
set -e

./configure $XORG_CONFIG
make
make install

