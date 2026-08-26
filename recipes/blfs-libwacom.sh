#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libwacom.html
# title  : libwacom-2.18.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: space required: 12 MB (with tests) Estimated build time: less than 0.1 SBU (with tests)
#   ctx: libwacom Dependencies Required libevdev-1.13.6 and libgudev-238 Recommended
#   ctx: libxml2-2.15.1 Optional Doxygen-1.16.1, git-2.53.0, librsvg-2.61.4, Valgrind-3.26.0
#   ctx: (optional for some tests), and pytest-9.0.2 with python-libevdev and pyudev Installation
#   ctx: of libwacom Install libwacom by running the following commands:
mkdir build &&
cd    build &&

meson setup ..            \
      --prefix=/usr       \
      --buildtype=release \
      -D tests=disabled   &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. To run additional tests, install pytest-9.0.2,
#   ctx: python-libevdev, and pyudev, then remove the "-D tests=disabled" option from the meson
#   ctx: line above. If upgrading from a previous version of libwacom, remove the old device
#   ctx: database installation to prevent a potential duplicated match of devices in case some
#   ctx: old database files are not overwritten:
rm -rf /usr/share/libwacom

# --- block 2 --------------------------------------------------
#   ctx: Now, as the root user:
ninja install

