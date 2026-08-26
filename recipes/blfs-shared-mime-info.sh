#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/shared-mime-info.html
# title  : shared-mime-info-2.4
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ime/xdgmime.tar.xz xdgmime md5sum: 7dfb4446705d345d3acd672024049e86 Shared Mime Info
#   ctx: Dependencies Required GLib-2.86.4 and libxml2-2.15.1 Optional xmlto-0.0.29 Installation
#   ctx: of Shared Mime Info Install Shared Mime Info by running the following commands: If you
#   ctx: wish to run the test suite, you must first extract the xdgmime tarball into the current
#   ctx: directory, and compile it so that meson can find it:
tar -xf ../xdgmime.tar.xz &&
make -C xdgmime

# --- block 1 --------------------------------------------------
#   ctx: Now build the package:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release -D update-mimedb=true .. &&
ninja

# --- block 2 --------------------------------------------------
#   ctx: If you have followed the instructions above to build xdgmime, to test the result issue
#   ctx: ninja test. Now, as the root user:
ninja install

