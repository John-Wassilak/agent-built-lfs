#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/libwebp.html
# title  : libwebp-1.6.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 0.tar.gz Download MD5 sum: cceb6447180f961473b181c9ef38b630 Download size: 4.1 MB
#   ctx: Estimated disk space required: 41 MB Estimated build time: 0.3 SBU libwebp Dependencies
#   ctx: Recommended libjpeg-turbo-3.2.0, libpng-1.6.58, tiff-4.7.2, and sdl2-compat-2.32.70 (for
#   ctx: improved 3D Acceleration) Optional Freeglut-3.8.0 and giflib-6.1.3 Installation of
#   ctx: libwebp Install libwebp by running the following commands:
./configure --prefix=/usr           \
            --enable-libwebpmux     \
            --enable-libwebpdemux   \
            --enable-libwebpdecoder \
            --enable-libwebpextras  \
            --enable-swap-16bit-csp \
            --disable-static        &&
make

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make install

