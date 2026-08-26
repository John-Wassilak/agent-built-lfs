#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libjpeg.html
# title  : libjpeg-turbo-3.1.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: f3be7e58ad79d297845e64807472c Download size: 2.4 MB Estimated disk space required: 54 MB
#   ctx: (with tests) Estimated build time: 0.6 SBU (with tests; both using parallelism=4)
#   ctx: libjpeg-turbo Dependencies Required CMake-4.2.3 Recommended NASM-3.01 or yasm-1.3.0 (for
#   ctx: building the package with optimized assembly routine) Installation of libjpeg-turbo
#   ctx: Install libjpeg-turbo by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr        \
      -D CMAKE_BUILD_TYPE=RELEASE         \
      -D ENABLE_STATIC=FALSE              \
      -D CMAKE_INSTALL_DEFAULT_LIBDIR=lib \
      -D CMAKE_SKIP_INSTALL_RPATH=ON      \
      -D CMAKE_INSTALL_DOCDIR=/usr/share/doc/libjpeg-turbo-3.1.3 \
      .. &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make test. Now, as the root user:
make install

