#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/spirv-llvm-translator.html
# title  : SPIRV-LLVM-Translator-21.1.4
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
#
# Built 2026-08-26 -- not needed until now (only required as a libclc
# dependency, which in turn is only required for Mesa's NVK Vulkan
# driver, enabled this session -- see blfs-mesa.sh, blfs-libclc.sh).
set -e

mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr                   \
      -D CMAKE_BUILD_TYPE=Release                    \
      -D BUILD_SHARED_LIBS=ON                        \
      -D CMAKE_SKIP_INSTALL_RPATH=ON                 \
      -D LLVM_EXTERNAL_SPIRV_HEADERS_SOURCE_DIR=/usr \
      -G Ninja ..                                    &&
ninja

ninja install
