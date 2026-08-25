#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/attr.html
# title  : 8.25. Attr-2.5.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Attr package contains utilities to administer the extended attributes of filesystem
#   ctx: objects. Approximate build time: less than 0.1 SBU Required disk space: 4.1 MB 8.25.1.
#   ctx: Installation of Attr Prepare Attr for compilation:
./configure --prefix=/usr     \
            --disable-static  \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-2.5.2

# --- block 1 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: The tests must be run on a filesystem that supports extended attributes such as the
#   ctx: ext2, ext3, or ext4 filesystems. To test the results, issue:
#   TAGS: testsuite   [DISABLED - review]
# make check

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make install

