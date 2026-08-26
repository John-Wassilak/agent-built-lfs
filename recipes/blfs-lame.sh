#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/lame.html
# title  : LAME-3.100
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: b54fe08e0bdbf7cddb Download size: 1.5 MB Estimated disk space required: 9.7 MB Estimated
#   ctx: build time: 0.1 SBU LAME Dependencies Optional Dmalloc, Electric Fence, libsndfile-1.2.2
#   ctx: and NASM-3.01 Editor Notes: https://wiki.linuxfromscratch.org/blfs/wiki/lame
#   ctx: Installation of LAME Prevent the source code directory from being mistakenly hardcoded
#   ctx: as a shared library search path in the installed programs:
sed -i -e 's/^\(\s*hardcode_libdir_flag_spec\s*=\).*/\1/' configure

# --- block 1 --------------------------------------------------
#   ctx: Install LAME by running the following commands:
./configure --prefix=/usr --enable-mp3rtp --disable-static &&
make

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue: LD_LIBRARY_PATH=libmp3lame/.libs make test. Now, as the root
#   ctx: user:
make pkghtmldir=/usr/share/doc/lame-3.100 install

