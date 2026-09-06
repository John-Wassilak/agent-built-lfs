#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libatomic_ops.html
# title  : libatomic_ops-7.10.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: S 13.0 platform. Package Information Download (HTTP):
#   ctx: s://github.com/bdwgc/libatomic_ops/releases/download/v7.10.0/libatomic_ops-7.10.0.tar.gz
#   ctx: Download MD5 sum: 1de9631daa0781a8c5a8457053d57cf0 Download size: 532 KB Estimated disk
#   ctx: space required: 6.2 MB (with tests) Estimated build time: 0.1 SBU (with tests)
#   ctx: Installation of libatomic_ops Install libatomic_ops by running the following commands:
./configure --prefix=/usr    \
            --enable-shared  \
            --disable-static \
            --docdir=/usr/share/doc/libatomic_ops-7.10.0 &&
make

# --- block 1 --------------------------------------------------
#   ctx: To check the results, issue make check. Now, as the root user:
make install

