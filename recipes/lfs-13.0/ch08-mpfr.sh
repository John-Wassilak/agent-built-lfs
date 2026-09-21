#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/mpfr.html
# title  : 8.23. MPFR-4.2.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The MPFR package contains functions for multiple precision math. Approximate build time:
#   ctx: 0.2 SBU Required disk space: 43 MB 8.23.1. Installation of MPFR Prepare MPFR for
#   ctx: compilation:
./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.2.2

# --- block 1 --------------------------------------------------
#   ctx: Compile the package and generate the HTML documentation:
make
make html

# --- block 2 --------------------------------------------------
#   ctx: Important The test suite for MPFR in this section is considered critical. Do not skip it
#   ctx: under any circumstances. Test the results and ensure that all 198 tests passed:
#   TAGS: testsuite   [DISABLED - review]
# make check

# --- block 3 --------------------------------------------------
#   ctx: Install the package and its documentation:
make install
make install-html

