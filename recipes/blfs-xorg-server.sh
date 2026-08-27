#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/xorg-server.html
# title  : Xorg-Server-21.1.21
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
#
# Built 2026-08-26 as part of the X11+awesome migration (see
# AWESOME-X11-PLAN.md) -- this system previously only had Xwayland (a
# separate package/tarball since Xwayland split out of the main xserver
# repo). This is the real, standalone Xorg server.
#
# Real gap the book's own dependency list misses: hw/xfree86's
# meson.build hard-requires libpciaccess, not listed anywhere on this
# page. Built blfs-libpciaccess.sh first after hitting this directly.
#
# modesetting_drv (this page's own DDX driver) is irrelevant to why this
# was built -- the actual target is NVIDIA's own nvidia_drv.so (already
# installed, see blfs-nvidia-470xx.sh), for VDPAU decode via the
# proprietary driver's EGLStreams-incompatible-with-Hyprland path.
set -e

mkdir build &&
cd    build &&

meson setup ..              \
      --prefix=$XORG_PREFIX \
      --localstatedir=/var  \
      -D glamor=true        \
      -D xkb_output_dir=/var/lib/xkb &&
ninja

ninja install
mkdir -pv /etc/X11/xorg.conf.d
