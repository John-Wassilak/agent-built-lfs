#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.1-systemd book.
# source : book/13.1/chapter08/openssl.html
# title  : 8.49 OpenSSL-4.0.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The OpenSSL package contains management tools and libraries relating to cryptography.
#   ctx: These are useful for providing cryptographic functions to other packages, such as
#   ctx: OpenSSH, email applications, and web browsers (for accessing HTTPS sites). Approximate
#   ctx: build time: 1.9 SBU Required disk space: 1.0 GB 8.49.1 Installation of OpenSSL Prepare
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
#   REVIEWED [drop]: Test suite outside the critical three (glibc/gcc/binutils), so out of scope per the tests policy. It also cannot run any more: ch08-cleanup deleted the 'tester' account it needs, so a re-run fails with "chown: invalid user: 'tester'". These tests did run and pass during the original build, while tester still existed. Command text updated for the 2026-09-07 LFS 13.1 bump: the book dropped the `HARNESS_JOBS=$(nproc)` prefix, now just `make test` -- same test suite, same reason to drop it.
# make test

# --- block 3 --------------------------------------------------
#   ctx: s not have CONFIG_CRYPTO_USER_API_SKCIPHER enabled, or does not have any options
#   ctx: providing an AES with CBC implementation (for example, the combination of
#   ctx: CONFIG_CRYPTO_AES and CONFIG_CRYPTO_CBC, or CONFIG_CRYPTO_AES_NI_INTEL if the CPU
#   ctx: supports AES-NI) enabled. If it fails, it can safely be ignored. Install the package
#   ctx: (setting an empty INSTALL_LIBS prevents the installation of static libraries):
make INSTALL_LIBS= MANSUFFIX=ssl install

# --- block 4 --------------------------------------------------
#   ctx: Add the version to the documentation directory name, to be consistent with other
#   ctx: packages:
mv -v /usr/share/doc/openssl /usr/share/doc/openssl-4.0.1

# --- block 5 --------------------------------------------------
#   ctx: If desired, install some additional documentation:
cp -vfr doc/* /usr/share/doc/openssl-4.0.1

