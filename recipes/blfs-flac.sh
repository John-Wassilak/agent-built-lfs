#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/flac.html
# title  : FLAC-1.5.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: .tar.xz Download MD5 sum: 0bb45bcf74338b00efeec121fff27367 Download size: 1.1 MB
#   ctx: Estimated disk space required: 25 MB (additional 170 MB to run the test suite) Estimated
#   ctx: build time: 0.2 SBU (additional 0.2 SBU to run the test suite) FLAC Dependencies
#   ctx: Optional libogg-1.3.6, DocBook-utils-0.6.14, Doxygen-1.16.1, and Valgrind-3.26.0
#   ctx: Installation of FLAC Install FLAC by running the following commands:
./configure --prefix=/usr            \
            --disable-thorough-tests \
            --docdir=/usr/share/doc/flac-1.5.0 &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Note that if you passed the
#   ctx: --enable-exhaustive-tests and --enable-valgrind-testing parameters to configure and then
#   ctx: run the test suite, it will take a very long time (up to 300 SBUs) and use about 375 MB
#   ctx: of disk space. Now, as the root user:
make install

