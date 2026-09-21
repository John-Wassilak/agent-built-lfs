#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/libunistring.html
# title  : libunistring-1.4.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Download MD5 sum: e033195d90d0803063f3fecc77148124 Download size: 2.7 MB Estimated disk
#   ctx: space required: 58 MB (add 46 MB for tests) Estimated build time: 0.6 SBU (add 0.3 SBU
#   ctx: for tests; both using parallelism=4) libunistring Dependencies Optional texlive-20260301
#   ctx: (or install-tl-unx) (to rebuild the documentation) Installation of libunistring Install
#   ctx: libunistring by running the following commands:
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/libunistring-1.4.2 &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

