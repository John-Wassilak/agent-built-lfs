#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/tree.html
# title  : tree-2.3.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: own to build and work properly using an LFS 13.1 platform. Package Information Download
#   ctx: (HTTP):
#   ctx: https://gitlab.com/OldManProgrammer/unix-tree/-/archive/2.3.2/unix-tree-2.3.2.tar.bz2
#   ctx: Download MD5 sum: 1f87820af612c03bfcc0fe7800ce0c71 Download size: 60 KB Estimated disk
#   ctx: space required: 832 KB Estimated build time: less than 0.1 SBU Installation of tree
#   ctx: Install tree by running the following commands:
make

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make PREFIX=/usr MANDIR=/usr/share/man install

