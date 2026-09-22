#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/libarchive.html
# title  : libarchive-3.8.9
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: thub.com/libarchive/libarchive/releases/download/v3.8.9/libarchive-3.8.9.tar.xz Download
#   ctx: MD5 sum: 535e3afec5f61d493f0b1b9e8bcf7539 Download size: 6.4 MB Estimated disk space
#   ctx: required: 91 MB (with tests) Estimated build time: 1.1 SBU (with tests) libarchive
#   ctx: Dependencies Optional libxml2-2.15.3, LZO-2.10, and Nettle-4.0 Installation of
#   ctx: libarchive Install libarchive by running the following commands:
./configure --prefix=/usr --disable-static &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check as a non-root user. Now, as the root user:
make install

# --- block 2 --------------------------------------------------
#   ctx: Still as the root user, create a symlink so we can use bsdunzip as unzip, instead of
#   ctx: relying on the unmaintained Unzip package:
ln -sfv bsdunzip /usr/bin/unzip

