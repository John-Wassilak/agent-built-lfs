#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/iso-codes.html
# title  : ISO Codes-4.20.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: using an LFS 13.0 platform. Package Information Download (HTTP):
#   ctx: s://salsa.debian.org/iso-codes-team/iso-codes/-/archive/v4.20.1/iso-codes-v4.20.1.tar.gz
#   ctx: Download MD5 sum: a8f16a62662ec13e55ca255a7c036ee3 Download size: 16 MB Estimated disk
#   ctx: space required: 114 MB Estimated build time: less than 0.1 SBU (with tests) Installation
#   ctx: of ISO Codes Install ISO Codes by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install

