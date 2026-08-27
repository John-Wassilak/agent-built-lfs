#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for rofi.
# source: github.com/davatorium/rofi, tag 2.0.0.
# Rationale: X11 launcher, wofi's replacement after abandoning
# Hyprland/Wayland (see AWESOME-X11-PLAN.md Phase 3).
#
# Real gap: rofi's meson.build calls subproject('libgwater') and
# subproject('libnkutils') -- both real git submodules, not included
# in GitHub's auto-generated tarball archive (submodules never are).
# Cloned both directly into subprojects/ from their actual upstream
# repos (found via .gitmodules, fetched separately since that file is
# also submodule-adjacent metadata GitHub's tarball omits) rather than
# doing a full git clone of rofi itself.
#
# -D imdkit=false: xcb-imdkit (CJK/IME input method support) isn't
# built on this system and is a genuinely optional meson feature here
# (meson.build: dependency(..., required: false)) -- not needed for
# this use case.
#
# Rebuilt 2026-08-27 with -D wayland=disabled. Real bug: rofi's own
# meson.build has a `wayland` feature option left on its default
# (auto) originally, which linked wayland-client/wayland-cursor as
# hard DT_NEEDED dependencies (plus libgwater's wayland variant) since
# wayland was present at build time. Same class of bug as gtk3's and
# mpv's, found the same way (system-wide `ldd | grep "not found"`
# sweep) -- removing the wayland package that night left rofi unable
# to start at all on a fresh launch.
set -e

rm -rf subprojects/libgwater subprojects/libnkutils
git clone --depth 1 https://github.com/sardemff7/libgwater subprojects/libgwater
git clone --depth 1 https://github.com/sardemff7/libnkutils subprojects/libnkutils

mkdir build
cd build

meson setup --prefix=/usr --buildtype=release -D imdkit=false -D check=disabled -D wayland=disabled ..
ninja
ninja install
