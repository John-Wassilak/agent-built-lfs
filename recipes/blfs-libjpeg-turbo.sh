#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/libjpeg.html
# title  : libjpeg-turbo-3.2.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: f9f1c735b57d3cdd66daed1ba6bb4 Download size: 2.5 MB Estimated disk space required: 59 MB
#   ctx: (with tests) Estimated build time: 0.6 SBU (with tests; both using parallelism=4)
#   ctx: libjpeg-turbo Dependencies Required CMake-4.4.2 Recommended NASM-3.02 or yasm-1.3.0 (for
#   ctx: building the package with optimized assembly routine) Installation of libjpeg-turbo
#   ctx: Install libjpeg-turbo by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr        \
      -D CMAKE_BUILD_TYPE=RELEASE         \
      -D ENABLE_STATIC=FALSE              \
      -D CMAKE_INSTALL_DEFAULT_LIBDIR=lib \
      -D CMAKE_SKIP_INSTALL_RPATH=ON      \
      -D CMAKE_INSTALL_DOCDIR=/usr/share/doc/libjpeg-turbo-3.2.0 \
      .. &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make test. Now, as the root user:
make install

