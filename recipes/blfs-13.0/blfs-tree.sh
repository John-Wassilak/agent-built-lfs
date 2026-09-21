#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/tree.html
# title  : tree-2.3.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: own to build and work properly using an LFS 13.0 platform. Package Information Download
#   ctx: (HTTP):
#   ctx: https://gitlab.com/OldManProgrammer/unix-tree/-/archive/2.3.1/unix-tree-2.3.1.tar.bz2
#   ctx: Download MD5 sum: f39b46b96098b6dd196f6cea311e6473 Download size: 60 KB Estimated disk
#   ctx: space required: 840 KB Estimated build time: less than 0.1 SBU Installation of tree
#   ctx: Install tree by running the following commands:
make

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make PREFIX=/usr MANDIR=/usr/share/man install

