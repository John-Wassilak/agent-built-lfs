#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for KDSingleApplication (grepped the whole
# book tree, zero hits). It is a KDAB library, unrelated to KDE Frameworks despite the
# initials.
#
# source: github.com/KDAB/KDSingleApplication, release v1.2.1 (2026-04-22) -- the
# project's own release asset kdsingleapplication-1.2.1.tar.gz, not a tag archive.
#
# provenance: sha256 e3254ce9dc5ecf6d61ef83264bc61d486a307f0e3c9ed1bb2176f068cdbcbe09,
# and the detached signature kdsingleapplication-1.2.1.tar.gz.asc published beside it
# verifies GOOD against RSA key E86C000370B1B9E2A9191AD53DBFB6882C9358FB, uid "KDAB
# Products (user for KDAB products) <info@kdab.com>". The key came from
# keys.openpgp.org by fingerprint -- a different origin from the tarball, so this is an
# independent trust path rather than a same-origin checksum.
#
# rationale: nextcloud-desktop (seq 333) does `find_package(KDSingleApplication-qt6
# REQUIRED)` at the top level of its CMakeLists.txt, and src/gui/application.cpp
# connects to KDSingleApplication::messageReceived. It is what makes a second launch of
# the client hand its arguments to the already-running instance and exit, instead of
# starting a second tray icon and a second sync engine over the same directories. There
# is no cmake option to build without it.
#
# Deliberately NOT a dependency on system ECM: this tarball vendors the four Extra CMake
# Modules it uses under cmake/ECM/modules (ECMGeneratePriFile, ECMSetupVersion,
# ECMGenerateHeaders, ECMQueryQt), so it configures whether or not seq 328 has run. The
# seq order below still puts it after ECM, because nothing is gained by the two being
# independent and a reader should not have to check.
#
# Portable: names no device, no display, no GPU, no disk. Shared per CLAUDE.md's
# shared/host test.
set -e

# Every option stated explicitly, since two of the upstream defaults are wrong for a
# system install (the header comment at the top of the tarball's own CMakeLists.txt is
# the authority for each default named here):
#
#   KDSingleApplication_QT6=ON       upstream default is already ON. Left explicit
#                                    because OFF would silently build against Qt5,
#                                    which does not exist on this system, and because
#                                    the package nextcloud asks for is specifically
#                                    named "KDSingleApplication-qt6".
#   KDSingleApplication_EXAMPLES=OFF upstream default is ON. Builds two demo GUI
#                                    programs that are not installed but do cost build
#                                    time and pull in Qt Widgets examples.
#   KDSingleApplication_TESTS=OFF    already the default; stated so a reader does not
#                                    have to check.
#   KDSingleApplication_STATIC=OFF   already the default. ON would produce a static
#                                    library that nextcloud would link in, making a
#                                    future security fix here require rebuilding the
#                                    client rather than just this package.
#
# CMAKE_INSTALL_LIBDIR is not passed: this system has no /usr/lib64 and cmake's
# GNUInstallDirs resolves LIBDIR to plain `lib` here, confirmed by the existing
# /usr/lib/libsdbus-c++.so.2 from seq 317's identically-shaped build.
cmake -B build -S . \
      -D CMAKE_BUILD_TYPE=Release \
      -D CMAKE_INSTALL_PREFIX=/usr \
      -D KDSingleApplication_QT6=ON \
      -D KDSingleApplication_EXAMPLES=OFF \
      -D KDSingleApplication_TESTS=OFF \
      -D KDSingleApplication_STATIC=OFF

JOBS=$(printf '%s' "${MAKEFLAGS:-}" | grep -oE '\-j ?[0-9]+' | grep -oE '[0-9]+' | head -1 || true)
: "${JOBS:=1}"
cmake --build build --parallel "$JOBS"

cmake --install build
ldconfig

echo "### version"
ls -1 /usr/lib/libkdsingleapplication-qt6.so.* 2>/dev/null | head -2
echo "### cmake package"
ls -d /usr/lib/cmake/KDSingleApplication-qt6
