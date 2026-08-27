#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for xdotool.
# source: github.com/jordansissel/xdotool, tag v4.20260303.1.
# Rationale: clipmenu dependency (see AWESOME-X11-PLAN.md Phase 3).
set -e

make
make install PREFIX=/usr
