#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in this BLFS mirror. Direct Hyprland dependency (confirmed in Arch's official hyprland PKGBUILD depends array: 'libxrender'), not just an XWayland transitive dep.
set -e

./configure $XORG_CONFIG
make
make install

