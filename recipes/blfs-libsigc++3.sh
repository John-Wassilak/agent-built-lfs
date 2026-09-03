#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libsigc3.html
# title  : libsigc++-3.6.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: load MD5 sum: b7205d5465ac15fbc0c781d39b4011be Download size: 972 KB Estimated disk
#   ctx: space required: 12 MB (with tests) Estimated build time: 0.4 SBU (with tests) libsigc++
#   ctx: Dependencies Recommended Boost-1.90.0 and libxslt-1.1.45 Optional DocBook-utils-0.6.14,
#   ctx: docbook-xml-5.0, Doxygen-1.16.1, fop-2.11, and mm-common Installation of libsigc++
#   ctx: First, fix detecting Boost when configuring this package:
sed -i "s/'system',//" meson.build

# --- block 1 --------------------------------------------------
#   ctx: Install libsigc++ by running the following commands:
mkdir bld &&
cd    bld &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install

