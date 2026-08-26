#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/libsndfile.html
# title  : libsndfile-1.2.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 2.2.tar.xz Download MD5 sum: 04e2e6f726da7c5dc87f8cf72f250d04 Download size: 716 KB
#   ctx: Estimated disk space required: 12 MB (add 10 MB for tests) Estimated build time: 0.3 SBU
#   ctx: (add 0.3 SBU for tests) libsndfile Dependencies Recommended FLAC-1.5.0, Opus-1.6.1, and
#   ctx: libvorbis-1.3.7 Optional alsa-lib-1.2.15.3, LAME-3.100, mpg123-1.33.4, and Speex-1.2.1
#   ctx: Installation of libsndfile Fix building with GCC-15:
sed -i '/typedef enum/,/bool ;/d' src/ALAC/alac_{en,de}coder.c

# --- block 1 --------------------------------------------------
#   ctx: Install libsndfile by running the following commands:
./configure --prefix=/usr    \
            --docdir=/usr/share/doc/libsndfile-1.2.2 &&
make

# --- block 2 --------------------------------------------------
#   ctx: If running the test suite, disable the Opus tests which would fail with the recent Opus
#   ctx: release and cause the test suite to bail out early:
sed '/ogg_opus/,+1s/HAVE_[A-Z_]*/0/' -i tests/lossy_comp_test.c

# --- block 3 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

