#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libseccomp.html
# title  : libseccomp-2.6.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 2d42bcde31fd6e994fcf251a1f71d487 Download size: 672 KB Estimated disk space required:
#   ctx: 7.6 MB (additional 6.3 MB for tests) Estimated build time: less than 0.1 SBU (additional
#   ctx: 1.7 SBU for tests) libseccomp Dependencies Optional Which-2.23 (needed for tests),
#   ctx: Valgrind-3.26.0, cython-3.2.4 (for python bindings), and LCOV Installation of libseccomp
#   ctx: Install libseccomp by running the following commands:
./configure --prefix=/usr --disable-static &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

