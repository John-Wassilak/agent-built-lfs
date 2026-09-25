#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/graphviz.html
# title  : Graphviz-14.1.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ard coding library search paths (rpath) into the shared libraries. The libraries do not
#   ctx: need the rpath for an installation into the standard location, and rpath may sometimes
#   ctx: cause unwanted effects or even security issues. We cannot use -D
#   ctx: CMAKE_SKIP_INSTALL_RPATH=ON for this package because the rpath is really needed for the
#   ctx: programs installed by this package, so we need to edit the build system:
sed '/ORIGIN/d' -i lib/CMakeLists.txt

# --- block 1 --------------------------------------------------
#   ctx: Install Graphviz by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_BUILD_TYPE=Release  \
      ..                           &&

sed -i '/GZIP/s/:.*$/=/' CMakeCache.txt &&

make

# --- block 2 --------------------------------------------------
#   ctx: This package does not come with a test suite that provides meaningful results. Now, as
#   ctx: the root user:
make install

