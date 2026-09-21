#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/basicnet/libtirpc.html
# title  : libtirpc-1.3.7
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 2 Download MD5 sum: 74f97df306b8d6149d3d9898a1d44c6e Download size: 560 KB Estimated
#   ctx: disk space required: 6.8 MB Estimated build time: less than 0.1 SBU libtirpc
#   ctx: Dependencies Optional MIT Kerberos V5-1.22.2 for GSSAPI support Installation of libtirpc
#   ctx: Note If updating this package, you will also need to update any existing version of
#   ctx: rpcbind-1.2.8 Install libtirpc by running the following commands:
./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --disable-static  \
            --disable-gssapi  &&

make

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make install

