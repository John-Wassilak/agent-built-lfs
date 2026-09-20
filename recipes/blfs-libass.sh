#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/multimedia/libass.html
# title  : libass-0.17.5
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: /download/0.17.5/libass-0.17.5.tar.xz Download MD5 sum: d9aeb9dac0ca97acbaae96c35af4013b
#   ctx: Download size: 452 KB Estimated disk space required: 9.9 MB Estimated build time: 0.1
#   ctx: SBU libass Dependencies Required FreeType-2.14.3 and FriBidi-1.0.16 Recommended
#   ctx: Fontconfig-2.18.3 and NASM-3.02 Optional harfBuzz-14.3.1 and libunibreak Installation of
#   ctx: libass Install libass by running the following commands:
./configure --prefix=/usr --disable-static &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

