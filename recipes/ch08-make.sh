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
chown -R tester .
su tester -c "PATH=$PATH make check"

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make install

