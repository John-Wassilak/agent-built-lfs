#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/multimedia/sdl2.html
# title  : sdl2-compat-2.32.70
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: oad (HTTP): https://www.libsdl.org/release/sdl2-compat-2.32.70.tar.gz Download MD5 sum:
#   ctx: ba9179f09652a6395b3673e4ce8c473b Download size: 2.7 MB Estimated disk space required: 63
#   ctx: MB (add 29 MB for tests) Estimated build time: 0.1 SBU (add 0.1 SBU for tests)
#   ctx: sdl2-compat Dependencies Required CMake-4.4.2 and SDL3-3.4.14 Installation of
#   ctx: sdl2-compat Install sdl2-compat by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr   \
      -D CMAKE_BUILD_TYPE=Release    \
      -D CMAKE_SKIP_INSTALL_RPATH=ON \
      -D SDL2COMPAT_STATIC=OFF       \
      -D SDL2COMPAT_TESTS=OFF        \
      -W no-author -G Ninja ..       &&

ninja

# --- block 1 --------------------------------------------------
#   ctx: Now, as the root user:
ninja install &&
rm -vf /usr/lib/libSDL2_test.a

# --- block 2 --------------------------------------------------
#   ctx: Testing sdl2-compat If you want to build the tests, issue the following commands:
mkdir ../build-tests &&
cd    ../build-tests &&

cmake -D CMAKE_INSTALL_PREFIX=/usr   \
      -D CMAKE_BUILD_TYPE=Release    \
      -D CMAKE_SKIP_INSTALL_RPATH=ON \
      -D SDL2COMPAT_INSTALL_TESTS=ON \
      -D SDL2COMPAT_STATIC=OFF       \
      -D SDL2COMPAT_TESTS=ON         \
      -W no-author -G Ninja ..       &&

ninja &&
DESTDIR=$PWD/TESTS ninja install

