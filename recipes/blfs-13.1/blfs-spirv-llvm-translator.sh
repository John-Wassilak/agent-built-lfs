#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/spirv-llvm-translator.html
# title  : SPIRV-LLVM-Translator-22.1.5
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 5/SPIRV-LLVM-Translator-22.1.5.tar.gz Download MD5 sum: 8bdf03a2f7d90da52e358ac78b3e9959
#   ctx: Download size: 1.9 MB Estimated disk space required: 48 MB Estimated build time: 0.5 SBU
#   ctx: (with parallelism=4) SPIRV-LLVM-Translator Dependencies Required libxml2-2.15.3,
#   ctx: LLVM-22.1.8, and SPIRV-Tools-1.4.357.0 Installation of SPIRV-LLVM-Translator Install
#   ctx: SPIRV-LLVM-Translator by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr                   \
      -D CMAKE_BUILD_TYPE=Release                    \
      -D BUILD_SHARED_LIBS=ON                        \
      -D CMAKE_SKIP_INSTALL_RPATH=ON                 \
      -D LLVM_EXTERNAL_SPIRV_HEADERS_SOURCE_DIR=/usr \
      -G Ninja ..                                    &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
ninja install

