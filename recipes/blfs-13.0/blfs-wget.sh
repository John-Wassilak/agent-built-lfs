#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/basicnet/wget.html
# title  : Wget-1.25.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 27 MB for tests) Estimated build time: 0.3 SBU (add 0.4 SBU for tests) Wget
#   ctx: Dependencies Recommended libpsl-0.21.5 Recommended at runtime make-ca-1.16.1 Optional
#   ctx: GnuTLS-3.8.12, HTTP-Daemon-6.16 (for the test suite), IO-Socket-SSL-2.098 (for the test
#   ctx: suite), libidn2-2.3.8, libproxy-0.5.12, and Valgrind-3.26.0 (for the test suite)
#   ctx: Installation of Wget Install Wget by running the following commands:
./configure --prefix=/usr      \
            --sysconfdir=/etc  \
            --with-ssl=openssl &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

