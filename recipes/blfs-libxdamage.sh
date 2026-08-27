#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step (book/x/x7lib.html
# lists libXdamage among the X7 libraries but gives no per-package instructions
# beyond the standard Xorg autotools build).
# rationale: real, verified requirement -- Firefox's configure failed with
# "Package xdamage was not found in the pkg-config search path" (checking for
# x11 xcb xcb-shm x11-xcb xext xrandr xcomposite xcursor xdamage xfixes xi).
# Not previously needed by anything else in this project (awesome/mpv/rofi
# don't need it), so it was never built despite being part of the standard
# BLFS X11 library set most other builds pick up transitively via GTK3's own
# chain.
set -e

./configure $XORG_CONFIG
make
make install
