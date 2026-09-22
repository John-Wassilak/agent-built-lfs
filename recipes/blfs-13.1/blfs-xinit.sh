#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/x/xinit.html
# title  : xinit-1.4.4
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: dividual/app/xinit-1.4.4.tar.xz Download MD5 sum: e7430a710261c9129b1280f26cb159a5
#   ctx: Download size: 160 KB Estimated disk space required: 1.4 MB Estimated build time: less
#   ctx: than 0.1 SBU xinit Dependencies Required Xorg Libraries Recommended (runtime only)
#   ctx: twm-1.0.13.1, xclock-1.2.1, and xterm-411 (used in the default xinitrc file)
#   ctx: Installation of xinit Install xinit by running the following commands:
./configure $XORG_CONFIG --with-xinitdir=/etc/X11/app-defaults &&
make

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make install &&
ldconfig

