#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this package.
# rationale: Qt6 platform input context plugin, plus the Fcitx5Qt6DBusAddons and
# WidgetsAddons libraries fcitx5-configtool links against. Qt5 is not installed, so
# only the Qt6 half is built. Qt6 lives in /opt/qt6 on this system. Vietnamese input
# closure (operator request, 2026-10-21), see blfs-fcitx5.
# source: download.fcitx-im.org/fcitx5/fcitx5-qt/fcitx5-qt-5.1.16.tar.zst. Detached
# signature verified good against Weng Xuetian's key
# 2CC8A0609AD2A479C65B6D5C8E8B898CBF2412F9. sha256
# 2d49cb4dfade430e822377beabae5f23da5caf2b2ff49e1eb54213b64dd0840e.
set -e

cmake -B build -D CMAKE_INSTALL_PREFIX=/usr -D CMAKE_BUILD_TYPE=Release \
      -D CMAKE_PREFIX_PATH=/opt/qt6 \
      -D ENABLE_QT5=OFF -D ENABLE_QT6=ON \
      -W no-dev
cmake --build build
cmake --install build
