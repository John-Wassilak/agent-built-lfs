#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Operator-requested terminal for use once
# Hyprland is up (SUPER+Return in the mirrored keybindings). Rust/Cargo
# project -- uses the toolchain already built in tier 6. All native deps
# (cmake, freetype2, fontconfig, libxcb, libxkbcommon) already present;
# confirmed against Alacritty's own INSTALL.md dependency list rather than
# guessed. desktop-file-install/update-desktop-database aren't installed
# -- plain cp for the desktop entry instead, matching this project's
# pattern of skipping optional validation/cache tools not otherwise
# needed. Man page skipped -- needs scdoc, not installed.
set -e

cargo build --release

install -v -m755 target/release/alacritty /usr/bin/alacritty

tic -xe alacritty,alacritty-direct extra/alacritty.info

install -v -m644 -D extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
install -v -m644 -D extra/linux/Alacritty.desktop /usr/share/applications/Alacritty.desktop

echo "### version"
alacritty --version 2>&1 || true
