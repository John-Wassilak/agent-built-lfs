#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/fribidi.html
# title  : FriBidi-1.0.16
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: d (HTTP):
#   ctx: https://github.com/fribidi/fribidi/releases/download/v1.0.16/fribidi-1.0.16.tar.xz
#   ctx: Download MD5 sum: 333ad150991097a627755b752b87f9ff Download size: 1.1 MB Estimated disk
#   ctx: space required: 22 MB (with tests) Estimated build time: less than 0.1 SBU (with tests)
#   ctx: FriBidi Dependencies Optional c2man (to build man pages) Installation of FriBidi Install
#   ctx: FriBidi by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install

