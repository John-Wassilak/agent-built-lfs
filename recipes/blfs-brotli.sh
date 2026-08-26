#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/brotli.html
# title  : brotli-1.2.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ive/v1.2.0/brotli-1.2.0.tar.gz Download MD5 sum: 8fbfae9a5ecbc278ae7f761ecb6d1285
#   ctx: Download size: 632 KB Estimated disk space required: 33 MB (with python3 bindings)
#   ctx: Estimated build time: 0.3 SBU (with python3 bindings; parallelism=4) Brotli Dependencies
#   ctx: Required CMake-4.2.3 Optional pytest-9.0.2 (for testing Python3 bindings) Installation
#   ctx: of Brotli Install brotli by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_BUILD_TYPE=Release  \
      -G Ninja .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install

# --- block 2 --------------------------------------------------
#   ctx: If desired, build the Python3 bindings:
#   REVIEWED [drop]: 'If desired, build the Python3 bindings' -- explicitly optional. Nothing in this stack needs Python brotli bindings, only the C library installed by blocks 0-1.
# cd .. &&
# 
# sed -e '/libraries +=/s/=.*/= [required_system_library[3:]]/' \
#     -e '/package_configuration/d'                             \
#     -e '/pkgconfig/d'                                         \
#     -i setup.py                                               &&
# 
# USE_SYSTEM_BROTLI=1 \
# pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD

# --- block 3 --------------------------------------------------
#   ctx: Install the Python3 bindings as the root user:
#   REVIEWED [drop]: Installs the Python wheel built by block 2. Not built, so nothing to install.
# pip3 install --no-index --find-links dist --no-user Brotli

