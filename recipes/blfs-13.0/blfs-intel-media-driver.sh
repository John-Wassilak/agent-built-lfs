#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/intel-media-driver.html
# title  : intel-media-driver-25.3.4
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: built. To determine the model of the Intel GPU, install pciutils-3.14.0 and run lspci
#   ctx: -nn | grep -Ei 'VGA|DISPLAY' first. It will output some information about the GPU,
#   ctx: including the PCI vendor ID (8086 for Intel) and the PCI device ID. For example, with an
#   ctx: Intel Core i5-11300H CPU, the output is 8086:9a49. Now searching for the registration of
#   ctx: this device ID in the intel-media-driver source tree:
#   TAGS: admon:note   [DISABLED - review]
# grep -ri 'RegisterDevice(0x9a49'

# --- block 1 --------------------------------------------------
#   ctx: And determine the GPU model from the file name containing the registration. For the
#   ctx: example above, the file name is media_sysinfo_g12.cpp, indicating the model is GEN12.
#   ctx: Install intel-media-driver by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=$XORG_PREFIX \
      -D CMAKE_POLICY_VERSION_MINIMUM=3.5  \
      -D INSTALL_DRIVER_SYSCONF=OFF        \
      -D BUILD_TYPE=Release                \
      -D MEDIA_BUILD_FATAL_WARNINGS=OFF    \
      -G Ninja                             \
      -W no-dev ..                         &&
ninja

# --- block 2 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
ninja install

