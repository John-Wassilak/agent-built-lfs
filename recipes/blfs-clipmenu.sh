#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for clipmenu.
# source: github.com/cdown/clipmenu, tag 6.2.0.
# Rationale: X11 clipboard history, cliphist's replacement after
# abandoning Hyprland/Wayland (see AWESOME-X11-PLAN.md Phase 3).
# Shell-script tool; hard deps xsel/clipnotify built first
# (blfs-xsel.sh, blfs-clipnotify.sh). dmenu itself deliberately not
# built -- rofi (already installed) covers the launcher role via
# CM_LAUNCHER=rofi in the environment, avoiding a second launcher
# implementation for the same job.
set -e

make install
