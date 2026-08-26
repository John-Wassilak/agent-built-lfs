#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libgpg-error.html
# title  : libgpg-error-1.59
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ork properly using an LFS 13.0 platform. Package Information Download (HTTP):
#   ctx: https://www.gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-1.59.tar.bz2 Download MD5
#   ctx: sum: d8afb7b49472cadcc434fa65d6b527ef Download size: 1.1 MB Estimated disk space
#   ctx: required: 15 MB (with tests) Estimated build time: 0.3 SBU (with tests) Installation of
#   ctx: libgpg-error Install libgpg-error by running the following commands:
./configure --prefix=/usr --sysconfdir=/etc &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install &&
install -v -m644 -D README /usr/share/doc/libgpg-error-1.59/README

