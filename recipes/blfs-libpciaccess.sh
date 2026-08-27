#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for libpciaccess (a real gap:
# the book's xorg-server page requires it via hw/xfree86's meson.build,
# hard, but never lists it in the page's own dependency section).
# source: x.org individual release, libpciaccess-0.18.1 (current stable).
set -e

mkdir build
cd build

meson setup --prefix=/usr --buildtype=release ..
ninja
ninja install
