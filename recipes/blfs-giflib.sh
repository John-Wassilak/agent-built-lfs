#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/giflib.html
# title  : giflib-5.2.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Required patch:
#   ctx: https://www.linuxfromscratch.org/patches/blfs/13.0/giflib-5.2.2-upstream_fixes-1.patch
#   ctx: Required patch:
#   ctx: https://www.linuxfromscratch.org/patches/blfs/13.0/giflib-5.2.2-security_fixes-1.patch
#   ctx: giflib Dependencies Optional xmlto-0.0.29 (required if you run make after make clean)
#   ctx: [1] Installation of giflib First, prevent the build process from installing XML files
#   ctx: instead of man pages:
patch -Np1 -i ../giflib-5.2.2-upstream_fixes-1.patch

# --- block 1 --------------------------------------------------
#   ctx: Next, fix several security vulnerabilities in the 'gif2rgb' utility:
patch -Np1 -i ../giflib-5.2.2-security_fixes-1.patch

# --- block 2 --------------------------------------------------
#   ctx: Next, remove an unnecessary dependency on ImageMagick-7.1.2-13 by moving a file into an
#   ctx: expected location:
cp pic/gifgrid.gif doc/giflib-logo.gif

# --- block 3 --------------------------------------------------
#   ctx: Install giflib by running the following commands:
make

# --- block 4 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make PREFIX=/usr install &&

rm -fv /usr/lib/libgif.a &&

find doc \( -name Makefile\* -o -name \*.1 \
         -o -name \*.xml \) -exec rm -v {} \; &&

install -v -dm755 /usr/share/doc/giflib-5.2.2 &&
cp -v -R doc/* /usr/share/doc/giflib-5.2.2

