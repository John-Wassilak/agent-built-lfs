#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/sdl2.html
# title  : sdl2-compat-2.32.64
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ): https://www.libsdl.org/release/sdl2-compat-2.32.64.tar.gz Download MD5 sum:
#   ctx: 67f7e69cfacc25c51496f2702ce32654 Download size: 2.7 MB Estimated disk space required: 60
#   ctx: MB (add 29 MB for tests) Estimated build time: less than 0.1 SBU (add 0.1 SBU for tests)
#   ctx: sdl2-compat Dependencies Required CMake-4.2.3 and SDL3-3.4.0 Installation of sdl2-compat
#   ctx: Install sdl2-compat by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr   \
      -D CMAKE_BUILD_TYPE=Release    \
      -D CMAKE_SKIP_INSTALL_RPATH=ON \
      -D SDL2COMPAT_STATIC=OFF       \
      -D SDL2COMPAT_TESTS=OFF        \
      -W no-dev -G Ninja ..          &&

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
      -W no-dev -G Ninja ..          &&

ninja &&
DESTDIR=$PWD/TESTS ninja install

