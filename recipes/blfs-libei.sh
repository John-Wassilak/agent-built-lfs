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
#   REVIEWED [drop]: Same class of gap as blfs-vulkan-loader's test suite: not auto-flagged by the testsuite classifier ('meson configure -D tests=enabled && ninja test', not the usual 'make check'/'make test' shape), and unconditionally re-enables tests right after block 0 correctly disabled them with the book's own -D tests=disabled. The test suite needs munit, an external dependency not built here (block 0's -D tests=disabled is exactly the book's own documented path for that case) -- meson then tries to git-clone munit as a subproject and fails outright with no network in the chroot ('Git command failed'). True of any host building this page without munit/structlog installed, not laptop-specific.
# meson configure -D tests=enabled &&
# ninja test

# --- block 2 --------------------------------------------------
#   ctx: Now, as the root user:
ninja install

