#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/basicnet/glib-networking.html
# title  : glib-networking-2.80.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: : 5.9 MB (with tests) Estimated build time: less than 0.1 SBU (with tests) GLib
#   ctx: Networking Dependencies Required GLib-2.86.4 and GnuTLS-3.8.12 Recommended
#   ctx: gsettings-desktop-schemas-49.1 (for the applications using this package to use proxy
#   ctx: server settings in GNOME) and make-ca-1.16.1 Optional libproxy-0.5.12 Installation of
#   ctx: GLib Networking Install GLib Networking by running the following commands:
mkdir build &&
cd    build &&

meson setup             \
   --prefix=/usr        \
   --buildtype=release  \
   -D libproxy=disabled \
   .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install

