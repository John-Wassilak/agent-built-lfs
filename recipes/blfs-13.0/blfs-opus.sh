#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/opus.html
# title  : Opus-1.6.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: form. Package Information Download (HTTP):
#   ctx: https://downloads.xiph.org/releases/opus/opus-1.6.1.tar.gz Download MD5 sum:
#   ctx: 67cafc438c430aa74eeb605eef670886 Download size: 10 MB Estimated disk space required: 41
#   ctx: MB (with tests) Estimated build time: 0.5 SBU (with tests) Optional Doxygen-1.16.1 and
#   ctx: texlive-20250308 (or install-tl-unx) Installation of Opus Install Opus by running the
#   ctx: following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr        \
            --buildtype=release  \
            -D docdir=/usr/share/doc/opus-1.6.1 &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install

