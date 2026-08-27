#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Originally noted as "needed by hyprcursor" and
# removed along with the rest of the Hyprland chain on 2026-08-27 -- that
# was wrong. ImageMagick (kept, used throughout this project for
# screenshots via `import`, wired into rc.lua's keybindings) is also
# linked against libzip.so.5 for its own zip-based format coders,
# independent of hyprcursor. Removing it broke `import`/`convert`/`magick`
# outright (unresolved libzip.so.5 at runtime), caught immediately while
# testing the Firefox build's live desktop -- rebuilt the same night.
# Arch's official libzip PKGBUILD as reference; built against whatever of
# its optional compression backends (zlib, bzip2, zstd, openssl) are
# actually present -- cmake auto-detects and skips the rest, same pattern
# used throughout this build.
set -e

cmake -B build -S . -D CMAKE_BUILD_TYPE=None -D CMAKE_INSTALL_PREFIX=/usr -Wno-dev
cmake --build build
cmake --install build
