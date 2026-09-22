#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/libclc.html
# title  : libclc-22.1.8
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: lvm-project-22.1.8.src.tar.xz Download MD5 sum: 69065494ebcb1150b2a329c1b3db7584
#   ctx: Download size: 160 MB Estimated disk space required: 431 MB Estimated build time: 0.6
#   ctx: SBU (with parallelism=8) libclc Dependencies Required LLVM-22.1.8 Recommended
#   ctx: SPIRV-LLVM-Translator-22.1.5 (required for the iris gallium driver in Mesa-26.1.7)
#   ctx: Installation of libclc Install libclc by running the following commands:
mkdir libclc/build &&
cd    libclc/build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_BUILD_TYPE=Release  \
      -G Ninja ..                  &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install

