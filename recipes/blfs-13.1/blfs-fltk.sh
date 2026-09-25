#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/x/fltk.html
# title  : FLTK-1.3.11
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: equired Xorg Libraries Recommended hicolor-icon-theme-0.18, libjpeg-turbo-3.2.0, and
#   ctx: libpng-1.6.58 Optional alsa-lib-1.2.16.1, desktop-file-utils-0.28, Doxygen-1.18.0,
#   ctx: Mesa-26.1.7, and texlive-20260301 (or install-tl-unx) Installation of FLTK Note The tar
#   ctx: extraction directory is fltk-1.3.11 and not fltk-1.3.11-source as indicated by the
#   ctx: tarball name. Install FLTK by running the following commands:
sed -i -e '/cat./d' documentation/Makefile &&

./configure --prefix=/usr --enable-shared  &&
make

# --- block 1 --------------------------------------------------
#   ctx: If you wish to create the API documentation, issue:
#   REVIEWED [drop]: 'If you wish to create the API documentation, issue: make -C documentation html' -- explicitly optional, and needs Doxygen, which is not built.
# make -C documentation html

# --- block 2 --------------------------------------------------
#   ctx: The tests for the package are interactive. To execute the tests, run test/unittests. In
#   ctx: addition, there are about 70 other executable test programs in the test directory that
#   ctx: can be run individually. Now, install the package and remove unneeded static libraries.
#   ctx: As the root user:
make docdir=/usr/share/doc/fltk-1.3.11 install &&
rm -fv /usr/lib/libfltk*.a

# --- block 3 --------------------------------------------------
#   ctx: If desired, install some example games built as a part of the tests, extra documentation
#   ctx: and example programs. As the root user:
#   REVIEWED [drop]: 'If desired, install some example games built as a part of the tests, extra documentation and example programs' -- explicitly optional; the documentation half also needs block 1's docs.
# make -C test          docdir=/usr/share/doc/fltk-1.3.9 install-linux &&
# make -C documentation docdir=/usr/share/doc/fltk-1.3.9 install-linux

