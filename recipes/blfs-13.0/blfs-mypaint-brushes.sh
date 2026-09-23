#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/mypaint-brushes.html
# title  : mypaint-brushes-1.3.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: github.com/mypaint/mypaint-brushes/releases/download/v1.3.1/mypaint-brushes-1.3.1.tar.xz
#   ctx: Download MD5 sum: 7241032d814cb91d2baae7d009a2a2e0 Download size: 1.3 MB Estimated disk
#   ctx: space required: 3.4 MB Estimated build time: less than 0.1 SBU mypaint-brushes
#   ctx: Dependencies Required at runtime libmypaint-1.6.1 Installation of mypaint-brushes
#   ctx: Install mypaint-brushes by running the following commands:
./configure --prefix=/usr &&
make

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make install

