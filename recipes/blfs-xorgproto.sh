#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/xorgproto.html
# title  : xorgproto-2025.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: to build additional documentation) Note There is a reciprocal dependency with fop-2.11.
#   ctx: If you wish to build the documentation, you'll need to re-install the Protocol Headers
#   ctx: after the installation is complete and fop-2.11 has been installed. Editor Notes:
#   ctx: https://wiki.linuxfromscratch.org/blfs/wiki/Xorg7ProtocolHeaders Installation of
#   ctx: xorgproto Install xorgproto by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=$XORG_PREFIX .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
ninja install &&
mv -v $XORG_PREFIX/share/doc/xorgproto{,-2025.1}

