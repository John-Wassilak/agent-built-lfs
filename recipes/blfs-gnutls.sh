#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/postlfs/gnutls.html
# title  : GnuTLS-3.8.12
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 20250308 or install-tl-unx, Valgrind-3.26.0 (used during the test suite), autogen,
#   ctx: cmocka and (used during the test suite if the DANE library is built), leancrypto, and
#   ctx: Trousers (Trusted Platform Module support) Note Note that if you do not install
#   ctx: libtasn1-4.21.0, a version shipped in the GnuTLS tarball will be used instead.
#   ctx: Installation of GnuTLS Install GnuTLS by running the following commands:
./configure --prefix=/usr \
            --docdir=/usr/share/doc/gnutls-3.8.12 \
            --with-default-trust-store-pkcs11="pkcs11:" &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, now issue: make check. Now, install the package as the root user:
make install

