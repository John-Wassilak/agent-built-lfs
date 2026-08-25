#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter07/texinfo.html
# title  : 7.11. Texinfo-7.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Texinfo package contains programs for reading, writing, and converting info pages.
#   ctx: Approximate build time: 0.2 SBU Required disk space: 152 MB 7.11.1. Installation of
#   ctx: Texinfo Prepare Texinfo for compilation:
./configure --prefix=/usr

# --- block 1 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: Install the package:
make install

