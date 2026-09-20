#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/libjxl.html
# title  : libjxl-0.12.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 0, CMake-4.4.2, giflib-6.1.3, highway-1.4.0, Little CMS-2.19.1, libjpeg-turbo-3.2.0, and
#   ctx: libpng-1.6.58 Optional asciidoc-10.2.1 (for man pages), Doxygen-1.18.0 and
#   ctx: Graphviz-15.1.1 (for documentation), gdk-pixbuf-2.44.7 (for the plugin), Java-21.0.10
#   ctx: (for the JAR), libavif-1.4.2, libwebp-1.6.0, gtest, OpenEXR, sjpeg, and skcms
#   ctx: Installation of libjxl Install libjxl by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr             \
      -D CMAKE_BUILD_TYPE=Release              \
      -D BUILD_TESTING=OFF                     \
      -D BUILD_SHARED_LIBS=ON                  \
      -D JPEGXL_ENABLE_SKCMS=OFF               \
      -D JPEGXL_ENABLE_SJPEG=OFF               \
      -D JPEGXL_ENABLE_PLUGINS=OFF             \
      -D JPEGXL_INSTALL_JARDIR=/usr/share/java \
      -G Ninja ..                              &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: This package does come with a test suite, but it requires gtest, which is not in BLFS.
#   ctx: Now, as the root user:
ninja install

