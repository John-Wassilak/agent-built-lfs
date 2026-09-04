#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/postlfs/gpgme.html
# title  : gpgme-2.0.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: gpgme-2.0.1.tar.bz2 Download MD5 sum: 73b6d337d02e1829323ef44830e92117 Download size:
#   ctx: 1.3 MB Estimated disk space required: 25 MB (with tests) Estimated build time: 0.2 SBU
#   ctx: (with tests and parallelism=4) gpgme Dependencies Required libassuan-3.0.2 Recommended
#   ctx: GnuPG-2.5.17 (as per upstream recommendation) Optional Doxygen-1.16.1 Installation of
#   ctx: gpgme Install gpgme by running the following commands:
mkdir build &&
cd    build &&

../configure --prefix=/usr --disable-static &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, you should have GnuPG-2.5.17 installed. If so, run:
#   TAGS: testsuite   [DISABLED - review]
# make -k check

# --- block 2 --------------------------------------------------
#   ctx: Now, as the root user:
make install

