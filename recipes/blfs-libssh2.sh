#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/libssh2.html
# title  : libssh2-1.11.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: tional Downloads Required patch:
#   ctx: https://www.linuxfromscratch.org/patches/blfs/13.1/libssh2-1.11.1-security_fixes-1.patch
#   ctx: libssh2 Dependencies Optional CMake-4.4.2 (can be used instead of the configure script),
#   ctx: libgcrypt-1.12.2 (can be used instead of OpenSSL), OpenSSH-10.5p1 (for some tests), and
#   ctx: Docker (for some tests) Installation of libssh2 First, fix three security
#   ctx: vulnerabilities in libssh2:
patch -Np1 -i ../libssh2-1.11.1-security_fixes-1.patch

# --- block 1 --------------------------------------------------
#   ctx: Install libssh2 by running the following commands:
./configure --prefix=/usr          \
            --disable-docker-tests \
            --disable-static       &&
make

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

