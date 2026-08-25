#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter06/tar.html
# title  : 6.15. Tar-1.35
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Tar package provides the ability to create tar archives as well as perform various
#   ctx: other kinds of archive manipulation. Tar can be used on previously created archives to
#   ctx: extract files, to store additional files, or to update or list files which were already
#   ctx: stored. Approximate build time: 0.1 SBU Required disk space: 42 MB 6.15.1. Installation
#   ctx: of Tar Prepare Tar for compilation:
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

# --- block 1 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: Install the package:
make DESTDIR=$LFS install

