#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/tar.html
# title  : 8.73. Tar-1.35
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Tar package provides the ability to create tar archives as well as perform various
#   ctx: other kinds of archive manipulation. Tar can be used on previously created archives to
#   ctx: extract files, to store additional files, or to update or list files which were already
#   ctx: stored. Approximate build time: 0.6 SBU Required disk space: 43 MB 8.73.1. Installation
#   ctx: of Tar Prepare Tar for compilation:
FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr

# --- block 1 --------------------------------------------------
#   ctx: The meaning of the configure option: FORCE_UNSAFE_CONFIGURE=1 This forces the test for
#   ctx: mknod to be run as root. It is generally considered dangerous to run this test as the
#   ctx: root user, but as it is being run on a system that has only been partially built,
#   ctx: overriding it is OK. Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue:
#   TAGS: testsuite   [DISABLED - review]
# make check

# --- block 3 --------------------------------------------------
#   ctx: One test, capabilities: binary store/restore, is known to fail if it is run because LFS
#   ctx: lacks selinux, but will be skipped if the host kernel does not support extended
#   ctx: attributes or security labels on the filesystem used for building LFS. Install the
#   ctx: package:
make install
make -C doc install-html docdir=/usr/share/doc/tar-1.35

