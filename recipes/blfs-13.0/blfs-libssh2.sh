#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libssh2.html
# title  : libssh2-1.11.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: dacace2e6 Download size: 1.0 MB Estimated disk space required: 15 MB (with tests)
#   ctx: Estimated build time: 0.2 SBU (with tests) libssh2 Dependencies Optional CMake-4.2.3
#   ctx: (can be used instead of the configure script), libgcrypt-1.12.0 (can be used instead of
#   ctx: OpenSSL), OpenSSH-10.2p1 (for some tests), and Docker (for some tests) Installation of
#   ctx: libssh2 Install libssh2 by running the following commands:
./configure --prefix=/usr          \
            --disable-docker-tests \
            --disable-static       &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

