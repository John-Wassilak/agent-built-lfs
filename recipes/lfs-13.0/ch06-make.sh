#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter06/make.html
# title  : 6.12. Make-4.4.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Make package contains a program for controlling the generation of executables and
#   ctx: other non-source files of a package from source files. Approximate build time: less than
#   ctx: 0.1 SBU Required disk space: 15 MB 6.12.1. Installation of Make Prepare Make for
#   ctx: compilation:
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

# --- block 1 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: Install the package:
make DESTDIR=$LFS install

