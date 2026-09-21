#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/kde/qtkeychain.html
# title  : qtkeychain-0.15.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: on Download (HTTP):
#   ctx: https://github.com/frankosterfeld/qtkeychain/archive/0.15.0/qtkeychain-0.15.0.tar.gz
#   ctx: Download MD5 sum: 00b01588862ba1ed4e6cb81a959108c3 Download size: 56 KB Estimated disk
#   ctx: space required: 3.0 MB Estimated build time: less than 0.1 SBU (Using parallelism=4)
#   ctx: qtkeychain Dependencies Required Qt-6.10.2 Installation of qtkeychain Install qtkeychain
#   ctx: by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=$QT6DIR \
      -D CMAKE_BUILD_TYPE=Release     \
      -D BUILD_WITH_QT6=ON            \
      -D BUILD_TESTING=OFF            \
      -W no-dev ..                    &&
make

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make install

