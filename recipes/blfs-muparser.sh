#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/lxqt/muparser.html
# title  : muparser-2.3.5
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ing an LFS 13.0 platform. Package Information Download (HTTP):
#   ctx: https://github.com/beltoforion/muparser/archive/v2.3.5/muparser-2.3.5.tar.gz Download
#   ctx: MD5 sum: 04d4224cb01712207b85af05a255b6fc Download size: 116 KB Estimated disk space
#   ctx: required: 4.6 MB Estimated build time: 0.1 SBU muparser Dependencies Required
#   ctx: CMake-4.2.3 Installation of muparser Install muparser by running the following commands:
mkdir -v build &&
cd       build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_BUILD_TYPE=Release  \
      ..                           &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make test. Now, as the root user:
make install

