#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/xdg-desktop-portal.html
# title  : xdg-desktop-portal-1.20.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: t will create a large security issue. Optional GeoClue-2.8.0 (for the “location”
#   ctx: portal), and pytest-9.0.2 with libportal-0.9.1, dbusmock-0.38.1, and umockdev-0.19.4
#   ctx: (for running tests) Optional (for building the documentation) sphinx-9.1.0 with
#   ctx: sphinxext.opengraph, sphinx_copybutton, furo, and flatpak Installation of
#   ctx: xdg-desktop-portal Install xdg-desktop-portal by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release -D tests=disabled .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: If the optional dependencies are installed, you can test the results by running:
#   REVIEWED [drop]: Optional test suite, guarded by the book's own conditional: 'If the optional dependencies are installed, you can test the results by running'. Those dependencies are pytest-9.0.2, libportal-0.9.1, dbusmock-0.38.1 and umockdev-0.19.4, none of which is in this build. This block is worse than a plain 'make check' skip: its first command is 'meson configure -D tests=enabled', which reconfigures the tree away from the '-D tests=disabled' the book's own block 0 sets, so running it on a system without those four packages breaks the configured build rather than merely failing a test. The book itself notes that one test (integration/dynamiclauncher) fails without the external dependencies anyway.
# meson configure -D tests=enabled &&
# ninja test

# --- block 2 --------------------------------------------------
#   ctx: Without the external dependencies one test, integration/dynamiclauncher is known to
#   ctx: fail. Now, as the root user:
ninja install

