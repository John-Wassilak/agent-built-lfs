#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/pinentry.html
# title  : pinentry-1.3.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: bz2 Download MD5 sum: 5247373d2e9ac73b1ea662bd270e58a4 Download size: 600 KB Estimated
#   ctx: disk space required: 17 MB Estimated build time: 0.2 SBU PIN-Entry Dependencies Required
#   ctx: libassuan-3.0.2 and libgpg-error-1.59 Optional Emacs-30.2, FLTK-1.4.4, Gcr-4.4.0.1 (or
#   ctx: Gcr-3.41.2), KDE Frameworks-6.23.0, libsecret-0.21.7, and efl Installation of PIN-Entry
#   ctx: First, make configure consistent with fltk-1.4.1:
sed -i "/FLTK 1/s/3/4/" configure   &&
sed -i '14456 s/1.3/1.4/' configure

# --- block 1 --------------------------------------------------
#   ctx: Install PIN-Entry by running the following commands:
./configure --prefix=/usr          \
            --enable-pinentry-tty  &&
make

# --- block 2 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make install

