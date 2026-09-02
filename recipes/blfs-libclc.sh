#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libclc.html
# title  : libclc-21.1.8
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: load (HTTP):
#   ctx: //github.com/llvm/llvm-project/releases/download/llvmorg-21.1.8/libclc-21.1.8.src.tar.xz
#   ctx: Download MD5 sum: 994234e3bede730842de1d66396a2919 Download size: 147 KB Estimated disk
#   ctx: space required: 431 MB Estimated build time: 0.6 SBU (with parallelism=8) libclc
#   ctx: Dependencies Required SPIRV-LLVM-Translator-21.1.4 Installation of libclc Install libclc
#   ctx: by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_BUILD_TYPE=Release  \
      -G Ninja ..                  &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install

