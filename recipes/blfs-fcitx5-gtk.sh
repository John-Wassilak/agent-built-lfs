#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this package.
# rationale: GTK3/GTK4 IM modules and the fcitx5 GObject client library. GTK apps on
# Wayland can reach fcitx5 through text-input-v3 without these, but XWayland GTK apps
# and GTK's own im-module path need them. GTK2 is not installed, so its module is off.
# Vietnamese input closure (operator request, 2026-10-21), see blfs-fcitx5.
# source: download.fcitx-im.org/fcitx5/fcitx5-gtk/fcitx5-gtk-5.1.7.tar.zst. Detached
# signature verified good against Weng Xuetian's key
# 2CC8A0609AD2A479C65B6D5C8E8B898CBF2412F9. sha256
# bda5aae72886d0f046e896c48461ffa257ecaa6045e17827ffe27f1530172c42.
set -e

cmake -B build -D CMAKE_INSTALL_PREFIX=/usr -D CMAKE_BUILD_TYPE=Release \
      -D ENABLE_GTK2_IM_MODULE=OFF \
      -W no-dev
cmake --build build
cmake --install build
# GTK reads its module caches, not the module directories.
gtk-query-immodules-3.0 --update-cache
if [ -d /usr/lib/gtk-4.0/4.0.0/immodules ]; then
    gio-querymodules /usr/lib/gtk-4.0/4.0.0/immodules
fi
