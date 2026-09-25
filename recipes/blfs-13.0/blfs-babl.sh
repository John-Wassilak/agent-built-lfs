#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/babl.html
# title  : babl-0.1.122
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 0.1/babl-0.1.122.tar.xz Download MD5 sum: 607382d56278e66a88f8bccb33fc9900 Download
#   ctx: size: 320 KB Estimated disk space required: 22 MB (with tests) Estimated build time: 0.1
#   ctx: SBU (Using parallelism=4; with tests) Babl Dependencies Recommended GLib-2.86.4 (with
#   ctx: GObject Introspection), librsvg-2.61.4, and Little CMS-2.18 Optional w3m Installation of
#   ctx: Babl Install Babl by running the following commands:
mkdir bld &&
cd    bld &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install &&

install -v -m755 -d                         /usr/share/gtk-doc/html/babl/graphics &&
install -v -m644 docs/*.{css,html}          /usr/share/gtk-doc/html/babl          &&
install -v -m644 docs/graphics/*.{html,svg} /usr/share/gtk-doc/html/babl/graphics

