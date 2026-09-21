#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/speex.html
# title  : Speex-1.2.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: -1.2.1.tar.gz Download MD5 sum: e6eb5ddef743a362c8018f260b91dca5 Download size: 904 KB
#   ctx: Estimated disk space required: 5.5 MB Estimated build time: less than 0.1 SBU Speex
#   ctx: Dependencies Required libogg-1.3.6 Optional Valgrind-3.26.0 Installation of Speex This
#   ctx: package consists of two separate tarballs. They need to be extracted and built
#   ctx: independently. Install Speex by running the following commands:
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/speex-1.2.1 &&
make

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. As the root user:
make install

# --- block 2 --------------------------------------------------
#   ctx: Now extract and install the speexdsp package:
cd ..                          &&
tar -xf speexdsp-1.2.1.tar.gz &&
cd speexdsp-1.2.1             &&

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/speexdsp-1.2.1 &&
make

# --- block 3 --------------------------------------------------
#   ctx: Again, as the root user:
make install

