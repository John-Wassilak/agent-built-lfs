#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/postlfs/nettle.html
# title  : Nettle-4.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: nload (HTTP): https://ftpmirror.gnu.org/nettle/nettle-4.0.tar.gz Download MD5 sum:
#   ctx: 144401453f9f35e53938bcacfc59800e Download size: 2.5 MB Estimated disk space required:
#   ctx: 106 MB (with tests) Estimated build time: 0.3 SBU (with tests; both using parallelism=4)
#   ctx: Nettle Dependencies Optional Valgrind-3.27.1 (optional for the tests) Installation of
#   ctx: Nettle Install Nettle by running the following commands:
./configure --prefix=/usr --disable-static &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install &&
chmod   -v   755 /usr/lib/lib{hogweed,nettle}.so &&
install -v -m755 -d /usr/share/doc/nettle-4.0 &&
install -v -m644 nettle.{html,pdf} /usr/share/doc/nettle-4.0

