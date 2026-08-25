#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter05/binutils-pass1.html
# title  : 5.2. Binutils-2.46.0 - Pass 1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: General Compilation Instructions. Understanding the notes labeled important can save you
#   ctx: a lot of problems later. It is important that Binutils be the first package compiled
#   ctx: because both Glibc and GCC perform various tests on the available linker and assembler
#   ctx: to determine which of their own features to enable. The Binutils documentation
#   ctx: recommends building Binutils in a dedicated build directory:
mkdir -v build
cd       build

# --- block 1 --------------------------------------------------
#   ctx: Note In order for the SBU values listed in the rest of the book to be of any use,
#   ctx: measure the time it takes to build this package from the configuration, up to and
#   ctx: including the first install. To achieve this easily, wrap the commands in a time command
#   ctx: like this: time { ../configure ... && make && make install; }. Now prepare Binutils for
#   ctx: compilation:
../configure --prefix=$LFS/tools \
             --with-sysroot=$LFS \
             --target=$LFS_TGT   \
             --disable-nls       \
             --enable-gprofng=no \
             --disable-werror    \
             --enable-new-dtags  \
             --enable-default-hash-style=gnu

# --- block 2 --------------------------------------------------
#   ctx: linker (provided by the Glibc package) will always use the GNU-style hash table which
#   ctx: is faster to query. So the classic ELF hash table is completely useless. This makes the
#   ctx: linker only generate the GNU-style hash table by default, so we can avoid wasting time
#   ctx: to generate the classic ELF hash table when we build the packages, or wasting disk space
#   ctx: to store it. Continue with compiling the package:
make

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make install

