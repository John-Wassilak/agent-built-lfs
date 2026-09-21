#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.1-systemd book.
# source : book/13.1/chapter08/mpc.html
# title  : 8.25 MPC-1.4.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The MPC package contains a library for the arithmetic of complex numbers with
#   ctx: arbitrarily high precision and correct rounding of the result. Approximate build time:
#   ctx: 0.1 SBU Required disk space: 23 MB 8.25.1 Installation of MPC Prepare MPC for
#   ctx: compilation:
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.4.1

# --- block 1 --------------------------------------------------
#   ctx: Compile the package and generate the HTML documentation:
make
make html

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue:
#   TAGS: testsuite   [DISABLED - review]
# make check

# --- block 3 --------------------------------------------------
#   ctx: Install the package and its documentation:
make install
make install-html

