#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libmypaint.html
# title  : libmypaint-1.6.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 7 Download size: 508 KB Estimated disk space required: 11 MB (add 1 MB for tests)
#   ctx: Estimated build time: 0.1 SBU (add 0.3 SBU for tests) libmypaint Dependencies Required
#   ctx: JSON-C-0.18 Recommended GLib-2.86.4 (with GObject Introspection) Optional Doxygen-1.16.1
#   ctx: (to create XML docs), gegl (0.3 versions only) and gperftools Installation of libmypaint
#   ctx: Install libmypaint by running the following commands:
./configure --prefix=/usr &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

