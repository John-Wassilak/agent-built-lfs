#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/basicnet/libndp.html
# title  : libndp-1.9
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ng NDP messages. Note This package is known to build and work properly using an LFS 13.0
#   ctx: platform. Package Information Download (HTTP): http://libndp.org/files/libndp-1.9.tar.gz
#   ctx: Download MD5 sum: 9d486750569e7025e5d0afdcc509b93c Download size: 368 KB Estimated disk
#   ctx: space required: 2.5 MB Estimated build time: less than 0.1 SBU Installation of libndp
#   ctx: Install libndp by running the following command:
./configure --prefix=/usr        \
            --sysconfdir=/etc    \
            --localstatedir=/var \
            --disable-static     &&
make

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make install

