#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter06/patch.html
# title  : 6.13. Patch-2.8
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Patch package contains a program for modifying or creating files by applying a
#   ctx: “patch” file typically created by the diff program. Approximate build time: 0.1 SBU
#   ctx: Required disk space: 14 MB 6.13.1. Installation of Patch Prepare Patch for compilation:
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

# --- block 1 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: Install the package:
make DESTDIR=$LFS install

