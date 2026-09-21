#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/multimedia/x265.html
# title  : x265-4.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: nload (HTTP): https://bitbucket.org/multicoreware/x265_git/downloads/x265_4.2.tar.gz
#   ctx: Download MD5 sum: 0a7edcf495aba9f320047d61647d610b Download size: 1.8 MB Estimated disk
#   ctx: space required: 49 MB Estimated build time: 0.4 SBU (using parallelism=4) x265
#   ctx: Dependencies Required CMake-4.4.2 Recommended NASM-3.02 Optional numactl Installation of
#   ctx: x265 First, fix building this package for 32-bit platforms:
sed -i 's/FORMAT_ELF/UNIX64 \&\& FORMAT_ELF/' source/common/x86/cpu-a.asm

# --- block 1 --------------------------------------------------
#   ctx: Install x265 by running the following commands:
mkdir bld &&
cd    bld &&

cmake -D CMAKE_INSTALL_PREFIX=/usr \
      -D GIT_ARCHETYPE=1           \
      -W no-author                 \
      ../source                    &&
make

# --- block 2 --------------------------------------------------
#   ctx: This package does not come with a test suite. To install the package, first remove any
#   ctx: old library versions. After installation, remove a static library. As the root user:
make install &&
rm -vf /usr/lib/libx265.a

