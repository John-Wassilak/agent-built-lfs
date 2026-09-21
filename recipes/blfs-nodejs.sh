#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/nodejs.html
# title  : Node.js-24.19.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: res-1.34.8, ICU-78.3, libuv-1.52.1, nghttp2-1.70.0, and simdutf-9.0.0 Optional
#   ctx: http-parser and npm (an internal copy of npm will be installed if not present) Note An
#   ctx: Internet connection is needed for some tests of this package. The system certificate
#   ctx: store may need to be set up with make-ca-1.16.1 before testing this package.
#   ctx: Installation of Node.js Build Node.js by running the following commands:
./configure --prefix=/usr    \
            --shared-openssl \
            --shared-zlib &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make test-only. Now, as the root user:
make install &&
ln -sf node /usr/share/doc/node-24.19.0

