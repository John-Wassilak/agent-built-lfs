#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for xsel.
# source: github.com/kfish/xsel (current maintained home; the original
#   vergenet.net site is dead), tag 1.2.1.
# Rationale: clipmenu dependency (see AWESOME-X11-PLAN.md Phase 3).
set -e

autoreconf -fi
./configure --prefix=/usr
make
make install
