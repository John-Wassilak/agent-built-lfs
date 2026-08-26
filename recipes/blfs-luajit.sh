#!/bin/bash
# HAND-AUTHORED recipe from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/luajit.html
# title  : luajit-20260213
# rationale: Recommended dependency of mpv (tier 14) -- distinct from the
# lua5.4 (libinput, tier 8) and lua5.5 (Hyprland, tier 10) builds already on
# this system; luajit installs under its own soname/pkg-config name and
# doesn't collide with either.
set -e

make PREFIX=/usr amalg

make PREFIX=/usr install
rm -v /usr/lib/libluajit-5.1.a

echo "### version"
luajit -v 2>&1 || true
