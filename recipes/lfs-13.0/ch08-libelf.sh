#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/libelf.html
# title  : 8.50. Libelf from Elfutils-0.194
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Libelf is a library for handling ELF (Executable and Linkable Format) files. Approximate
#   ctx: build time: 0.1 SBU Required disk space: 41 MB 8.50.1. Installation of Libelf Libelf is
#   ctx: part of the elfutils-0.194 package. Use the elfutils-0.194.tar.bz2 file as the source
#   ctx: tarball. Prepare Libelf for compilation:
./configure --prefix=/usr        \
            --disable-debuginfod \
            --enable-libdebuginfod=dummy

# --- block 1 --------------------------------------------------
#   ctx: Compile only Libelf:
make -C lib
make -C libelf

# --- block 2 --------------------------------------------------
#   ctx: The test suite fails to build with glibc-2.43 or newer. Install only Libelf:
make -C libelf install
install -vm644 config/libelf.pc /usr/lib/pkgconfig
rm /usr/lib/libelf.a

