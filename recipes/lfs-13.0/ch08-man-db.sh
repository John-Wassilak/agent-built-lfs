#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/man-db.html
# title  : 8.80. Man-DB-2.13.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Man-DB package contains programs for finding and viewing man pages. Approximate
#   ctx: build time: 0.3 SBU Required disk space: 44 MB 8.80.1. Installation of Man-DB Prepare
#   ctx: Man-DB for compilation:
./configure --prefix=/usr                         \
            --docdir=/usr/share/doc/man-db-2.13.1 \
            --sysconfdir=/etc                     \
            --disable-setuid                      \
            --enable-cache-owner=bin              \
            --with-browser=/usr/bin/lynx          \
            --with-vgrind=/usr/bin/vgrind         \
            --with-grap=/usr/bin/grap

# --- block 1 --------------------------------------------------
#   ctx: a text-based web browser (see BLFS for installation instructions), vgrind converts
#   ctx: program sources to Groff input, and grap is useful for typesetting graphs in Groff
#   ctx: documents. The vgrind and grap programs are not normally needed for viewing manual
#   ctx: pages. They are not part of LFS or BLFS, but you should be able to install them yourself
#   ctx: after finishing LFS if you wish to do so. Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue:
#   TAGS: testsuite   [DISABLED - review]
# make check

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make install

