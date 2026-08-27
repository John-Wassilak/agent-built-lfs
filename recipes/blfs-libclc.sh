#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libclc.html
# title  : libclc-21.1.8
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
#
# Built 2026-08-26 -- required by Mesa's NVK Vulkan driver build (meson
# hard-requires libclc once -D vulkan-drivers includes nouveau, for
# built-in function lowering), enabled this session. Depends on
# spirv-llvm-translator (built just before this).
set -e

mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_BUILD_TYPE=Release  \
      -G Ninja ..                  &&
ninja

ninja install
