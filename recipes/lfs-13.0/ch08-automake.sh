#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/automake.html
# title  : 8.48. Automake-1.18.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Automake package contains programs for generating Makefiles for use with Autoconf.
#   ctx: Approximate build time: less than 0.1 SBU (about 1.1 SBU with tests) Required disk
#   ctx: space: 123 MB 8.48.1. Installation of Automake Prepare Automake for compilation:
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.18.1

# --- block 1 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: Using four parallel jobs speeds up the tests, even on systems with less logical cores,
#   ctx: due to internal delays in individual tests. To test the results, issue:
#   TAGS: testsuite   [DISABLED - review]
# make -j$(($(nproc)>4?$(nproc):4)) check

# --- block 3 --------------------------------------------------
#   ctx: Replace $((...)) with the number of logical cores you want to use if you don't want to
#   ctx: use all. Install the package:
make install

