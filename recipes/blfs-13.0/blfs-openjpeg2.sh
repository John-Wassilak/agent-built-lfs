#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/openjpeg2.html
# title  : OpenJPEG-2.5.4
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: c0f024b375e4 Download size: 2.1 MB Estimated disk space required: 16 MB (add 1.7 GB for
#   ctx: tests) Estimated build time: 0.2 SBU (add 1.1 SBU for tests) OpenJPEG Dependencies
#   ctx: Required CMake-4.2.3 Optional git-2.53.0 (for tests), Little CMS-2.18, libpng-1.6.55,
#   ctx: libtiff-4.7.1, and Doxygen-1.16.1 (to build the API documentation) Installation of
#   ctx: OpenJPEG Install OpenJPEG by running the following commands:
mkdir -v build &&
cd       build &&

cmake -D CMAKE_BUILD_TYPE=Release  \
      -D CMAKE_INSTALL_PREFIX=/usr \
      -D BUILD_STATIC_LIBS=OFF ..  &&
make

# --- block 1 --------------------------------------------------
#   ctx: If you wish to run the tests, some additional files are required. Download these files
#   ctx: and run the tests using the following commands, but note that 8 tests are known to fail:
#   REVIEWED [drop]: The book's condition: 'If you wish to run the tests, some additional files are required', fetched by git clone of openjpeg-data, and the page puts the tests at 1.7 GB of extra disk space with '8 tests are known to fail'. Optional; the install in block 2 builds from block 0's tree, not the test reconfiguration.
# git clone https://github.com/uclouvain/openjpeg-data.git --depth 1 &&
# OPJ_DATA_ROOT=$PWD/openjpeg-data cmake -D BUILD_TESTING=ON ..      &&
# make                                                               &&
# make test

# --- block 2 --------------------------------------------------
#   ctx: Now, as the root user:
make install &&
cp -rv ../doc/man -T /usr/share/man

