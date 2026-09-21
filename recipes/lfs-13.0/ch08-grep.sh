#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/grep.html
# title  : 8.36. Grep-3.12
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Grep package contains programs for searching through the contents of files.
#   ctx: Approximate build time: 0.5 SBU Required disk space: 48 MB 8.36.1. Installation of Grep
#   ctx: First, remove a warning about using egrep and fgrep that makes tests on some packages
#   ctx: fail:
sed -i "s/echo/#echo/" src/egrep.sh

# --- block 1 --------------------------------------------------
#   ctx: Prepare Grep for compilation:
./configure --prefix=/usr

# --- block 2 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 3 --------------------------------------------------
#   ctx: To test the results, issue:
#   TAGS: testsuite   [DISABLED - review]
# make check

# --- block 4 --------------------------------------------------
#   ctx: Install the package:
make install

