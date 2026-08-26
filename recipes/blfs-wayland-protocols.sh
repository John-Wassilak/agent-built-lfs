#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/wayland-protocols.html
# title  : Wayland-Protocols-1.47
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: rg/wayland/wayland-protocols/-/releases/1.47/downloads/wayland-protocols-1.47.tar.xz
#   ctx: Download MD5 sum: 190cc400d3ec85b5931a0d8f015d4242 Download size: 136 KB Estimated disk
#   ctx: space required: 14 MB (with tests) Estimated build time: 0.1 SBU (with tests)
#   ctx: Wayland-protocols Dependencies Required Wayland-1.24.0 Installation of Wayland-protocols
#   ctx: Install Wayland-protocols by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install

