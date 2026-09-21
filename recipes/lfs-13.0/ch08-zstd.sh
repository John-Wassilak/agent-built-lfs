#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/zstd.html
# title  : 8.10. Zstd-1.5.7
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Zstandard is a real-time compression algorithm, providing high compression ratios. It
#   ctx: offers a very wide range of compression / speed trade-offs, while being backed by a very
#   ctx: fast decoder. Approximate build time: 0.4 SBU Required disk space: 86 MB 8.10.1.
#   ctx: Installation of Zstd Compile the package:
make prefix=/usr

# --- block 1 --------------------------------------------------
#   ctx: Note In the test output there are several places that indicate 'failed'. These are
#   ctx: expected and only 'FAIL' is an actual test failure. There should be no test failures. To
#   ctx: test the results, issue:
#   TAGS: testsuite   [DISABLED - review]
# make check

# --- block 2 --------------------------------------------------
#   ctx: Install the package:
make prefix=/usr install

# --- block 3 --------------------------------------------------
#   ctx: Remove the static library:
rm -v /usr/lib/libzstd.a

