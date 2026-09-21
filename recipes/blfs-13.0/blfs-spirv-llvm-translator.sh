#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/spirv-llvm-translator.html
# title  : SPIRV-LLVM-Translator-21.1.4
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 4/SPIRV-LLVM-Translator-21.1.4.tar.gz Download MD5 sum: fac27ad16b5923bc4cdb66659f8d8dcc
#   ctx: Download size: 1.8 MB Estimated disk space required: 40 MB Estimated build time: 0.5 SBU
#   ctx: (with parallelism=4) SPIRV-LLVM-Translator Dependencies Required libxml2-2.15.1,
#   ctx: LLVM-21.1.8, and SPIRV-Tools-1.4.341.0 Installation of SPIRV-LLVM-Translator Install
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

