#!/bin/bash
# HAND-AUTHORED recipe -- BLFS has no page for an individual Qt module; see the longer
# note in recipes/blfs-qt5compat.sh, which this step is the twin of.
#
# source: download.qt.io/archive/qt/6.10/6.10.2/submodules/qtwebsockets-everywhere-src-
# 6.10.2.tar.xz
#
# provenance: md5 9bdd750ea2aef59df559b7d2c3d6683a, matching md5sums.txt in that same
# submodules/ directory. sha256 of what was downloaded is
# eccc751bea509ef656d20029693987a0fc03c58e21c38f1351480f3c8eb42ebd. Same-origin check,
# no upstream signature -- recorded as what it is. Pinned to 6.10.2 because a Qt module
# must match the qtbase it is built against.
#
# rationale: nextcloud-desktop (seq 333) links Qt::WebSockets PUBLIC into
# libnextcloudsync (src/libsync/CMakeLists.txt), and its find_package line is
# `find_package(Qt6 REQUIRED COMPONENTS WebSockets Xml Sql Gui Svg Widgets)` -- REQUIRED,
# so the build does not even configure without it. It is what the client uses to hold an
# open notify_push channel to the server instead of polling. `-skip qtwebsockets` is one
# of the 35 skips in this host's qt6 override.
#
# 447 KB of source and a handful of translation units -- this is the cheapest of the
# three new Qt-side steps by a wide margin.
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
ls -1 "$QT6DIR/lib/libQt6WebSockets.so."* 2>/dev/null | head -1
