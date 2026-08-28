#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/librsvg.html
# title  : librsvg-2.61.4
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: system certificate store may need to be set up with make-ca-1.16.1 before building this
#   ctx: package. Recommended gdk-pixbuf-2.44.5, GLib-2.86.4 (with GObject Introspection), and
#   ctx: Vala-0.56.18 Optional dav1d-1.5.3 (to support embedded AVIF in SVG), docutils-0.22.4
#   ctx: (for man pages), and Gi-DocGen-2026.1 (for documentation) Installation of librsvg First,
#   ctx: fix the installation path of the API documentation:
sed -e "/OUTDIR/s|,| / 'librsvg-2.61.4', '--no-namespace-dir',|" \
    -e '/output/s|Rsvg-2.0|librsvg-2.61.4|'                      \
    -i doc/meson.build

# --- block 1 --------------------------------------------------
#   ctx: Install librsvg by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release -D pixbuf-loader=enabled .. &&
ninja

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue:
#   REVIEWED [drop]: Test suite (meson test -v) -- skipped, matches every other package in this build.
# meson test -v

# --- block 3 --------------------------------------------------
#   ctx: Now, as the root user:
ninja install

