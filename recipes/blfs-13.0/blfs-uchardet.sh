#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/uchardet.html
# title  : Uchardet-0.0.8
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Information Download (HTTP):
#   ctx: https://www.freedesktop.org/software/uchardet/releases/uchardet-0.0.8.tar.xz Download
#   ctx: MD5 sum: 9e267be7aee81417e5875086dd9d44fd Download size: 217 KB Estimated disk space
#   ctx: required: 4.6 MB (with test) Estimated build time: less than 0.1 SBU (with test)
#   ctx: Uchardet Dependencies Required CMake-4.2.3 Installation of Uchardet Install Uchardet by
#   ctx: running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr        \
      -D BUILD_STATIC=OFF                 \
      -D CMAKE_POLICY_VERSION_MINIMUM=3.5 \
      -W no-dev ..                        &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make test. Now, as the root user:
make install

