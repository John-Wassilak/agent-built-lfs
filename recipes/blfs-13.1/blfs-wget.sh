#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/basicnet/wget.html
# title  : Wget-1.25.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ies Recommended libpsl-0.23.3 Recommended at runtime make-ca-1.16.1 Optional
#   ctx: GnuTLS-3.8.13, HTTP-Daemon-6.17 (for the test suite), IO-Socket-SSL-2.099 (for the test
#   ctx: suite), libidn2-2.3.8, libproxy-0.5.12, and Valgrind-3.27.1 (for the test suite)
#   ctx: Installation of Wget First, make a fix to make the package compatible with OpenSSL 4.
#   ctx: The bash variable is for presentation purposes due to the long line.
NEW_LINE='#if !defined OPENSSL_NO_SSL3_METHOD '
NEW_LINE+='&& OPENSSL_VERSION_NUMBER < 0x40000000L'

sed -i "/SSL3/c $NEW_LINE" src/openssl.c

unset NEW_LINE 

# --- block 1 --------------------------------------------------
#   ctx: Install Wget by running the following commands:
./configure --prefix=/usr      \
            --sysconfdir=/etc  \
            --with-ssl=openssl &&
make

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

