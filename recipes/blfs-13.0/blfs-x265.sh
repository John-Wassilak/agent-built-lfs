#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/x265.html
# title  : x265-4.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: oreware/x265_git/downloads/x265_4.1.tar.gz Download MD5 sum:
#   ctx: f1c3c80248d8574378a4aac8f374f6de Download size: 1.6 MB Estimated disk space required: 39
#   ctx: MB Estimated build time: 0.4 SBU (using parallelism=4) x265 Dependencies Required
#   ctx: CMake-4.2.3 Recommended NASM-3.01 Optional numactl Installation of x265 First, remove
#   ctx: some CMake policy settings that are no longer compatible with CMake-4.0 and later:
sed -r '/cmake_policy.*(0025|0054)/d' -i source/CMakeLists.txt

# --- block 1 --------------------------------------------------
#   ctx: Install x265 by running the following commands:
mkdir bld &&
cd    bld &&

cmake -D CMAKE_INSTALL_PREFIX=/usr        \
      -D GIT_ARCHETYPE=1                  \
      -D CMAKE_POLICY_VERSION_MINIMUM=3.5 \
      -W no-dev                           \
      ../source                           &&
make

# --- block 2 --------------------------------------------------
#   ctx: This package does not come with a test suite. To install the package, first remove any
#   ctx: old library versions. After installation, remove a static library. As the root user:
make install &&
rm -vf /usr/lib/libx265.a

