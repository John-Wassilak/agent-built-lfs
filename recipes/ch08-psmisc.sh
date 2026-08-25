#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/psmisc.html
# title  : 8.33. Psmisc-23.7
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Psmisc package contains programs for displaying information about running processes.
#   ctx: Approximate build time: less than 0.1 SBU Required disk space: 6.7 MB 8.33.1.
#   ctx: Installation of Psmisc Prepare Psmisc for compilation:
./configure --prefix=/usr

# --- block 1 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: To run the test suite, run:
#   TAGS: testsuite   [DISABLED - review]
# make check

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make install

