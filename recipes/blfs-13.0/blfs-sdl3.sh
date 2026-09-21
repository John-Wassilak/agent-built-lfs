#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/sdl3.html
# title  : SDL3-3.4.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ests) SDL3 Dependencies Required CMake-4.2.3 Recommended alsa-lib-1.2.15.3,
#   ctx: libusb-1.0.29, libxkbcommon-1.13.1, Mesa-25.3.5, pipewire-1.6.0, PulseAudio-17.0,
#   ctx: Vulkan-Loader-1.4.341.0, wayland-protocols-1.47, and Xorg Libraries (if those are not
#   ctx: present, the corresponding modules are not built) Optional ibus-1.5.33, jack, and sndio
#   ctx: Installation of SDL3 Install SDL3 by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_BUILD_TYPE=Release  \
      -D SDL_TEST_LIBRARY=OFF      \
      -D SDL_STATIC=OFF            \
      -D SDL_RPATH=OFF             \
      -W no-dev -G Ninja ..        &&

ninja

# --- block 1 --------------------------------------------------
#   ctx: Now, as the root user:
ninja install

# --- block 2 --------------------------------------------------
#   ctx: Testing SDL3 If you want to build the tests, issue the following commands:
#   REVIEWED [drop]: Optional test build, not wanted.
# mkdir ../build-tests &&
# cd    ../build-tests &&
# 
# cmake -D CMAKE_INSTALL_PREFIX=/usr \
#       -D CMAKE_BUILD_TYPE=Release  \
#       -D SDL_STATIC=OFF            \
#       -D SDL_RPATH=OFF             \
#       -D SDL_TESTS=ON              \
#       -D SDL_INSTALL_TESTS=ON      \
#       -W no-dev -G Ninja ..        &&
# 
# ninja &&
# DESTDIR=$PWD/TESTS ninja install

