#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/libXdmcp.html
# title  : libXdmcp-1.1.5
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 5.tar.xz Download MD5 sum: ce0af51de211e4c99a111e64ae1df290 Download size: 292 KB
#   ctx: Estimated disk space required: 3.0 MB (with test) Estimated build time: less than 0.1
#   ctx: SBU (with test) libXdmcp Dependencies Required xorgproto-2025.1 Optional xmlto-0.0.29,
#   ctx: fop-2.11, libxslt-1.1.45, and Xorg-SGML-doctools (for documentation) Installation of
#   ctx: libXdmcp Install libXdmcp by running the following commands:
./configure $XORG_CONFIG --docdir='${datadir}'/doc/libXdmcp-1.1.5 &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

