#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Blue-light filter, operator-requested (kept from
# their real dotfiles' autostart block; DPMS/idle timeout via swayidle
# deliberately dropped per operator request -- don't want screen
# blanking). Deps: wayland-client, wayland-protocols (already built).
# man-pages disabled -- scdoc not installed, same "book/upstream leaves an
# optional doc-tool build on by default" pattern as elsewhere in this
# project.
set -e

meson setup --prefix=/usr --buildtype=release -D man-pages=disabled . build
ninja -C build
ninja -C build install

echo "### version"
wlsunset -h 2>&1 | head -1 || true
