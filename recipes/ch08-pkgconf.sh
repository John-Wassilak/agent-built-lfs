#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.1-systemd book.
# source : book/13.1/chapter08/pkgconf.html
# title  : 8.21 Pkgconf-3.0.5
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The pkgconf package is a successor to pkg-config and contains a tool for passing the
#   ctx: include path and/or library paths to build tools during the configure and make phases of
#   ctx: package installations. Approximate build time: less than 0.1 SBU Required disk space: 47
#   ctx: MB 8.21.1 Installation of Pkgconf First, work around a circular dependency on meson:
tar -xf ../meson-1.12.0.tar.gz

# --- block 1 --------------------------------------------------
#   ctx: Prepare Pkgconf for compilation:
mkdir build
cd    build

python3 ../meson-1.12.0/meson.py setup --prefix=/usr --buildtype=release ..

# --- block 2 --------------------------------------------------
#   ctx: Compile the package:
ninja

# --- block 3 --------------------------------------------------
#   ctx: To test the results, issue:
#   TAGS: testsuite   [DISABLED - review]
# ninja test

# --- block 4 --------------------------------------------------
#   ctx: Install the package:
ninja install
mv /usr/share/doc/pkgconf{,-3.0.5}

# --- block 5 --------------------------------------------------
#   ctx: To maintain compatibility with the original Pkg-config create two symlinks:
ln -sv pkgconf   /usr/bin/pkg-config
ln -sv pkgconf.1 /usr/share/man/man1/pkg-config.1

