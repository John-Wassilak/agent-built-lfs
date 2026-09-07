#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/xdg-desktop-portal-gtk.html
# title  : xdg-desktop-portal-gtk-1.15.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ownload MD5 sum: 2d6e2ad2953c386a1db11618fa3803b0 Download size: 96 KB Estimated disk
#   ctx: space required: 6.6 MB Estimated build time: 0.1 SBU xdg-desktop-portal-gtk Dependencies
#   ctx: Required GTK-3.24.51 and xdg-desktop-portal-1.20.3 Recommended gnome-desktop-44.5 (for
#   ctx: compiling more portal interfaces) Installation of xdg-desktop-portal-gtk Install
#   ctx: xdg-desktop-portal-gtk by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release -D wallpaper=disabled .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
ninja install

