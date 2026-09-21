#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libksba.html
# title  : libksba-1.6.7
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ation Download (HTTP): https://www.gnupg.org/ftp/gcrypt/libksba/libksba-1.6.7.tar.bz2
#   ctx: Download MD5 sum: 7e736de467b67c7ea88de746c31ea12f Download size: 692 KB Estimated disk
#   ctx: space required: 9.4 MB (with tests) Estimated build time: 0.1 SBU (with tests) Libksba
#   ctx: Dependencies Required libgpg-error-1.59 Optional Valgrind-3.26.0 Installation of Libksba
#   ctx: Install Libksba by running the following commands:
./configure --prefix=/usr &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

