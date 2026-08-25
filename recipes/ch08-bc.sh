#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/bc.html
# title  : 8.15. Bc-7.0.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Bc package contains an arbitrary precision numeric processing language. Approximate
#   ctx: build time: less than 0.1 SBU Required disk space: 7.8 MB 8.15.1. Installation of Bc
#   ctx: Prepare Bc for compilation:
CC='gcc -std=c99' ./configure --prefix=/usr -G -O3 -r

# --- block 1 --------------------------------------------------
#   ctx: The meaning of the configure options: CC='gcc -std=c99' This parameter specifies the
#   ctx: compiler and C standard to use. -G Omit parts of the test suite that won't work until
#   ctx: the bc program has been installed. -O3 Specify the optimization to use. -r Enable the
#   ctx: use of Readline to improve the line editing feature of bc. Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: To test bc, run:
#   TAGS: testsuite   [DISABLED - review]
# make test

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make install

