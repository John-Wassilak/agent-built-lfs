#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/man-pages.html
# title  : 8.3. Man-pages-6.17
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Man-pages package contains over 2,400 man pages. Approximate build time: 0.1 SBU
#   ctx: Required disk space: 54 MB 8.3.1. Installation of Man-pages Remove two man pages for
#   ctx: password hashing functions. Libxcrypt will provide a better version of these man pages:
rm -v man3/crypt*

# --- block 1 --------------------------------------------------
#   ctx: Install Man-pages by running:
make -R GIT=false prefix=/usr install

