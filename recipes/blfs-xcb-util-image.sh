#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in this BLFS mirror. Direct Hyprland dependency, needs xcb-util (already built).
set -e

./configure --prefix=/usr --disable-static
make
make install

