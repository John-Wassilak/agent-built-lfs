#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/lcms2.html
# title  : Little CMS-2.19.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: github.com/mm2/Little-CMS/releases/download/lcms2.19.1/lcms2-2.19.1.tar.gz Download MD5
#   ctx: sum: 541978f73749499e9e0277bfe5a3c868 Download size: 5.5 MB Estimated disk space
#   ctx: required: 17 MB (with the tests) Estimated build time: 0.2 SBU (with the tests) Little
#   ctx: CMS2 Dependencies Optional libjpeg-turbo-3.2.0 and tiff-4.7.2 Installation of Little
#   ctx: CMS2 Install Little CMS2 by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install

