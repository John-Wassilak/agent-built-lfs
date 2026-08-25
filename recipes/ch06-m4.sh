#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter06/m4.html
# title  : 6.2. M4-1.4.21
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The M4 package contains a macro processor. Approximate build time: 0.1 SBU Required disk
#   ctx: space: 39 MB 6.2.1. Installation of M4 Prepare M4 for compilation:
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

# --- block 1 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: Install the package:
make DESTDIR=$LFS install

