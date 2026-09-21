#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/clucene.html
# title  : CLucene-2.3.3.4
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ad MD5 sum: 48d647fbd8ef8889e5a7f422c1bfda94 Download size: 2.2 MB Estimated disk space
#   ctx: required: 78 MB Estimated build time: 0.8 SBU Additional Downloads Required patch:
#   ctx: https://www.linuxfromscratch.org/patches/blfs/13.0/clucene-2.3.3.4-contribs_lib-1.patch
#   ctx: CLucene Dependencies Required CMake-4.2.3 Recommended Boost-1.90.0 Installation of
#   ctx: CLucene Install CLucene by running the following commands:
patch -Np1 -i ../clucene-2.3.3.4-contribs_lib-1.patch &&

sed -i '/Misc.h/a #include <ctime>' src/core/CLucene/document/DateTools.cpp &&

mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr        \
      -D CMAKE_POLICY_VERSION_MINIMUM=3.5 \
      -D BUILD_CONTRIBS_LIB=ON            \
      -W no-dev ..                        &&
make

# --- block 1 --------------------------------------------------
#   ctx: Now, as the root user:
make install

