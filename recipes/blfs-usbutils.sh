#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/usbutils.html
# title  : usbutils-019
# rationale: Operator-requested (lsusb). Required: libusb (tier 12).
# Recommended: hwdata (tier 2, already provides usb.ids).
set -e

mkdir build
cd build

meson setup .. \
  --prefix=/usr \
  --buildtype=release
ninja

ninja install

echo "### version"
lsusb --version 2>&1 || true
