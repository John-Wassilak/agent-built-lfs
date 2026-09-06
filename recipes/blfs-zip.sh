#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/zip.html
# title  : Zip-3.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: into ZIP archives. Note This package is known to build and work properly using an LFS
#   ctx: 13.0 platform. Package Information Download (HTTP):
#   ctx: https://downloads.sourceforge.net/infozip/zip30.tar.gz Download MD5 sum:
#   ctx: 7b74551e63f8ee6aab6fbc86676c0d37 Download size: 1.1 MB Estimated disk space required:
#   ctx: 6.4 MB Estimated build time: 0.1 SBU Installation of Zip Install Zip by running the
#   ctx: following commands:
make -f unix/Makefile generic CC="gcc -std=gnu89"

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make prefix=/usr MANDIR=/usr/share/man/man1 -f unix/Makefile install

