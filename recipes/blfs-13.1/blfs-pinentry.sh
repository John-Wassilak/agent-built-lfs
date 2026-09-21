#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/pinentry.html
# title  : pinentry-1.3.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ownload MD5 sum: 59a65644180ac2a43a1235d698515b36 Download size: 608 KB Estimated disk
#   ctx: space required: 8.4 MB Estimated build time: 0.2 SBU PIN-Entry Dependencies Required
#   ctx: libassuan-3.0.2 and libgpg-error-1.61 Optional Emacs-31.1, FLTK-1.3.11, Gcr-4.4.0.1 (or
#   ctx: Gcr-3.41.2), KDE Frameworks-6.29.0, libsecret-0.21.7, and efl Installation of PIN-Entry
#   ctx: Install PIN-Entry by running the following commands:
./configure --prefix=/usr          \
            --enable-pinentry-tty  &&
make

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make install

