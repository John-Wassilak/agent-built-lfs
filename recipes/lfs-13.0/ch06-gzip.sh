#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter06/gzip.html
# title  : 6.11. Gzip-1.14
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Gzip package contains programs for compressing and decompressing files. Approximate
#   ctx: build time: 0.1 SBU Required disk space: 12 MB 6.11.1. Installation of Gzip Prepare Gzip
#   ctx: for compilation:
./configure --prefix=/usr --host=$LFS_TGT

# --- block 1 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: Install the package:
make DESTDIR=$LFS install

