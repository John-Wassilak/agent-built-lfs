#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this package.
# rationale: XIM protocol library from the fcitx project. fcitx5 requires it when
# ENABLE_X11 is on, which it is so that XWayland clients get input through XIM.
# Needs ECM and xcb-util/xcb-util-keysyms (already built). Vietnamese input closure
# (operator request, 2026-10-21), see blfs-fcitx5.
# source: download.fcitx-im.org/fcitx5/xcb-imdkit/xcb-imdkit-1.0.9.tar.zst. Detached
# signature verified good against Weng Xuetian's key
# 2CC8A0609AD2A479C65B6D5C8E8B898CBF2412F9. sha256
# 74283bacef4d53655d3ddd6e3b969a787f77ee9d66b6ef256a2012a6ba2d1104.
set -e

cmake -B build -D CMAKE_INSTALL_PREFIX=/usr -D CMAKE_BUILD_TYPE=Release
cmake --build build
cmake --install build
