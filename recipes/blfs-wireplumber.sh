#!/bin/bash
# HAND-AUTHORED recipe from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/wireplumber.html
# title  : Wireplumber-0.5.13
# rationale: pipewire's session manager -- required for pipewire to do
# automatic device management. Required: GLib (tier 11), pipewire (just
# built, this tier), systemd (already present). Recommended: Lua 5.4 (tier
# 8) -- -D system-lua=true uses it directly rather than pulling in a
# bundled copy.
set -e

mkdir build
cd build

meson setup --prefix=/usr --buildtype=release -D system-lua=true ..
ninja

ninja install
mv -v /usr/share/doc/wireplumber /usr/share/doc/wireplumber-0.5.13

echo "### pkg-config"
pkg-config --modversion wireplumber-0.5 2>&1 || true
