#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/dejagnu.html
# title  : 8.19. DejaGNU-1.6.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The DejaGnu package contains a framework for running test suites on GNU tools. It is
#   ctx: written in expect, which itself uses Tcl (Tool Command Language). Approximate build
#   ctx: time: less than 0.1 SBU Required disk space: 6.9 MB 8.19.1. Installation of DejaGNU The
#   ctx: upstream recommends building DejaGNU in a dedicated build directory:
mkdir -v build
cd       build

# --- block 1 --------------------------------------------------
#   ctx: Prepare DejaGNU for compilation:
../configure --prefix=/usr
makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue:
#   TAGS: testsuite   [DISABLED - review]
# make check

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make install
install -v -dm755  /usr/share/doc/dejagnu-1.6.3
install -v -m644   doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3

