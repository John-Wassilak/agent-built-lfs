#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/raptor.html
# title  : Raptor-2.0.16
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 2.0.16.tar.gz Download MD5 sum: 0a71f13b6eaa0a04bf411083d89d7bc2 Download size: 1.7 MB
#   ctx: Estimated disk space required: 25 MB (additional 2 MB for the tests) Estimated build
#   ctx: time: 0.1 SBU (additional 0.3 SBU for the tests) Raptor Dependencies Required
#   ctx: cURL-8.18.0 and libxslt-1.1.45 Optional GTK-Doc-1.35.1, ICU-78.2 and libyajl
#   ctx: Installation of Raptor First, fix an incompatibility with libxml2-2.11.x:
sed -i 's/20627/20627 \&\& LIBXML_VERSION < 21100/' src/raptor_libxml.c

# --- block 1 --------------------------------------------------
#   ctx: Install Raptor by running the following commands:
./configure --prefix=/usr --disable-static &&
make

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue: make check. Several of the XML tests may fail. Now, as the
#   ctx: root user:
make install

