#!/bin/bash
# HAND-AUTHORED recipe -- built alone rather than through BLFS's frameworks6 page.
# rationale: fcitx5-config-qt (blfs-fcitx5-configtool) needs exactly two KDE
# Frameworks, KF6ItemViews and KF6WidgetsAddons, both tier 1 (Qt6 and ECM only). The
# book's frameworks6 page builds the whole ~70-framework set in one loop, which would
# pull in far more than this needs. Same version as the book (6.23.0, matching the
# installed extra-cmake-modules) and the same cmake options as that page's loop.
# Vietnamese input closure (operator request, 2026-10-21), see blfs-fcitx5.
# source: download.kde.org/stable/frameworks/6.23/kitemviews-6.23.0.tar.xz, md5 matching
# the one BLFS 13.0's frameworks6 page lists.
set -e

cmake -B build -D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_INSTALL_LIBEXECDIR=libexec \
      -D CMAKE_PREFIX_PATH=/opt/qt6       \
      -D CMAKE_SKIP_INSTALL_RPATH=ON      \
      -D CMAKE_BUILD_TYPE=Release         \
      -D BUILD_TESTING=OFF                \
      -D BUILD_PYTHON_BINDINGS=OFF        \
      -W no-dev
cmake --build build
cmake --install build
