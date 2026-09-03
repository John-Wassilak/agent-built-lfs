#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/json-glib.html
# title  : JSON-GLib-1.10.8
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: -1.10.8.tar.xz Download MD5 sum: 95c3d5dd56d4ada808480739889b75bc Download size: 1.2 MB
#   ctx: Estimated disk space required: 15 MB (with tests) Estimated build time: 0.1 SBU (with
#   ctx: tests) JSON-GLib Dependencies Required GLib-2.86.4 (GObject Introspection required if
#   ctx: building GNOME) Optional docutils-0.22.4 and Gi-DocGen-2026.1 Installation of JSON GLib
#   ctx: Install JSON GLib by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: If docutils-0.22.4 is installed, build the man pages:
meson configure -D man=true &&
ninja

# --- block 2 --------------------------------------------------
#   ctx: If Gi-DocGen-2026.1 is installed, build the API documentation:
sed "/json_docdir =/s|$| / 'json-glib-1.10.8'|" -i ../doc/meson.build &&
meson configure -D documentation=enabled &&
ninja

# --- block 3 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. One test, node, is known to fail. Now, as the
#   ctx: root user:
ninja install

