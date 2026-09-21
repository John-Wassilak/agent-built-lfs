#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/rasqal.html
# title  : Rasqal-0.9.33
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: s://download.librdf.org/source/rasqal-0.9.33.tar.gz Download MD5 sum:
#   ctx: 1f5def51ca0026cd192958ef07228b52 Download size: 1.6 MB Estimated disk space required: 22
#   ctx: MB (additional 4 MB for the tests) Estimated build time: 0.3 SBU (additional 0.7 SBU for
#   ctx: the tests) Rasqal Dependencies Required Raptor-2.0.16 Optional libgcrypt-1.12.0
#   ctx: Installation of Rasqal Install Rasqal by running the following commands:
./configure --prefix=/usr --disable-static &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

