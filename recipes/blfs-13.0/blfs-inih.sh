#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/inih.html
# title  : inih-62
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: n C. Note This package is known to build and work properly using an LFS 13.0 platform.
#   ctx: Package Information Download (HTTP):
#   ctx: https://github.com/benhoyt/inih/archive/r62/inih-r62.tar.gz Download MD5 sum:
#   ctx: c0c6982525958a0376a3cb5bfbee14a0 Download size: 24 KB Estimated disk space required: 2
#   ctx: MB Estimated build time: less than 0.1 SBU Installation of inih Install inih by running
#   ctx: the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install

