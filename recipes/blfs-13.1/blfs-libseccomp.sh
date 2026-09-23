#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/libseccomp.html
# title  : libseccomp-2.6.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Download MD5 sum: 33a3a5d4c526a739515ff4dc53cdc192 Download size: 644 KB Estimated disk
#   ctx: space required: 13 MB (with tests) Estimated build time: less than 0.1 SBU (additional
#   ctx: 1.7 SBU for tests) libseccomp Dependencies Optional Which-2.25 (needed for tests),
#   ctx: Valgrind-3.27.1, cython-3.2.9 (for python bindings), and LCOV Installation of libseccomp
#   ctx: Install libseccomp by running the following commands:
./configure --prefix=/usr --disable-static &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

