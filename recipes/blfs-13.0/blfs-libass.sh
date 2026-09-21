#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/libass.html
# title  : libass-0.17.4
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: /download/0.17.4/libass-0.17.4.tar.xz Download MD5 sum: 10963e702850fd888cb270abcbe852c3
#   ctx: Download size: 444 KB Estimated disk space required: 8.0 MB Estimated build time: 0.1
#   ctx: SBU libass Dependencies Required FreeType-2.14.1 and FriBidi-1.0.16 Recommended
#   ctx: Fontconfig-2.17.1 and NASM-3.01 Optional harfBuzz-12.3.2 and libunibreak Installation of
#   ctx: libass Install libass by running the following commands:
./configure --prefix=/usr --disable-static &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

