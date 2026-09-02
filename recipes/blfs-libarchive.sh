#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libarchive.html
# title  : libarchive-3.8.5
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: archive/releases/download/v3.8.5/libarchive-3.8.5.tar.xz Download MD5 sum:
#   ctx: 2cd5a73ed7fe7f9da22d34ac1048534e Download size: 5.8 MB Estimated disk space required: 43
#   ctx: MB (add 37 MB for tests) Estimated build time: 0.3 SBU (add 0.8 SBU for tests)
#   ctx: libarchive Dependencies Optional libxml2-2.15.1, LZO-2.10, and Nettle-3.10.2
#   ctx: Installation of libarchive Install libarchive by running the following commands:
./configure --prefix=/usr --disable-static &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

# --- block 2 --------------------------------------------------
#   ctx: Still as the root user, create a symlink so we can use bsdunzip as unzip, instead of
#   ctx: relying on the unmaintained Unzip package:
ln -sfv bsdunzip /usr/bin/unzip

