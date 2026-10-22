#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this package.
# rationale: fcitx5-config-qt, the graphical settings tool: add the Bamboo input
# method, choose Telex/VNI, set the switch hotkey. The KDE System Settings module
# (ENABLE_KCM) would need Plasma, Kirigami, KCMUtils and more, none installed, so only
# the standalone Qt tool is built; it needs KF6ItemViews and KF6WidgetsAddons
# (blfs-kitemviews, blfs-kwidgetsaddons). Vietnamese input closure (operator request,
# 2026-10-21), see blfs-fcitx5.
# source: download.fcitx-im.org/fcitx5/fcitx5-configtool/fcitx5-configtool-5.1.16.tar.zst.
# Detached signature verified good against Weng Xuetian's key
# 2CC8A0609AD2A479C65B6D5C8E8B898CBF2412F9. sha256
# 0d9b9e023d3aa7056ec185ed9e6ccfb94e5a5b930d3dd742dba7f37a49abd61e.
set -e

cmake -B build -D CMAKE_INSTALL_PREFIX=/usr -D CMAKE_BUILD_TYPE=Release \
      -D CMAKE_PREFIX_PATH=/opt/qt6 \
      -D ENABLE_KCM=OFF -D ENABLE_CONFIG_QT=ON \
      -W no-dev
cmake --build build
cmake --install build
