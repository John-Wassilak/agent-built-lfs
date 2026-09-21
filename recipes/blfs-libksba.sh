#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/libksba.html
# title  : libksba-1.8.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: mation Download (HTTP): https://www.gnupg.org/ftp/gcrypt/libksba/libksba-1.8.0.tar.bz2
#   ctx: Download MD5 sum: 182951961170c12f6569454717a1383a Download size: 708 KB Estimated disk
#   ctx: space required: 12 MB (with tests) Estimated build time: 0.1 SBU (with tests) Libksba
#   ctx: Dependencies Required libgpg-error-1.61 Optional Valgrind-3.27.1 Installation of Libksba
#   ctx: Install Libksba by running the following commands:
./configure --prefix=/usr &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

