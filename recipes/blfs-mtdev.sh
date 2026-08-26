#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/mtdev.html
# title  : mtdev-1.1.7
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: rotocol. Note This package is known to build and work properly using an LFS 13.0
#   ctx: platform. Package Information Download (HTTP):
#   ctx: https://bitmath.org/code/mtdev/mtdev-1.1.7.tar.bz2 Download MD5 sum:
#   ctx: 483ed7fdf7c1e7b7375c05a62848cce7 Download size: 296 KB Estimated disk space required:
#   ctx: 2.5 MB Estimated build time: less than 0.1 SBU Installation of mtdev Install mtdev by
#   ctx: running the following commands:
./configure --prefix=/usr --disable-static &&
make

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make install

