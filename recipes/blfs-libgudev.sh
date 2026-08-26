#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libgudev.html
# title  : libgudev-238
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: .gnome.org/sources/libgudev/238/libgudev-238.tar.xz Download MD5 sum:
#   ctx: 46da30a1c69101c3a13fa660d9ab7b73 Download size: 32 KB Estimated disk space required: 2.0
#   ctx: MB Estimated build time: less than 0.1 SBU Required GLib-2.86.4 (GObject Introspection
#   ctx: required for GNOME) Optional GTK-Doc-1.35.1 and umockdev-0.19.4 (for testing)
#   ctx: Installation of libgudev Install libgudev by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install

