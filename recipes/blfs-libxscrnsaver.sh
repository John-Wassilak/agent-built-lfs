#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in this BLFS mirror. SDL3's cmake hard-requires it (X11 Screen Saver extension) when X11 support is enabled -- discovered via a real configure failure ('Couldn't find dependency package for XSCRNSAVER'), not mentioned in SDL3's book page (which only lists the generic Xorg Libraries as part of Recommended). Arch's official libxss PKGBUILD as reference -- needs libxext, libx11, xorgproto (all already built).
set -e

./configure $XORG_CONFIG --sysconfdir=/etc
make
make install

