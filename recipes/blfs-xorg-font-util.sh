#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in this BLFS mirror as its own page. xwayland.html lists it as a Required dependency ('Xorg Fonts (only font-util)'). Arch's official xorg-font-util PKGBUILD as reference.
set -e

./configure $XORG_CONFIG
make
make install

