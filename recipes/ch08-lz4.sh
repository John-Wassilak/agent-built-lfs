#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/lz4.html
# title  : 8.9. Lz4-1.10.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Lz4 is a lossless compression algorithm, providing compression speed greater than 500
#   ctx: MB/s per core. It features an extremely fast decoder, with speed in multiple GB/s per
#   ctx: core. Lz4 can work with Zstandard to allow both algorithms to compress data faster.
#   ctx: Approximate build time: 0.1 SBU Required disk space: 4.2 MB 8.9.1. Installation of Lz4
#   ctx: Compile the package:
make BUILD_STATIC=no PREFIX=/usr

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue:
#   TAGS: testsuite   [DISABLED - review]
# make -j1 check

# --- block 2 --------------------------------------------------
#   ctx: Install the package:
make BUILD_STATIC=no PREFIX=/usr install

