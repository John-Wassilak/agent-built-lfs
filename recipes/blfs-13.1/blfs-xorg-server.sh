#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/x/xorg-server.html
# title  : Xorg-Server-21.1.24
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: RM kernel GPU driver (usually named CONFIG_FB_* in the kernel configuration, or existing
#   ctx: as out-tree kernel modules), or you need an device specific functionality requiring a
#   ctx: DDX driver, consult a prior version of BLFS, or an even earlier prior version for more
#   ctx: DDX drivers. Installation of Xorg Server First, if you need the TearFree option to work
#   ctx: around screen tearing, apply the backported patch:
patch -Np1 -i ../xorg-server-21.1.24-tearfree_backport-1.patch

# --- block 1 --------------------------------------------------
#   ctx: Install the server by running the following commands:
mkdir build &&
cd    build &&

meson setup ..              \
      --prefix=$XORG_PREFIX \
      --localstatedir=/var  \
      -D glamor=true        \
      -D sha1=libgcrypt     \
      -D xkb_output_dir=/var/lib/xkb &&
ninja

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. You will need to run ldconfig as the root user
#   ctx: first or some tests may fail. Now as the root user:
ninja install &&
mkdir -pv /etc/X11/xorg.conf.d

