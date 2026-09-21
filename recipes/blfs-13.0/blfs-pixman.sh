#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/pixman.html
# title  : Pixman-0.46.4
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: https://www.cairographics.org/releases/pixman-0.46.4.tar.gz Download MD5 sum:
#   ctx: c08173c8e1d2cc79428d931c13ffda59 Download size: 808 KB Estimated disk space required: 28
#   ctx: MB (With tests) Estimated build time: 0.1 SBU (Using parallelism=4; with tests) Pixman
#   ctx: Dependencies Optional libpng-1.6.55 and GTK-3.24.51 (for tests and demos) Installation
#   ctx: of Pixman Install Pixman by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install

