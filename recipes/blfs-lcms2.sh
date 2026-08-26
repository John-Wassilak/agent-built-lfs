#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/lcms2.html
# title  : Little CMS-2.18
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: /github.com/mm2/Little-CMS/releases/download/lcms2.18/lcms2-2.18.tar.gz Download MD5
#   ctx: sum: bf1dcc205fe3889897ed16e2913b3197 Download size: 5.4 MB Estimated disk space
#   ctx: required: 22 MB (with the tests) Estimated build time: 0.2 SBU (with the tests) Little
#   ctx: CMS2 Dependencies Optional libjpeg-turbo-3.1.3 and libtiff-4.7.1 Installation of Little
#   ctx: CMS2 Install Little CMS2 by running the following commands:
./configure --prefix=/usr --disable-static &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

