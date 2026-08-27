#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for dunst.
# source: github.com/dunst-project/dunst, tag v1.13.2.
# Rationale: X11 notification daemon, mako's replacement after
# abandoning Hyprland/Wayland (see AWESOME-X11-PLAN.md Phase 3).
# Required libXinerama (blfs-libxinerama.sh), the only real gap versus
# what was already built for the Hyprland/Wayland stack.
set -e

mkdir build
cd build

meson setup --prefix=/usr --buildtype=release ..
ninja
ninja install
