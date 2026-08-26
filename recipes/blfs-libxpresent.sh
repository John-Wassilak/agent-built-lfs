#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in this BLFS mirror. mpv's meson.build hard-requires it (X11
# Present extension, used for tear-free presentation) -- discovered via a real
# configure failure ('Dependency "xpresent" not found'), not mentioned in
# mpv's book page at all (which only lists the generic Xorg Libraries as part
# of Recommended, same class of gap as libxscrnsaver for SDL3). Arch's
# official libxpresent PKGBUILD as reference -- needs libxext, libxfixes,
# libxrandr, libx11, xorgproto (all already built).
set -e

./configure $XORG_CONFIG
make
make install
