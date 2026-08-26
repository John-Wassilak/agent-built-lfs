#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/popt.html
# title  : Popt-1.19
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: /pub/rpm/popt/releases/popt-1.x/popt-1.19.tar.gz Download MD5 sum:
#   ctx: eaa2135fddb6eb03f2c87ee1823e5a78 Download size: 584 KB Estimated disk space required:
#   ctx: 6.9 MB (includes installing documentation and tests) Estimated build time: less than 0.1
#   ctx: SBU (with tests) popt Dependencies Optional Doxygen-1.16.1 (for generating
#   ctx: documentation) Installation of Popt Install popt by running the following commands:
./configure --prefix=/usr --disable-static &&
make

# --- block 1 --------------------------------------------------
#   ctx: If you have Doxygen-1.16.1 installed and wish to build the API documentation, issue:
#   REVIEWED [drop]: Optional doxygen docs, not installed.
# sed -i 's@\./@src/@' Doxyfile &&
# doxygen

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

# --- block 3 --------------------------------------------------
#   ctx: If you built the API documentation, install it using the following commands issued by
#   ctx: the root user:
#   REVIEWED [drop]: Installs the doxygen docs from block 1, which was dropped.
# install -v -m755 -d /usr/share/doc/popt-1.19 &&
# install -v -m644 doxygen/html/* /usr/share/doc/popt-1.19

