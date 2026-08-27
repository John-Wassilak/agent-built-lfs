#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for xcb-util-xrm.
# source: github.com/Airblader/xcb-util-xrm, tag v1.3.
# Rationale: awesome window manager dependency (see AWESOME-X11-PLAN.md).
#
# Real gap: this package's own configure.ac calls XCB_UTIL_COMMON, an
# autoconf macro that only autotools-built xcb-util installs to
# /usr/share/aclocal (this project's xcb-util was built via meson,
# which doesn't produce that file at all). Fetched the macro directly
# from its actual source, the xcb-util-m4 submodule
# (gitlab.freedesktop.org/xorg/util/xcb-util-m4), into ./m4/ before
# bootstrapping, rather than rebuilding xcb-util via autotools just for
# this.
set -e

curl -fsSL "https://gitlab.freedesktop.org/api/v4/projects/xorg%2Futil%2Fxcb-util-m4/repository/files/xcb_util_common.m4/raw?ref=master" -o m4/xcb_util_common.m4
curl -fsSL "https://gitlab.freedesktop.org/api/v4/projects/xorg%2Futil%2Fxcb-util-m4/repository/files/xcb_util_m4_with_include_path.m4/raw?ref=master" -o m4/xcb_util_m4_with_include_path.m4
curl -fsSL "https://gitlab.freedesktop.org/api/v4/projects/xorg%2Futil%2Fxcb-util-m4/repository/files/ax_compare_version.m4/raw?ref=master" -o m4/ax_compare_version.m4

libtoolize --force --copy
aclocal
autoconf
automake --add-missing --copy
./configure --prefix=/usr --disable-static
make
make install
