#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/zlib.html
# title  : 8.6. Zlib-1.3.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Zlib package contains compression and decompression routines used by some programs.
#   ctx: Approximate build time: less than 0.1 SBU Required disk space: 6.4 MB 8.6.1.
#   ctx: Installation of Zlib Prepare Zlib for compilation:
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
#   ctx: Remove a useless static library:
rm -fv /usr/lib/libz.a

