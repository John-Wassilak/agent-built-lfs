#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter06/binutils-pass2.html
# title  : 6.17. Binutils-2.46.0 - Pass 2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Approximate build time: 0.4 SBU Required disk space: 557 MB 6.17.1. Installation of
#   ctx: Binutils Binutils building system relies on an shipped libtool copy to link against
#   ctx: internal static libraries, but the libiberty and zlib copies shipped in the package do
#   ctx: not use libtool. This inconsistency may cause produced binaries mistakenly linked
#   ctx: against libraries from the host distro. Work around this issue:
sed '6031s/$add_dir//' -i ltmain.sh

# --- block 1 --------------------------------------------------
#   ctx: Create a separate build directory again:
mkdir -v build
cd       build

# --- block 2 --------------------------------------------------
#   ctx: Prepare Binutils for compilation:
../configure                   \
    --prefix=/usr              \
    --build=$(../config.guess) \
    --host=$LFS_TGT            \
    --disable-nls              \
    --enable-shared            \
    --enable-gprofng=no        \
    --disable-werror           \
    --enable-64-bit-bfd        \
    --enable-new-dtags         \
    --enable-default-hash-style=gnu

# --- block 3 --------------------------------------------------
#   ctx: The meaning of the new configure options: --enable-shared Builds libbfd as a shared
#   ctx: library. --enable-64-bit-bfd Enables 64-bit support (on hosts with smaller word sizes).
#   ctx: This may not be needed on 64-bit systems, but it does no harm. Compile the package:
make

# --- block 4 --------------------------------------------------
#   ctx: Install the package:
make DESTDIR=$LFS install

# --- block 5 --------------------------------------------------
#   ctx: Remove the libtool archive files because they are harmful for cross compilation, and
#   ctx: remove unnecessary static libraries:
rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}

