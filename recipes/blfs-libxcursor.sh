#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in this BLFS mirror. Direct Hyprland dependency. Arch also lists 'default-cursors' (a cursor-theme meta-package) as a runtime dep -- not a build requirement, skipped; a cursor theme is a later, separate concern.
set -e

./configure $XORG_CONFIG
make
make install

