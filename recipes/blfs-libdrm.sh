#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/libdrm.html
# title  : Libdrm-2.4.131
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: o-1.18.4 (for tests), CMake-4.2.3 (could be used to find dependencies without pkgconfig
#   ctx: files), docbook-xml-4.5, docbook-xsl-nons-1.79.2, docutils-0.22.4, and libxslt-1.1.45
#   ctx: (to build manual pages), libatomic_ops-7.10.0 (required by architectures without native
#   ctx: atomic operations), Valgrind-3.26.0, and CUnit (for AMDGPU tests) Installation of Libdrm
#   ctx: Install libdrm by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=$XORG_PREFIX \
            --buildtype=release   \
            -D udev=true          \
            -D valgrind=disabled  \
            ..                    &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To check the results, issue ninja test. Now, as the root user:
ninja install

