#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/libaom.html
# title  : libaom-3.13.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: endencies Recommended yasm-1.3.0 (or NASM-3.01) Optional Doxygen-1.16.1 Installation of
#   ctx: libaom NASM-3 made a change where the help screen now shows different text based on
#   ctx: different parameters, instead of displaying all the info upfront. This package depends
#   ctx: on all the information being there. Fix how this package gets that information to
#   ctx: prevent a configuration failure with only NASM-3 installed:
patch -Np1 -i ../libaom-3.13.1-nasm3-1.patch

# --- block 1 --------------------------------------------------
#   ctx: Prevent installing static versions of the libraries:
sed -i 's/aom aom_static/aom/' build/cmake/aom_install.cmake

# --- block 2 --------------------------------------------------
#   ctx: Install libaom by running the following commands:
mkdir aom-build &&
cd    aom-build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_BUILD_TYPE=Release  \
      -D BUILD_SHARED_LIBS=1       \
      -D ENABLE_DOCS=no            \
      -G Ninja .. &&
ninja

# --- block 3 --------------------------------------------------
#   ctx: This package does not come with a working test suite. Now, as the root user:
ninja install

