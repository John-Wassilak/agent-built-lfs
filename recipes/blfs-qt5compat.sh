#!/bin/bash
# HAND-AUTHORED recipe -- BLFS has no page for an individual Qt module. Its x/qt6.html
# builds the whole qt-everywhere tarball in one step, and a host that trimmed that build
# has no book-derived way to add a module back.
#
# source: download.qt.io/archive/qt/6.10/6.10.2/submodules/qt5compat-everywhere-src-
# 6.10.2.tar.xz -- the per-module tarball Qt publishes alongside the 1.3 GB everywhere
# tarball, same release, same directory.
#
# provenance: md5 db6461a14b41fcbe0a3801d650a9e27c, matching the line for this file in
# md5sums.txt in that same submodules/ directory. sha256 of what was downloaded is
# 3fa418f0fac02eb9efc5f762fbe25f20647b0ebb7fa92faf07e6de85044161c2. Qt publishes no
# detached signature for the submodule tarballs, and md5sums.txt shares the tarball's
# TLS origin, so this is a same-origin integrity check rather than an independent trust
# path -- recorded as what it is. The version is pinned to the exact release the rest of
# this system's Qt was built from (6.10.2, x/qt6.html's own pin); a Qt module must match
# its qtbase, and nothing else would link.
#
# rationale: nextcloud-desktop (seq 333) needs this module twice over, both checked
# against the 34.0.3 source rather than its documentation:
#
#   Qt::Core5Compat   linked PUBLIC by libnextcloudsync (src/libsync/CMakeLists.txt's
#                     target_link_libraries). A build without it does not link.
#   Qt5Compat.GraphicalEffects
#                     imported by 12 QML files, among them src/gui/tray/MainWindow.qml
#                     and src/gui/tray/TrayFoldersMenuButton.qml -- i.e. the system-tray
#                     window itself. This one fails at *runtime*, not build time: the
#                     QML engine reports the module is not installed and the tray window
#                     never renders.
#
# Nothing in the qt6 build this host already has provides either. hosts/laptop/
# blfs-overrides.json trims x/qt6.html's build to 6 modules with 35 explicit `-skip`
# flags, and `-skip qt5compat` is one of them -- correctly, at the time: that trim was
# written for Quickshell/DankMaterialShell, which import none of this.
#
# The alternative was re-running seq 199 with two fewer `-skip` flags, which is a full
# rebuild of the everywhere tarball -- hours, and it re-links the Qt that the running
# desktop shell depends on. Operator decision (2026-09-12): build the module standalone
# instead. Qt supports this directly; see the build note below.
#
# Portable: names no device, no display, no GPU, no disk. The *reason* a host needs this
# step is host-specific and lives in that host's packages.py; the recipe is not. Shared
# per CLAUDE.md's shared/host test.
set -e

# $QT6DIR/bin/qt-cmake is Qt's own wrapper around cmake: it injects the toolchain file
# the installed Qt wrote at $QT6DIR/lib/cmake/Qt6/qt.toolchain.cmake, so the module is
# configured against exactly the qtbase that is installed rather than whatever cmake
# would find on its own. It is present here because x/qt6.html's `./configure -prefix
# $QT6PREFIX` installs it (confirmed: /opt/qt6/bin/qt-cmake exists).
#
# CMAKE_INSTALL_PREFIX is still given explicitly. qt-cmake defaults it to the Qt prefix,
# which is the value wanted, but a Qt module landing anywhere other than beside its own
# qtbase is silently broken and that is not a default worth trusting implicitly.
#
# QT_BUILD_TESTS/QT_BUILD_EXAMPLES are off: the examples in particular pull in modules
# this host does not have.
"$QT6DIR/bin/qt-cmake" -G Ninja -S . -B build \
      -D CMAKE_BUILD_TYPE=Release \
      -D CMAKE_INSTALL_PREFIX="$QT6DIR" \
      -D QT_BUILD_TESTS=OFF \
      -D QT_BUILD_EXAMPLES=OFF

# ninja does NOT read MAKEFLAGS -- it falls back to its own nproc+2 heuristic, which on
# this project's 4-thread host means 6 concurrent compiles. That was found live on
# 2026-09-04 during the qt6 build and is recorded in host.toml. Rather than hardcode a
# number into a shared recipe, parse the job count out of the MAKEFLAGS the driver
# exports and hand it to cmake's generator-agnostic --parallel.
JOBS=$(printf '%s' "${MAKEFLAGS:-}" | grep -oE '\-j ?[0-9]+' | grep -oE '[0-9]+' | head -1 || true)
: "${JOBS:=1}"
echo "### building with --parallel $JOBS (MAKEFLAGS=${MAKEFLAGS:-unset})"
cmake --build build --parallel "$JOBS"

cmake --install build

echo "### version"
ls -1 "$QT6DIR/lib/libQt6Core5Compat.so."* 2>/dev/null | head -1
echo "### QML module"
ls -d "$QT6DIR/qml/Qt5Compat/GraphicalEffects" 2>/dev/null \
  || ls -d "$QT6DIR/lib/qml/Qt5Compat/GraphicalEffects"
