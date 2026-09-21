#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/libxcrypt.html
# title  : 8.28. Libxcrypt-4.5.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Libxcrypt package contains a modern library for one-way hashing of passwords.
#   ctx: Approximate build time: 0.1 SBU Required disk space: 14 MB 8.28.1. Installation of
#   ctx: Libxcrypt First, make a fix required by glibc-2.43 and later:
sed -i '/strchr/s/const//' lib/crypt-{sm3,gost}-yescrypt.c

# --- block 1 --------------------------------------------------
#   ctx: Prepare Libxcrypt for compilation:
./configure --prefix=/usr                \
            --enable-hashes=strong,glibc \
            --enable-obsolete-api=no     \
            --disable-static             \
            --disable-failure-tokens

# --- block 2 --------------------------------------------------
#   ctx: rithms provided by traditional Glibc libcrypt for compatibility.
#   ctx: --enable-obsolete-api=no Disable obsolete API functions. They are not needed for a
#   ctx: modern Linux system built from source. --disable-failure-tokens Disable failure token
#   ctx: feature. It's needed for compatibility with the traditional hash libraries of some
#   ctx: platforms, but a Linux system based on Glibc does not need it. Compile the package:
make

# --- block 3 --------------------------------------------------
#   ctx: To test the results, issue:
#   TAGS: testsuite   [DISABLED - review]
# make check

# --- block 4 --------------------------------------------------
#   ctx: Install the package:
make install

# --- block 5 --------------------------------------------------
#   ctx: instructions above disabled obsolete API functions since no package installed by
#   ctx: compiling from sources would link against them at runtime. However, the only known
#   ctx: binary-only applications that link against these functions require ABI version 1. If you
#   ctx: must have such functions because of some binary-only application or to be compliant with
#   ctx: LSB, build the package again with the following commands:
#   REVIEWED [drop]: Optional rebuild providing obsolete API ABI 1, only 'if you must have such functions' for binary-only apps or LSB compliance. Not needed.
# make distclean
# ./configure --prefix=/usr                \
#             --enable-hashes=strong,glibc \
#             --enable-obsolete-api=glibc  \
#             --disable-static             \
#             --disable-failure-tokens
# make
# cp -av --remove-destination .libs/libcrypt.so.1* /usr/lib

