#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/exiv2.html
# title  : Exiv2-0.28.7
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: c28f6aa Download size: 45 MB Estimated disk space required: 134 MB (with tests)
#   ctx: Estimated build time: 0.5 SBU (Using parallelism=4, with tests) Exiv2 dependencies
#   ctx: Required CMake-4.2.3 Recommended Brotli-1.2.0, cURL-8.18.0, and inih-62 Optional libssh
#   ctx: Optional for documentation Doxygen-1.16.1, Graphviz-14.1.2, and libxslt-1.1.45
#   ctx: Installation of Exiv2 Install Exiv2 by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr   \
      -D CMAKE_BUILD_TYPE=Release    \
      -D EXIV2_ENABLE_VIDEO=yes      \
      -D EXIV2_ENABLE_WEBREADY=yes   \
      -D EXIV2_ENABLE_CURL=yes       \
      -D EXIV2_BUILD_SAMPLES=no      \
      -D CMAKE_SKIP_INSTALL_RPATH=ON \
      -G Ninja ..                    &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install

