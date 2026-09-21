#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/usbutils.html
# title  : usbutils-019
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: tion Download (HTTP):
#   ctx: https://kernel.org/pub/linux/utils/usb/usbutils/usbutils-019.tar.xz Download MD5 sum:
#   ctx: 67a8eb4782540058d0648f83ecabdf6c Download size: 120 KB Estimated disk space required:
#   ctx: 1.9 MB Estimated build time: less than 0.1 SBU USB Utils Dependencies Required
#   ctx: libusb-1.0.29 Recommended hwdata-0.404 (runtime) Installation of USB Utils Install USB
#   ctx: Utils by running the following commands:
mkdir build &&
cd    build &&

meson setup ..            \
      --prefix=/usr       \
      --buildtype=release &&

ninja

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
ninja install

