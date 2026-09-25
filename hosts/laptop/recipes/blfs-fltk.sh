#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/fltk.html
# title  : FLTK-1.4.4
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: org Libraries Recommended hicolor-icon-theme-0.18, libjpeg-turbo-3.1.3, and
#   ctx: libpng-1.6.55 Optional alsa-lib-1.2.15.3, desktop-file-utils-0.28, Doxygen-1.16.1,
#   ctx: GLU-9.0.3, Mesa-25.3.5, and texlive-20250308 (or install-tl-unx) Installation of FLTK
#   ctx: Note The tar extraction directory is fltk-1.4.4 and not fltk-1.4.4-source as indicated
#   ctx: by the tarball name. Install FLTK by running the following commands:
sed -i -e '/cat./d' documentation/Makefile &&

./configure --prefix=/usr --enable-shared --disable-wayland &&
make

# --- block 1 --------------------------------------------------
#   ctx: If you wish to create the API documentation, issue:
#   REVIEWED [drop]: 'If you wish to create the API documentation, issue: make -C documentation html' -- explicitly optional, and needs Doxygen, which is not built.
# make -C documentation html

# --- block 2 --------------------------------------------------
#   ctx: The tests for the package are interactive. To execute the tests, run test/unittests. In
#   ctx: addition, there are 70 other executable test programs in the test directory that can be
#   ctx: run individually. Now, install the package and remove unneeded static libraries. As the
#   ctx: root user:
make docdir=/usr/share/doc/fltk-1.4.4 install &&
rm -vf /usr/lib/libfltk*.a

# --- block 3 --------------------------------------------------
#   ctx: If desired, install some example games built as a part of the tests, extra documentation
#   ctx: and example programs. As the root user:
#   REVIEWED [drop]: 'If desired, install some example games built as a part of the tests, extra documentation and example programs' -- explicitly optional; the documentation half also needs block 1's docs.
# make -C test          docdir=/usr/share/doc/fltk-1.4.4 install-linux &&
# make -C documentation docdir=/usr/share/doc/fltk-1.4.4 install-linux

# --- block 4 --------------------------------------------------
#   ctx: If you downloaded the optional html documentation, install it as the root user:
#   REVIEWED [drop]: 'If you downloaded the optional html documentation' -- the docs tarball is not fetched.
# tar -C /usr/share/doc/fltk-1.4.4 --strip-components=4 -xf ../fltk-1.4.4-docs-html.tar.gz

