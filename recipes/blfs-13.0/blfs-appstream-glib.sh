#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/appstream-glib.html
# title  : appstream-glib-0.8.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: imated disk space required: 15 MB (with tests) Estimated build time: 0.1 SBU (with
#   ctx: tests) appstream-glib Dependencies Required cURL-8.18.0, gdk-pixbuf-2.44.5, GTK-3.24.51,
#   ctx: JSON-GLib-1.10.8, libarchive-3.8.5, and libyaml-0.2.5 Optional docbook-xml-4.5,
#   ctx: docbook-xsl-nons-1.79.2, GTK-Doc-1.35.1, and libxslt-1.1.45 Installation of
#   ctx: appstream-glib Install appstream-glib by running the following commands:
mkdir build &&
cd    build &&

meson setup ..            \
      --prefix=/usr       \
      --buildtype=release \
      -D rpm=false        &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install

