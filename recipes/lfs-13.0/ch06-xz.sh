#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter06/xz.html
# title  : 6.16. Xz-5.8.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Xz package contains programs for compressing and decompressing files. It provides
#   ctx: capabilities for the lzma and the newer xz compression formats. Compressing text files
#   ctx: with xz yields a better compression percentage than with the traditional gzip or bzip2
#   ctx: commands. Approximate build time: 0.1 SBU Required disk space: 24 MB 6.16.1.
#   ctx: Installation of Xz Prepare Xz for compilation:
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.8.2

# --- block 1 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: Install the package:
make DESTDIR=$LFS install

# --- block 3 --------------------------------------------------
#   ctx: Remove the libtool archive file because it is harmful for cross compilation:
rm -v $LFS/usr/lib/liblzma.la

