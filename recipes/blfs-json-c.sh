#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/json-c.html
# title  : json-c-0.19
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: zonaws.com/json-c_releases/releases/json-c-0.19.tar.gz Download MD5 sum:
#   ctx: 5678f1373ba51e0041b574c0411c696b Download size: 452 KB Estimated disk space required: 12
#   ctx: MB Estimated build time: 0.2 SBU (with tests) json-c Dependencies Required CMake-4.4.2
#   ctx: Optional (for documentation) Doxygen-1.18.0 and Graphviz-15.1.1 (for dot tool)
#   ctx: Installation of json-c Install json-c by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_BUILD_TYPE=Release  \
      -D BUILD_STATIC_LIBS=OFF     \
      .. &&
make

# --- block 1 --------------------------------------------------
#   ctx: If you have installed Doxygen-1.18.0 and Graphviz-15.1.1, you can build the
#   ctx: documentation by running the following command:
#   REVIEWED [drop]: Optional doxygen docs, not installed. Reindexed for the 2026-09-07 BLFS 13.1 bump (server; see book/blfs-13.1 vs book/blfs-13.0). Old index 2 -> 1: the book dropped the 'sed VERSION 2.8->4.0 CMakeLists.txt' block (no longer needed in json-c 0.19), shifting everything after it one position earlier.
# doxygen doc/Doxyfile

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue: make USE_VALGRIND=0 test. Note that testing with the latest
#   ctx: valgrind causes several test failures. Now, as the root user:
make install

# --- block 3 --------------------------------------------------
#   ctx: If you built the documentation, install it by running the following commands as the root
#   ctx: user:
#   REVIEWED [drop]: Installs the doxygen docs from block 2, which was dropped. Reindexed for the 2026-09-07 BLFS 13.1 bump (server; see book/blfs-13.1 vs book/blfs-13.0). Old index 4 -> 3 (same cause as block 1's reindex).
# install -d -vm755 /usr/share/doc/json-c-0.19 &&
# install -v -m644 doc/html/* /usr/share/doc/json-c-0.19

