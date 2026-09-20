#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/multimedia/libaom.html
# title  : libaom-3.14.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ownload (HTTP): https://storage.googleapis.com/aom-releases/libaom-3.14.1.tar.gz
#   ctx: Download MD5 sum: 4a689bbc27ec095d253ed8d241077ad5 Download size: 6.1 MB Estimated disk
#   ctx: space required: 124 MB Estimated build time: 0.8 SBU (with parallelism=4) libaom
#   ctx: Dependencies Recommended yasm-1.3.0 (or NASM-3.02) Optional Doxygen-1.18.0 Installation
#   ctx: of libaom Prevent installing static versions of the libraries:
sed -i 's/aom aom_static/aom/' cmake/aom_install.cmake

# --- block 1 --------------------------------------------------
#   ctx: Install libaom by running the following commands:
mkdir aom-build &&
cd    aom-build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_BUILD_TYPE=Release  \
      -D BUILD_SHARED_LIBS=1       \
      -D ENABLE_DOCS=no            \
      -G Ninja .. &&
ninja

# --- block 2 --------------------------------------------------
#   ctx: This package does not come with a working test suite. Now, as the root user:
ninja install

