#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in this BLFS mirror. Direct Hyprland dependency.
set -e

./configure $XORG_CONFIG
make
make install

