#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: There is no standalone libX11 page in either release -- but the package is
# NOT absent from the book, which is what this line used to claim. Both 13.0 and 13.1
# build it inside the GROUPED x7lib page's bulk loop, and 13.1's md5 list there pins
# libX11-1.8.13, which is exactly what this host's packages.py pins. Re-checked
# 2026-09-22. Same carve-out situation as blfs-libxt/libxmu/xauth: a grouped page has
# no per-package command block to extract, so this stays hand-authored rather than
# becoming book(). Required by libglvnd (Arch's libglvnd PKGBUILD makedepends) and Mesa's x11 platform support. Built per Arch's official libx11 PKGBUILD, using this project's $XORG_CONFIG rather than Arch's own flags -- same convention as every other Xorg lib already built (xorgproto, libXau, libXdmcp, etc).
set -e

./configure $XORG_CONFIG --disable-xf86bigfont &&
make
make install

