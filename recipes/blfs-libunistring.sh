#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libunistring.html
# title  : libunistring-1.4.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: r.xz Download MD5 sum: 7419fcbca7c0b29d3b218a09a15cbc76 Download size: 2.6 MB Estimated
#   ctx: disk space required: 58 MB (add 46 MB for tests) Estimated build time: 0.6 SBU (add 0.3
#   ctx: SBU for tests; both using parallelism=4) libunistring Dependencies Optional
#   ctx: texlive-20250308 (or install-tl-unx) (to rebuild the documentation) Installation of
#   ctx: libunistring First, make a fix required by glibc-2.43 and later:
sed -r '/_GL_EXTERN_C/s/w?memchr|bsearch/(&)/' \
    -i $(find -name \*.in.h)

# --- block 1 --------------------------------------------------
#   ctx: Install libunistring by running the following commands:
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/libunistring-1.4.1 &&
make

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

