#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/hicolor-icon-theme.html
# title  : hicolor-icon-theme-0.18
# rationale: Base fallback icon theme -- found missing while debugging
# wofi: "Could not find the icon 'gvim'. The 'hicolor' theme was not
# found either." Referenced by name in every .desktop-consuming app on
# this system.
set -e

mkdir build
cd build

meson setup --prefix=/usr --buildtype=release ..
ninja

ninja install
