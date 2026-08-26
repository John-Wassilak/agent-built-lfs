#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Needed by hyprcursor (cursor theme archives are zip files). Arch's official libzip PKGBUILD as reference; built against whatever of its optional compression backends (zlib, bzip2, zstd, openssl) are actually present -- cmake auto-detects and skips the rest, same pattern used throughout this build.
set -e

cmake -B build -S . -D CMAKE_BUILD_TYPE=None -D CMAKE_INSTALL_PREFIX=/usr -Wno-dev
cmake --build build
cmake --install build

