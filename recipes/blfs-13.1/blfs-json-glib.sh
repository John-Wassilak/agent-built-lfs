#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/json-glib.html
# title  : json-glib-1.10.8
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ib-1.10.8.tar.xz Download MD5 sum: 95c3d5dd56d4ada808480739889b75bc Download size: 1.2
#   ctx: MB Estimated disk space required: 15 MB (with tests) Estimated build time: 0.1 SBU (with
#   ctx: tests) json-glib Dependencies Required GLib-2.88.3 (GObject Introspection required if
#   ctx: building GNOME) Optional docutils-0.23 and Gi-DocGen-2026.1 Installation of json glib
#   ctx: Install json glib by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: If docutils-0.23 is installed, build the man pages:
#   REVIEWED [drop]: BLFS 13.1 general/json-glib.html: man pages, conditional on docutils-0.23 ('If docutils-0.23 is installed'). docutils is not installed (python3 -c 'import docutils' fails).
# meson configure -D man=true &&
# ninja

# --- block 2 --------------------------------------------------
#   ctx: If Gi-DocGen-2026.1 is installed, build the API documentation:
#   REVIEWED [drop]: BLFS 13.1 general/json-glib.html: API documentation, conditional on Gi-DocGen-2026.1. Not installed.
# sed "/json_docdir =/s|$| / 'json-glib-1.10.8'|" -i ../doc/meson.build &&
# meson configure -D documentation=enabled &&
# ninja

# --- block 3 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. One test, node, is known to fail. Now, as the
#   ctx: root user:
ninja install

