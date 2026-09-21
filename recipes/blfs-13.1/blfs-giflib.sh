#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/giflib.html
# title  : giflib-6.1.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: et/projects/giflib/files/giflib-6.1.3.tar.gz Download MD5 sum:
#   ctx: a70e90ff780e9ebee9cb84b82bbd46a7 Download size: 460 KB Estimated disk space required:
#   ctx: 4.2 MB (with documentation) Estimated build time: less than 0.1 SBU (with documentation)
#   ctx: giflib Dependencies Optional xmlto-0.0.29 (required if you run make after make clean)
#   ctx: [1] Installation of giflib Install giflib by running the following commands:
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make PREFIX=/usr \
     DOCDIR=/usr/share/doc/giflib-6.1.3 install &&

rm -fv /usr/lib/libgif.a

