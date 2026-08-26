#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/xkeyboard-config.html
# title  : XKeyboardConfig-2.46
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: bc0f52f2fb4629babc344c1 Download size: 912 KB Estimated disk space required: 22 MB
#   ctx: Estimated build time: 0.1 SBU (with tests) XKeyboardConfig Dependencies Required Xorg
#   ctx: Libraries Optional (required for tests) libxkbcommon-1.13.1, pytest-9.0.2 with
#   ctx: optionally xdist (speeds up the tests), and Xorg Applications Installation of
#   ctx: XKeyboardConfig Install XKeyboardConfig by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=$XORG_PREFIX --buildtype=release .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Two tests, test_compat_layout[mapping39-base]
#   ctx: and test_compat_layout[mapping39-evdev], are known to fail. Important If upgrading from
#   ctx: version 2.44 or earlier, the installation will fail if some files are not symbolic
#   ctx: links. To fix this, run as the root user:
#   REVIEWED [drop]: Upgrade-only cleanup ('if upgrading from version 2.44 or earlier'). This is a fresh install -- $XORG_PREFIX/share/X11/xkb does not exist yet.
# if [ -d $XORG_PREFIX/share/X11/xkb ]; then
#   rm -rf $XORG_PREFIX/share/X11/xkb
#   rm -f  $XORG_PREFIX/share/man/man7/xkeyboard-config.7
#   rm -f  $XORG_PREFIX/share/pkgconfig/xkeyboard-config.pc
# fi

# --- block 2 --------------------------------------------------
#   ctx: Now, as the root user:
ninja install

