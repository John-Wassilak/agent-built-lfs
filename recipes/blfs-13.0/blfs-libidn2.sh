#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libidn2.html
# title  : libidn2-2.3.8
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: s://ftpmirror.gnu.org/libidn/libidn2-2.3.8.tar.gz Download MD5 sum:
#   ctx: a8e113e040d57a523684e141970eea7a Download size: 2.1 MB Estimated disk space required: 21
#   ctx: MB (add 3 MB for tests) Estimated build time: 0.1 SBU (add 0.6 SBU for tests) libidn2
#   ctx: Dependencies Recommended libunistring-1.4.1 Optional git-2.53.0 and GTK-Doc-1.35.1
#   ctx: Installation of libidn2 Install libidn2 by running the following commands:
./configure --prefix=/usr --disable-static &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

