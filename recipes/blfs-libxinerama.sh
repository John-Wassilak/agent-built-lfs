#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for libXinerama.
# source: x.org individual release, libXinerama-1.1.5.
# Rationale: dunst dependency (see AWESOME-X11-PLAN.md Phase 3).
set -e

./configure $XORG_CONFIG
make
make install
