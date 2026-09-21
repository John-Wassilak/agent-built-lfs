#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/multimedia/sdl3.html
# title  : SDL3-3.4.14
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ependencies Required CMake-4.4.2 Recommended alsa-lib-1.2.16.1, libusb-1.0.30,
#   ctx: libxkbcommon-1.13.2, Mesa-26.1.7, pipewire-1.6.8, PulseAudio-17.0,
#   ctx: Vulkan-Loader-1.4.357.0, wayland-protocols-1.49, and Xorg Libraries (if those are not
#   ctx: present, the corresponding modules are not built) Optional ibus-1.5.34, jack, and sndio
#   ctx: Installation of SDL3 Fix potential conflicts with getresuid by applying a patch:
patch -Np1 -i ../SDL3-3.4.14-upstream_fixes-1.patch

# --- block 1 --------------------------------------------------
#   ctx: Install SDL3 by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_BUILD_TYPE=Release  \
      -D SDL_TEST_LIBRARY=OFF      \
      -D SDL_STATIC=OFF            \
      -D SDL_RPATH=OFF             \
      -W no-author -G Ninja ..     &&

ninja

# --- block 2 --------------------------------------------------
#   ctx: Now, as the root user:
ninja install

# --- block 3 --------------------------------------------------
#   ctx: Testing SDL3 If you want to build the tests, issue the following commands:
#   REVIEWED [drop]: This is the actual optional test build (separate build-tests directory, SDL_TESTS=ON/SDL_INSTALL_TESTS=ON) -- test suites have been skipped throughout this project. Previously left enabled by the same mix-up that wrongly dropped block 2 above instead of this one.
# mkdir ../build-tests &&
# cd    ../build-tests &&
# 
# cmake -D CMAKE_INSTALL_PREFIX=/usr \
#       -D CMAKE_BUILD_TYPE=Release  \
#       -D SDL_STATIC=OFF            \
#       -D SDL_RPATH=OFF             \
#       -D SDL_TESTS=ON              \
#       -D SDL_INSTALL_TESTS=ON      \
#       -W no-author -G Ninja ..     &&
# 
# ninja &&
# DESTDIR=$PWD/TESTS ninja install

