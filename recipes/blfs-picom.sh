#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. X11 compositor, added for real anti-aliased
# rounded window corners (awesome's own client.shape approach is a hard
# X11-Shape-extension cutout, not alpha-blended -- see rc.lua/BUILD-
# REPORT.md's Phase 5 corner-radius work). Also gives proper shadows and
# window-close/open fade, closer to how the abandoned Hyprland setup
# looked. GitHub's auto-generated source tarball omits git submodules
# (same gap hit with rofi's libgwater/libnkutils) -- cloned with
# --recurse-submodules instead.
#
# All of libx11/libX11-xcb/libxcb (with composite/damage/glx/present/
# randr/render/shape/sync/xfixes extensions)/xcb-util-image/xcb-util-
# renderutil/pixman/dbus/libepoxy/Mesa/pcre2 were already present in
# this project; only libconfig, libev, and uthash (header-only) had to
# be built fresh.
set -e

meson setup --prefix=/usr --buildtype=release build
ninja -C build
ninja -C build install
