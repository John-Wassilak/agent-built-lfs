#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/multimedia/dav1d.html
# title  : dav1d-1.5.4
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: d (HTTP): https://code.videolan.org/videolan/dav1d/-/archive/1.5.4/dav1d-1.5.4.tar.gz
#   ctx: Download MD5 sum: af9b8fdb97f436a76b73425ed16b6239 Download size: 1.7 MB Estimated disk
#   ctx: space required: 26 MB (with tests) Estimated build time: 0.3 SBU (using parallelism=4;
#   ctx: with tests) dav1d Dependencies Recommended NASM-3.02 Optional xxhash Installation of
#   ctx: dav1d Install dav1d by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release --wrap-mode=nofallback .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, run ninja test. Now, as the root user:
ninja install

