#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/postlfs/gpgmepp.html
# title  : gpgmepp-2.0.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: d work properly using an LFS 13.0 platform. Package Information Download (HTTP):
#   ctx: https://www.gnupg.org/ftp/gcrypt/gpgmepp/gpgmepp-2.0.0.tar.xz Download MD5 sum:
#   ctx: c27f2285fe9fac54b5d1ca22e00b4594 Download size: 115 KB Estimated disk space required:
#   ctx: 8.9 MB Estimated build time: 0.1 SBU gpgmepp Dependencies Required gpgme-2.0.1
#   ctx: Installation of gpgmepp Install gpgmepp by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr .. &&
make

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make install

