#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in this BLFS mirror. Required by libXtst below (found via a real at-spi2-core meson failure: 'Dependency xtst not found' -- at-spi2-core's book page only lists the generic 'Xorg Libraries', not this specific transitive chain). Arch's official libxi PKGBUILD as reference -- needs libxext, libxfixes, libx11, xorgproto (all already built).
set -e

./configure $XORG_CONFIG --sysconfdir=/etc
make
make install

