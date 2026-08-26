#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/libei.html
# title  : libei-1.5.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: rg/libinput/libei/-/archive/1.5.0/libei-1.5.0.tar.bz2 Download MD5 sum:
#   ctx: 3afe06351cfb6e47bd48f284b1213205 Download size: 184 KB Estimated disk space required:
#   ctx: 5.7 MB Estimated build time: less than 0.1 SBU libei Dependencies Required attrs-25.4.0
#   ctx: Optional libevdev-1.13.6, libxkbcommon-1.13.1, libxml2-2.15.1, munit, and structlog
#   ctx: Installation of libei Install libei by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release -D tests=disabled &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: This package does come with a test suite, but it requires an external dependency. If you
#   ctx: have both munit and structlog installed, and you wish to run the test suite, run the
#   ctx: following commands:
#   REVIEWED [drop]: Optional test suite needing munit/structlog, not installed.
# meson configure -D tests=enabled &&
# ninja test

# --- block 2 --------------------------------------------------
#   ctx: Now, as the root user:
ninja install

