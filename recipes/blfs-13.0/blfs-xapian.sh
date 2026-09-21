#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/xapian.html
# title  : Xapian-1.4.30
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: /oligarchy.co.uk/xapian/1.4.30/xapian-core-1.4.30.tar.xz Download MD5 sum:
#   ctx: 4f767035ec2b710f98fbe07a48fabfb1 Download size: 3.2 MB Estimated disk space required:
#   ctx: 146 MB (add 168 MB for tests) Estimated build time: 0.5 SBU (add 9.1 SBU for tests; both
#   ctx: using parallelism=4) Xapian Dependencies Optional Valgrind-3.26.0 (for tests)
#   ctx: Installation of Xapian Install Xapian by running the following commands:
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xapian-core-1.4.30 &&
make

# --- block 1 --------------------------------------------------
#   ctx: To run the test suite, issue: make check. Now, as the root user:
make install

