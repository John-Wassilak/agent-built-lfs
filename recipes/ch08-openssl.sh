#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/openssl.html
# title  : 8.49. OpenSSL-3.6.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The OpenSSL package contains management tools and libraries relating to cryptography.
#   ctx: These are useful for providing cryptographic functions to other packages, such as
#   ctx: OpenSSH, email applications, and web browsers (for accessing HTTPS sites). Approximate
#   ctx: build time: 1.9 SBU Required disk space: 981 MB 8.49.1. Installation of OpenSSL Prepare
#   ctx: OpenSSL for compilation:
./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic

# --- block 1 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue:
#   REVIEWED [drop]: Test suite outside the critical three (glibc/gcc/binutils), so out of scope per the tests policy. It also cannot run any more: ch08-cleanup deleted the 'tester' account it needs, so a re-run fails with "chown: invalid user: 'tester'". These tests did run and pass during the original build, while tester still existed.
# HARNESS_JOBS=$(nproc) make test

# --- block 3 --------------------------------------------------
#   ctx: One test, 30-test_afalg.t, is known to fail if the host kernel does not have
#   ctx: CONFIG_CRYPTO_USER_API_SKCIPHER enabled, or does not have any options providing an AES
#   ctx: with CBC implementation (for example, the combination of CONFIG_CRYPTO_AES and
#   ctx: CONFIG_CRYPTO_CBC, or CONFIG_CRYPTO_AES_NI_INTEL if the CPU supports AES-NI) enabled. If
#   ctx: it fails, it can safely be ignored. Install the package:
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install

# --- block 4 --------------------------------------------------
#   ctx: Add the version to the documentation directory name, to be consistent with other
#   ctx: packages:
mv -v /usr/share/doc/openssl /usr/share/doc/openssl-3.6.1

# --- block 5 --------------------------------------------------
#   ctx: If desired, install some additional documentation:
cp -vfr doc/* /usr/share/doc/openssl-3.6.1

