#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/make.html
# title  : 8.71. Make-4.4.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Make package contains a program for controlling the generation of executables and
#   ctx: other non-source files of a package from source files. Approximate build time: 0.6 SBU
#   ctx: Required disk space: 13 MB 8.71.1. Installation of Make Prepare Make for compilation:
./configure --prefix=/usr

# --- block 1 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue:
#   REVIEWED [drop]: Test suite outside the critical three (glibc/gcc/binutils), so out of scope per the tests policy. It also cannot run any more: ch08-cleanup deleted the 'tester' account it needs, so a re-run fails with "chown: invalid user: 'tester'". These tests did run and pass during the original build, while tester still existed.
# chown -R tester .
# su tester -c "PATH=$PATH make check"

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make install

