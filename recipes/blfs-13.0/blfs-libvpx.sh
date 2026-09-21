#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/libvpx.html
# title  : libvpx-1.16.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Doxygen-1.16.1 (to build documentation) Note An Internet connection is needed for some
#   ctx: tests of this package. The system certificate store may need to be set up with
#   ctx: make-ca-1.16.1 before testing this package. Installation of libvpx If upgrading from a
#   ctx: previous version of libvpx, update the timestamps of all the files to prevent the build
#   ctx: system from retaining the files from the old installation:
find -type f | xargs touch

# --- block 1 --------------------------------------------------
#   ctx: Next, fix a security vulnerability:
patch -Np1 -i ../libvpx-1.16.0-security_fix-1.patch

# --- block 2 --------------------------------------------------
#   ctx: Install libvpx by running the following commands:
sed -i 's/cp -p/cp/' build/make/Makefile &&

mkdir libvpx-build            &&
cd    libvpx-build            &&

../configure --prefix=/usr    \
             --enable-shared  \
             --disable-static &&
make

# --- block 3 --------------------------------------------------
#   ctx: To test the results, issue: LD_LIBRARY_PATH=. make test. The test suite downloads many
#   ctx: files as part of its test process. A few parts of it will use all available cores. Now,
#   ctx: as the root user:
make install

