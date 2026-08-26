#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in this BLFS mirror at all (confirmed: no libX11.html anywhere under book/blfs-13.0). Required by libglvnd (Arch's libglvnd PKGBUILD makedepends) and Mesa's x11 platform support. Built per Arch's official libx11 PKGBUILD, using this project's $XORG_CONFIG rather than Arch's own flags -- same convention as every other Xorg lib already built (xorgproto, libXau, libXdmcp, etc).
set -e

./configure $XORG_CONFIG --disable-xf86bigfont &&
make
make install

