#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/bison.html
# title  : 8.35. Bison-3.8.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Bison package contains a parser generator. Approximate build time: 2.1 SBU Required
#   ctx: disk space: 63 MB 8.35.1. Installation of Bison Prepare Bison for compilation:
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2

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

