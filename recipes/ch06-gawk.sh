#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter06/gawk.html
# title  : 6.9. Gawk-5.3.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Gawk package contains programs for manipulating text files. Approximate build time:
#   ctx: 0.1 SBU Required disk space: 49 MB 6.9.1. Installation of Gawk First, ensure some
#   ctx: unneeded files are not installed:
sed -i 's/extras//' Makefile.in

# --- block 1 --------------------------------------------------
#   ctx: Prepare Gawk for compilation:
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

# --- block 2 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make DESTDIR=$LFS install

