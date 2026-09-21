#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.1-systemd book.
# source : book/13.1/chapter08/expat.html
# title  : 8.43 Expat-2.8.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Expat package contains a stream oriented C library for parsing XML. Approximate
#   ctx: build time: 0.1 SBU Required disk space: 12 MB 8.43.1 Installation of Expat Prepare
#   ctx: Expat for compilation:
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.8.3

# --- block 1 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue:
#   TAGS: testsuite   [DISABLED - review]
# make check

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make install

# --- block 4 --------------------------------------------------
#   ctx: If desired, install the documentation:
install -v -m644 doc/*.{html,css} /usr/share/doc/expat-2.8.3

