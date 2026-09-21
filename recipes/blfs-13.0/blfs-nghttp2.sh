#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/basicnet/nghttp2.html
# title  : nghttp2-1.68.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: e: 1.6 MB Estimated disk space required: 25 MB Estimated build time: 0.1 SBU nghttp2
#   ctx: Dependencies Recommended libxml2-2.15.1 Optional The following are only used if building
#   ctx: the full package instead of only the main libraries: c-ares-1.34.6, jansson-2.15.0,
#   ctx: libevent-2.1.12, sphinx-9.1.0, jemalloc, libev, mruby, and Spdylay. Installation of
#   ctx: nghttp2 Install nghttp2 by running the following commands:
./configure --prefix=/usr     \
            --disable-static  \
            --enable-lib-only \
            --docdir=/usr/share/doc/nghttp2-1.68.0 &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

