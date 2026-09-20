#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/x/libdrm.html
# title  : Libdrm-2.4.134
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: iro-1.18.4 (for tests), CMake-4.4.2 (could be used to find dependencies without
#   ctx: pkgconfig files), docbook-xml-4.5, docbook-xsl-nons-1.79.2, docutils-0.23, and
#   ctx: libxslt-1.1.45 (to build manual pages), libatomic_ops-7.10.0 (required by architectures
#   ctx: without native atomic operations), Valgrind-3.27.1, and CUnit (for AMDGPU tests)
#   ctx: Installation of Libdrm Install libdrm by running the following commands:
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

