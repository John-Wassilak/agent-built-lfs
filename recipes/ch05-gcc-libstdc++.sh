#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter05/gcc-libstdc++.html
# title  : 5.6. Libstdc++ from GCC-15.2.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: on when we built gcc-pass1 because Libstdc++ depends on Glibc, which was not yet
#   ctx: available in the target directory. Approximate build time: 0.2 SBU Required disk space:
#   ctx: 1.3 GB 5.6.1. Installation of Target Libstdc++ Note Libstdc++ is part of the GCC
#   ctx: sources. You should first unpack the GCC tarball and change to the gcc-15.2.0 directory.
#   ctx: Create a separate build directory for Libstdc++ and enter it:
mkdir -v build
cd       build

# --- block 1 --------------------------------------------------
#   ctx: Prepare Libstdc++ for compilation:
../libstdc++-v3/configure      \
    --host=$LFS_TGT            \
    --build=$(../config.guess) \
    --prefix=/usr              \
    --disable-multilib         \
    --disable-nls              \
    --disable-libstdcxx-pch    \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/15.2.0

# --- block 2 --------------------------------------------------
#   ctx: e, this information must be explicitly given. The C++ compiler will prepend the sysroot
#   ctx: path $LFS (specified when building GCC-pass1) to the include file search path, so it
#   ctx: will actually search in $LFS/tools/$LFS_TGT/include/c++/15.2.0. The combination of the
#   ctx: DESTDIR variable (in the make install command below) and this switch causes the headers
#   ctx: to be installed there. Compile Libstdc++ by running:
make

# --- block 3 --------------------------------------------------
#   ctx: Install the library:
make DESTDIR=$LFS install

# --- block 4 --------------------------------------------------
#   ctx: Remove the libtool archive files because they are harmful for cross-compilation:
rm -v $LFS/usr/lib/lib{stdc++{,exp,fs},supc++}.la

