#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/x264.html
# title  : x264-20250815
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Information Download (HTTP):
#   ctx: https://anduin.linuxfromscratch.org/BLFS/x264/x264-20250815.tar.xz Download MD5 sum:
#   ctx: a4adb6f7d2644043765885e54abc3955 Download size: 732 KB Estimated disk space required: 15
#   ctx: MB Estimated build time: 0.2 SBU (Using parallelism=4) x264 Dependencies Recommended
#   ctx: NASM-3.01 Optional ffms2, gpac or liblsmash Installation of x264 Install x264 by running
#   ctx: the following commands:
./configure --prefix=/usr   \
            --enable-shared \
            --disable-cli   &&
make

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make install

