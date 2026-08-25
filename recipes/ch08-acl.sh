#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/acl.html
# title  : 8.26. Acl-2.3.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Acl package contains utilities to administer Access Control Lists, which are used to
#   ctx: define fine-grained discretionary access rights for files and directories. Approximate
#   ctx: build time: less than 0.1 SBU Required disk space: 6.5 MB 8.26.1. Installation of Acl
#   ctx: Prepare Acl for compilation:
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/acl-2.3.2

# --- block 1 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: The Acl tests must be run on a filesystem that supports access controls. To test the
#   ctx: results, issue:
#   TAGS: testsuite   [DISABLED - review]
# make check

# --- block 3 --------------------------------------------------
#   ctx: One test named test/cp.test is known to fail because Coreutils is not built with the Acl
#   ctx: support yet. Install the package:
make install

