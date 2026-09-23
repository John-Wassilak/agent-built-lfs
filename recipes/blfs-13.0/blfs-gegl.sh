#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/gegl.html
# title  : gegl-0.4.66
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: bp-1.6.0, luajit-20260213, Pango-1.57.0, Poppler-26.02.0, Ruby-4.0.1,
#   ctx: sdl2-compat-2.32.64, v4l-utils-1.32.0, Vala-0.56.18, lensfun, libnsgif, libumfpack,
#   ctx: maxflow, MRG, OpenCL, OpenEXR, poly2tri-c, source-highlight, and w3m Installation of
#   ctx: gegl If you are installing over a previous version of gegl, one of the modules will need
#   ctx: to be removed. As the root user, run the following command to remove it:
rm -f /usr/lib/gegl-0.4/vector-fill.so

# --- block 1 --------------------------------------------------
#   ctx: Install gegl by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- block 2 --------------------------------------------------
#   ctx: To run the tests, issue: ninja test. Many tests are skipped depending on what optional
#   ctx: dependencies are installed. Fourteen tests are known to fail in the gegl:ff-load-save
#   ctx: portion of the test suite due to incompatibilities with recent versions of ffmpeg. Now,
#   ctx: as the root user:
ninja install

