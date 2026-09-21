#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/cairo.html
# title  : Cairo-1.18.4
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ional ghostscript-10.06.0, GTK-Doc-1.35.1, libdrm-2.4.131, librsvg-2.61.4,
#   ctx: libxml2-2.15.1, LZO-2.10, Poppler-26.02.0, Valgrind-3.26.0, GTK+-2, and libspectre Note
#   ctx: There is a circular dependency between cairo and harfbuzz. If cairo is built before
#   ctx: harfbuzz, it is necessary to rebuild cairo after harfbuzz in order to build pango.
#   ctx: Installation of Cairo Install Cairo by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: This package does not have a working test suite. Now, as the root user:
ninja install

