#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for clipnotify.
# source: github.com/cdown/clipnotify, tag 1.0.2.
# Rationale: clipmenu dependency (see AWESOME-X11-PLAN.md Phase 3).
# Trivial single-file build, no configure/install target of its own.
set -e

make
install -m755 clipnotify /usr/bin/clipnotify
