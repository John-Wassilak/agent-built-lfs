#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/pkgconf.html
# title  : 8.20. Pkgconf-2.5.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The pkgconf package is a successor to pkg-config and contains a tool for passing the
#   ctx: include path and/or library paths to build tools during the configure and make phases of
#   ctx: package installations. Approximate build time: less than 0.1 SBU Required disk space:
#   ctx: 5.0 MB 8.20.1. Installation of Pkgconf Prepare Pkgconf for compilation:
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/pkgconf-2.5.1

# --- block 1 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: Install the package:
make install

# --- block 3 --------------------------------------------------
#   ctx: To maintain compatibility with the original Pkg-config create two symlinks:
ln -sv pkgconf   /usr/bin/pkg-config
ln -sv pkgconf.1 /usr/share/man/man1/pkg-config.1

