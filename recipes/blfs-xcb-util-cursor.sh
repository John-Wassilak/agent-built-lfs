#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for xcb-util-cursor.
# source: xcb.freedesktop.org/dist/xcb-util-cursor-0.1.5.tar.xz
# Rationale: awesome window manager dependency (see AWESOME-X11-PLAN.md).
set -e

./configure --prefix=/usr --disable-static
make
make install
