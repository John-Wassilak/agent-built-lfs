#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/gdbm.html
# title  : 8.39. GDBM-1.26
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ntains the GNU Database Manager. It is a library of database functions that uses
#   ctx: extensible hashing and works like the standard UNIX dbm. The library provides primitives
#   ctx: for storing key/data pairs, searching and retrieving the data by its key and deleting a
#   ctx: key along with its data. Approximate build time: 0.2 SBU Required disk space: 13 MB
#   ctx: 8.39.1. Installation of GDBM Prepare GDBM for compilation:
./configure --prefix=/usr    \
            --disable-static \
            --enable-libgdbm-compat

# --- block 1 --------------------------------------------------
#   ctx: The meaning of the configure option: --enable-libgdbm-compat This switch enables
#   ctx: building the libgdbm compatibility library. Some packages outside of LFS may require the
#   ctx: older DBM routines it provides. Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue:
#   TAGS: testsuite   [DISABLED - review]
# make check

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make install

