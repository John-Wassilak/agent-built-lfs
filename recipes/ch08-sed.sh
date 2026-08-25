#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/sed.html
# title  : 8.32. Sed-4.9
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Sed package contains a stream editor. Approximate build time: 0.3 SBU Required disk
#   ctx: space: 30 MB 8.32.1. Installation of Sed Prepare Sed for compilation:
./configure --prefix=/usr

# --- block 1 --------------------------------------------------
#   ctx: Compile the package and generate the HTML documentation:
make
make html

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue:
#   REVIEWED [drop]: Test suite outside the critical three (glibc/gcc/binutils), so out of scope per the tests policy. It also cannot run any more: ch08-cleanup deleted the 'tester' account it needs, so a re-run fails with "chown: invalid user: 'tester'". These tests did run and pass during the original build, while tester still existed.
# chown -R tester .
# su tester -c "PATH=$PATH make check"

# --- block 3 --------------------------------------------------
#   ctx: Install the package and its documentation:
make install
install -d -m755           /usr/share/doc/sed-4.9
install -m644 doc/sed.html /usr/share/doc/sed-4.9

