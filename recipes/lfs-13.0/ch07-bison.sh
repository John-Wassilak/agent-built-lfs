#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter07/bison.html
# title  : 7.8. Bison-3.8.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Bison package contains a parser generator. Approximate build time: 0.2 SBU Required
#   ctx: disk space: 58 MB 7.8.1. Installation of Bison Prepare Bison for compilation:
./configure --prefix=/usr \
            --docdir=/usr/share/doc/bison-3.8.2

# --- block 1 --------------------------------------------------
#   ctx: The meaning of the new configure option: --docdir=/usr/share/doc/bison-3.8.2 This tells
#   ctx: the build system to install bison documentation into a versioned directory. Compile the
#   ctx: package:
make

# --- block 2 --------------------------------------------------
#   ctx: Install the package:
make install

