#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/groff.html
# title  : 8.65. Groff-1.23.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 108 MB 8.65.1. Installation of Groff Groff expects the environment variable PAGE to
#   ctx: contain the default paper size. For users in the United States, PAGE=letter is
#   ctx: appropriate. Elsewhere, PAGE=A4 may be more suitable. While the default paper size is
#   ctx: configured during compilation, it can be overridden later by echoing either “A4” or
#   ctx: “letter” to the /etc/papersize file. Prepare Groff for compilation:
PAGE=letter ./configure --prefix=/usr

# --- block 1 --------------------------------------------------
#   ctx: Build the package:
make

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue:
#   TAGS: testsuite   [DISABLED - review]
# make check

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make install

