#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/gnome/gexiv2.html
# title  : gexiv2-0.14.6
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: .14/gexiv2-0.14.6.tar.xz Download MD5 sum: 4139dfeca8e30288969233568c72e06e Download
#   ctx: size: 384 KB Estimated disk space required: 3.3 MB (with tests) Estimated build time:
#   ctx: 0.1 SBU (with tests; both with parallelism=4) gexiv2 Dependencies Required Exiv2-0.28.7
#   ctx: Recommended Vala-0.56.18 Optional GTK-Doc-1.35.1 (for documentation) Installation of
#   ctx: gexiv2 Install gexiv2 by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, run:
meson configure -D tests=true &&
ninja test

# --- block 2 --------------------------------------------------
#   ctx: As the root user:
ninja install

