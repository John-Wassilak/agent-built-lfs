#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter06/findutils.html
# title  : 6.8. Findutils-4.10.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: e and to create, maintain, and search a database (often faster than the recursive find,
#   ctx: but unreliable unless the database has been updated recently). Findutils also supplies
#   ctx: the xargs program, which can be used to run a specified command on each file selected by
#   ctx: a search. Approximate build time: 0.2 SBU Required disk space: 48 MB 6.8.1. Installation
#   ctx: of Findutils Prepare Findutils for compilation:
./configure --prefix=/usr                   \
            --localstatedir=/var/lib/locate \
            --host=$LFS_TGT                 \
            --build=$(build-aux/config.guess)

# --- block 1 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: Install the package:
make DESTDIR=$LFS install

