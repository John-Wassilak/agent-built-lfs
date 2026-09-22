#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/imagemagick.html
# title  : ImageMagick-7.1.2-13
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: scape-1.4.4, Blender, corefonts, GhostPCL, Gnuplot, POV-Ray, and Radiance Optional
#   ctx: Conversion Tools Enscript-1.6.6, Potrace-1.16, texlive-20260301 (or install-tl-unx)
#   ctx: AutoTrace, GeoExpress Command Line Utilities, AKA MrSID Utilities (binary package),
#   ctx: hp2xx, libwmf, UniConvertor, and Utah Raster Toolkit (or URT-3.1b) Installation of
#   ctx: ImageMagick Install ImageMagick by running the following commands:
./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --enable-hdri     \
            --with-modules    \
            --with-perl       \
            --disable-static  &&
make

# --- block 1 --------------------------------------------------
#   ctx: Now, as the root user:
make DOCUMENTATION_PATH=/usr/share/doc/imagemagick-7.1.2 install

