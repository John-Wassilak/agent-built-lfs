#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/json-c.html
# title  : JSON-C-0.18
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: zonaws.com/json-c_releases/releases/json-c-0.18.tar.gz Download MD5 sum:
#   ctx: e6593766de7d8aa6e3a7e67ebf1e522f Download size: 396 KB Estimated disk space required:
#   ctx: 7.9 MB Estimated build time: 0.2 SBU (with tests) JSON-C Dependencies Required
#   ctx: CMake-4.2.3 Optional (for documentation) Doxygen-1.16.1 and Graphviz-14.1.2 (for dot
#   ctx: tool) Installation of JSON-C First, fix building this package with CMake-4.0:
sed -i 's/VERSION 2.8/VERSION 4.0/' apps/CMakeLists.txt  &&
sed -i 's/VERSION 3.9/VERSION 4.0/' tests/CMakeLists.txt

# --- block 1 --------------------------------------------------
#   ctx: Install JSON-C by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_BUILD_TYPE=Release  \
      -D BUILD_STATIC_LIBS=OFF     \
      .. &&
make

# --- block 2 --------------------------------------------------
#   ctx: If you have installed Doxygen-1.16.1 and Graphviz-14.1.2, you can build the
#   ctx: documentation by running the following command:
#   REVIEWED [drop]: Optional doxygen docs, not installed.
# doxygen doc/Doxyfile

# --- block 3 --------------------------------------------------
#   ctx: To test the results, issue: make test. Now, as the root user:
make install

# --- block 4 --------------------------------------------------
#   ctx: If you built the documentation, install it by running the following commands as the root
#   ctx: user:
#   REVIEWED [drop]: Installs the doxygen docs from block 2, which was dropped.
# install -d -vm755 /usr/share/doc/json-c-0.18 &&
# install -v -m644 doc/html/* /usr/share/doc/json-c-0.18

