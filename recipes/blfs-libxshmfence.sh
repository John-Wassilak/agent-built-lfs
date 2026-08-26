#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in this BLFS mirror. Discovered when mesa's meson configure failed: 'Dependency xshmfence not found' -- needed for DRI3 support on the x11 platform. Arch's official libxshmfence PKGBUILD as reference.
set -e

./configure $XORG_CONFIG
make
make install

