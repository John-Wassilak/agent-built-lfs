#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/pavucontrol.html
# title  : pavucontrol-6.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: vucontrol/pavucontrol-6.2.tar.xz Download MD5 sum: d515163651b8272e500dfcac32c525dd
#   ctx: Download size: 196 KB Estimated disk space required: 5.6 MB Estimated build time: 0.2
#   ctx: SBU pavucontrol Dependencies Required Gtkmm-4.20.0, JSON-GLib-1.10.8, libsigc++-3.6.0,
#   ctx: and PulseAudio-17.0 Optional libcanberra-0.30 and Lynx-2.9.2 Installation of pavucontrol
#   ctx: Install pavucontrol by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release -D lynx=disabled .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
ninja install &&
mv /usr/share/doc/pavucontrol /usr/share/doc/pavucontrol-6.2

