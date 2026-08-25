#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/nodejs.html
# title  : Node.js-22.22.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: li-1.2.0, c-ares-1.34.6, ICU-78.2, libuv-1.52.0, and nghttp2-1.68.0 Optional http-parser
#   ctx: and npm (an internal copy of npm will be installed if not present) Note An Internet
#   ctx: connection is needed for some tests of this package. The system certificate store may
#   ctx: need to be set up with make-ca-1.16.1 before testing this package. Installation of
#   ctx: Node.js First, fix building this package with Python 3.14:
patch -Np1 -i ../node-v22.22.0-python_build_fix-1.patch

# --- block 1 --------------------------------------------------
#   ctx: Build Node.js by running the following commands:
./configure --prefix=/usr    \
            --shared-openssl \
            --shared-zlib &&
make

# --- block 2 --------------------------------------------------
#   ctx: ake test-only. Out of over 4600 tests, about 10 in the 'parallel' test suite are known
#   ctx: to fail. Some failures are due to assumptions about dependent packages like icu and
#   ctx: nghttp2 versions that are earlier than what is in BLFS. Also note that if you pass a
#   ctx: high parallelism option (like -j20; -j8 is fine) to the test procedure, additional tests
#   ctx: will run out of memory and fail. Now, as the root user:
make install &&
ln -sf node /usr/share/doc/node-22.22.0

