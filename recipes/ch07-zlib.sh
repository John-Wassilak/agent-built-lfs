#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.1-systemd book.
# source : book/13.1/chapter07/zlib.html
# title  : 7.10 Zlib-1.3.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Zlib package contains compression and decompression routines used by some programs.
#   ctx: Approximate build time: less than 0.1 SBU Required disk space: 5.7 MB 7.10.1
#   ctx: Installation of Zlib Prepare Zlib for compilation:
./configure --prefix=/usr

# --- block 1 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: Install the package:
make install

# --- block 3 --------------------------------------------------
#   ctx: Remove a useless static library:
rm -fv /usr/lib/libz.a

