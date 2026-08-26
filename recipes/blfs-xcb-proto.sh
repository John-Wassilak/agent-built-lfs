#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/xcb-proto.html
# title  : xcb-proto-1.17.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: /xcb-proto-1.17.0.tar.xz Download MD5 sum: c415553d2ee1a8cea43c3234a079b53f Download
#   ctx: size: 152 KB Estimated disk space required: 1.3 MB Estimated build time: less than 0.1
#   ctx: SBU xcb-proto Dependencies Recommended Xorg build environment (needed for the
#   ctx: instructions below) Optional libxml2-2.15.1 (required to run the tests) Installation of
#   ctx: xcb-proto Install xcb-proto by running the following commands:
PYTHON=python3 ./configure $XORG_CONFIG

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

# --- block 2 --------------------------------------------------
#   ctx: If you are upgrading from version 1.15.1 or lower, the old pkgconfig file needs to be
#   ctx: removed. Issue, as the root user:
rm -f $XORG_PREFIX/lib/pkgconfig/xcb-proto.pc

