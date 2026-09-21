#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libdisplay-info.html
# title  : libdisplay-info-0.3.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: top.org/emersion/libdisplay-info/-/releases/0.3.0/downloads/libdisplay-info-0.3.0.tar.xz
#   ctx: Download MD5 sum: f2a15697f6e8c66722b7760ceccbed60 Download size: 112 KB Estimated disk
#   ctx: space required: 3.3 MB Estimated build time: less than 0.1 SBU libdisplay-info
#   ctx: Dependencies Required hwdata-0.404 Installation of libdisplay-info Install
#   ctx: libdisplay-info by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, run ninja test. Now, as the root user:
ninja install

