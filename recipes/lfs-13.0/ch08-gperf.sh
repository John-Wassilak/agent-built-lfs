#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/gperf.html
# title  : 8.40. Gperf-3.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Gperf generates a perfect hash function from a key set. Approximate build time: 0.2 SBU
#   ctx: Required disk space: 12 MB 8.40.1. Installation of Gperf Prepare Gperf for compilation:
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.3

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

