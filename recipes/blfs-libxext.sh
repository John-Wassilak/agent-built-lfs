#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Same situation as blfs-libx11 -- not in this BLFS mirror, required by libglvnd and Mesa's x11 platform. Arch's libxext PKGBUILD as reference.
set -e

./configure $XORG_CONFIG &&
make
make install

