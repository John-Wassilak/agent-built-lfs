#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. The compositor itself -- needs everything above plus lcms2, muparser (BLFS, already built), glib2 (already built), and the X11/XCB tier for XWayland integration. Uses Arch's exact source URL (the GitHub release's bundled 'source' tarball, not a plain git-tag archive -- Hyprland's own release process vendors things the plain tag archive would not include) and its top-level Makefile wrapper around the real cmake build.
set -e

sed -i -e '/^release:/{n;s/-D/-DCMAKE_SKIP_RPATH=ON -D/}' Makefile
make release PREFIX=/usr
make install
rm -fv /usr/include/hyprland/src/version.h.in

echo "### version"
hyprctl version 2>&1 || Hyprland --version 2>&1 || true

