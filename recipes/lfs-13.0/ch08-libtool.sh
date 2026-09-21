#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/libtool.html
# title  : 8.38. Libtool-2.5.4
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Libtool package contains the GNU generic library support script. It makes the use of
#   ctx: shared libraries simpler with a consistent, portable interface. Approximate build time:
#   ctx: 0.6 SBU Required disk space: 44 MB 8.38.1. Installation of Libtool Prepare Libtool for
#   ctx: compilation:
./configure --prefix=/usr

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
#   ctx: Remove a static library only useful for the test suite:
rm -fv /usr/lib/libltdl.a

