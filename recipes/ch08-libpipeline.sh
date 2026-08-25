#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/libpipeline.html
# title  : 8.70. Libpipeline-1.5.8
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Libpipeline package contains a library for manipulating pipelines of subprocesses in
#   ctx: a flexible and convenient way. Approximate build time: 0.1 SBU Required disk space: 10
#   ctx: MB 8.70.1. Installation of Libpipeline Prepare Libpipeline for compilation:
./configure --prefix=/usr

# --- block 1 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: The tests require the Check library that we've removed from LFS. Install the package:
make install

