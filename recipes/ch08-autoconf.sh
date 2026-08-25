#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/autoconf.html
# title  : 8.47. Autoconf-2.72
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Autoconf package contains programs for producing shell scripts that can
#   ctx: automatically configure source code. Approximate build time: less than 0.1 SBU (about
#   ctx: 0.4 SBU with tests) Required disk space: 25 MB 8.47.1. Installation of Autoconf Prepare
#   ctx: Autoconf for compilation:
./configure --prefix=/usr

# --- block 1 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue:
#   TAGS: testsuite   [DISABLED - review]
# make check

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make install

