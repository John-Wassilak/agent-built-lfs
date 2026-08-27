#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for dunst.
# source: github.com/dunst-project/dunst, tag v1.13.2.
# Rationale: X11 notification daemon, mako's replacement after
# abandoning Hyprland/Wayland (see AWESOME-X11-PLAN.md Phase 3).
# Required libXinerama (blfs-libxinerama.sh), the only real gap versus
# what was already built for the Hyprland/Wayland stack.
#
# Rebuilt 2026-08-27 with -D wayland=disabled. Real bug: dunst's own
# meson.build has a `wayland` feature option left on its default
# (auto) originally, which linked wayland-client/wayland-cursor as
# hard DT_NEEDED dependencies since wayland was present at build time
# -- same class of bug as gtk3/mpv/rofi, found the same way
# (system-wide `ldd | grep "not found"` sweep). Removing the wayland
# package that night left dunst unable to start at all on a fresh
# launch; the running session kept working only because its
# already-loaded copy doesn't need to re-resolve the dependency.
set -e

mkdir build
cd build

meson setup --prefix=/usr --buildtype=release -D wayland=disabled ..
ninja
ninja install
