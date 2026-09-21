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
#
# -D sha1=libgcrypt added 2026-09-09: meson's default `auto` picked libnettle, whose
# xsha1.c branch #includes <nettle/sha.h> -- a header nettle-4.0 (the book's own
# documented version, confirmed against its real tarball contents) does not ship at
# all, only sha1.h/sha2.h/sha3.h separately. A real upstream xorg-server/nettle version
# mismatch, not a packaging bug on this project's end. libgcrypt-1.12.2 is also a
# Required dependency of this page and xsha1.c has a complete, working libgcrypt
# branch (`#include <gcrypt.h>`) -- forcing that implementation avoids the missing
# header entirely rather than patching around it.
set -e

mkdir build &&
cd    build &&

meson setup ..              \
      --prefix=$XORG_PREFIX \
      --localstatedir=/var  \
      -D glamor=true        \
      -D sha1=libgcrypt     \
      -D xkb_output_dir=/var/lib/xkb &&
ninja

ninja install
mkdir -pv /etc/X11/xorg.conf.d

# Real, confirmed-necessary post-install step (see BUILD-REPORT.md's
# Phase 4 testing): without logind (not run on this system), an
# unprivileged startx fails outright with "xf86OpenConsole: Cannot
# open virtual console 1 (Permission denied)". Setuid-root is Xorg's
# own, much older mechanism for VT access, predating logind -- this
# was the standard way non-display-manager X11 systems worked for
# decades, not a hack. Confirmed via a direct root-level test first
# (bypassing the permission error entirely) before applying it here.
chmod u+s /usr/bin/Xorg
