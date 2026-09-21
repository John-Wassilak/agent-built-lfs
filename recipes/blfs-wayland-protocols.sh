#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/wayland-protocols.html
# title  : Wayland-Protocols-1.49
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: rg/wayland/wayland-protocols/-/releases/1.49/downloads/wayland-protocols-1.49.tar.xz
#   ctx: Download MD5 sum: 5685f769a227f2d4143d983ad07edaba Download size: 148 KB Estimated disk
#   ctx: space required: 16 MB (with tests) Estimated build time: 0.1 SBU (with tests)
#   ctx: Wayland-protocols Dependencies Required Wayland-1.26.0 Installation of Wayland-protocols
#   ctx: Install Wayland-protocols by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install

