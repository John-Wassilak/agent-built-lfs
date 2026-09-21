#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libtiff.html
# title  : libtiff-4.7.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ownload MD5 sum: f1044dd3b4466cc53464210148e08146 Download size: 3.9 MB Estimated disk
#   ctx: space required: 50 MB (with tests) Estimated build time: 0.2 SBU (with tests) libtiff
#   ctx: Dependencies Recommended CMake-4.2.3 Optional Freeglut-3.8.0 (required for tiffgt),
#   ctx: libjpeg-turbo-3.1.3, sphinx-9.1.0, libwebp-1.6.0, JBIG-KIT, and LERC Installation of
#   ctx: libtiff Install libtiff by running the following commands:
mkdir -p libtiff-build &&
cd       libtiff-build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_BUILD_TYPE=Release  \
      -W no-dev -G Ninja ..
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install &&
mv -v /usr/share/doc/{tiff,libtiff-4.7.1}

