#!/bin/bash
# HAND-AUTHORED recipe -- BLFS has no page for an individual Qt module; see the longer
# note in recipes/blfs-qt5compat.sh. Twin of recipes/blfs-qtwebsockets.sh.
#
# source: download.qt.io/archive/qt/6.10/6.10.2/submodules/qtwebchannel-everywhere-src-
# 6.10.2.tar.xz
#
# provenance: md5 b5eadb7599eb3682081985eb127b6098, matching md5sums.txt in that same
# submodules/ directory. sha256 of what was downloaded is
# e31ea59f8e19e0374d54fdc7a8479c840acffc4ba5297ee43564b5158a4f2c27. Same-origin check,
# no upstream signature. Pinned to 6.10.2 because a Qt module must match the qtbase it
# is built against.
#
# rationale: Mnemosyne closure (operator request, 2026-10-12), see blfs-mnemosyne.
# qtwebengine's dependencies.yaml lists qtwebchannel as optional; without it the
# webengine-webchannel feature (CONDITION TARGET Qt::WebChannel in
# src/core/api/configure.cmake) is off and QWebEnginePage has no webChannel API for
# PyQt6-WebEngine to bind. `-skip qtwebchannel` is one of the skips in laptop's qt6
# override. Must run before blfs-qtwebengine.
#
# Portable, shared per CLAUDE.md's shared/host test.
set -e

# See blfs-qt5compat.sh for why qt-cmake rather than plain cmake, and why
# CMAKE_INSTALL_PREFIX is written out rather than left to its (correct) default.
"$QT6DIR/bin/qt-cmake" -G Ninja -S . -B build \
      -D CMAKE_BUILD_TYPE=Release \
      -D CMAKE_INSTALL_PREFIX="$QT6DIR" \
      -D QT_BUILD_TESTS=OFF \
      -D QT_BUILD_EXAMPLES=OFF

# ninja ignores MAKEFLAGS; take the job count from it explicitly. See blfs-qt5compat.sh.
JOBS=$(printf '%s' "${MAKEFLAGS:-}" | grep -oE '\-j ?[0-9]+' | grep -oE '[0-9]+' | head -1 || true)
: "${JOBS:=1}"
echo "### building with --parallel $JOBS (MAKEFLAGS=${MAKEFLAGS:-unset})"
cmake --build build --parallel "$JOBS"

cmake --install build

echo "### version"
ls -1 "$QT6DIR/lib/libQt6WebChannel.so."* 2>/dev/null | head -1
