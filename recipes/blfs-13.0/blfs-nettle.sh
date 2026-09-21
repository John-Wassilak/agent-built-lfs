#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/postlfs/nettle.html
# title  : Nettle-3.10.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ad (HTTP): https://ftpmirror.gnu.org/nettle/nettle-3.10.2.tar.gz Download MD5 sum:
#   ctx: b28bcbf6f045ff007940a9401673600d Download size: 2.5 MB Estimated disk space required:
#   ctx: 102 MB (with tests) Estimated build time: 0.2 SBU (with tests; both using parallelism=4)
#   ctx: Nettle Dependencies Optional Valgrind-3.26.0 (optional for the tests) Installation of
#   ctx: Nettle Install Nettle by running the following commands:
./configure --prefix=/usr --disable-static &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install &&
chmod   -v   755 /usr/lib/lib{hogweed,nettle}.so &&
install -v -m755 -d /usr/share/doc/nettle-3.10.2 &&
install -v -m644 nettle.{html,pdf} /usr/share/doc/nettle-3.10.2

