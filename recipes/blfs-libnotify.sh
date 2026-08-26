#!/bin/bash
# HAND-AUTHORED recipe from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/libnotify.html
# title  : libnotify-0.8.8
# rationale: Firefox Required dependency. Required: gdk-pixbuf (already
# built, tier 6). meson.build gates its GTK4 dependency behind
# get_option('tests') (`required: get_option('tests')`), which defaults to
# true -- the book's own recipe doesn't disable it, so the first pass
# failed on a real "Dependency gtk4 not found" configure error even though
# the book only lists GTK4 as needed for tests. Not worth building an
# entire second GTK toolkit (GTK4, plus its own new deps: graphene, ISO
# Codes, PyGObject) for one test suite this project doesn't run anyway --
# same "book leaves an optional test/doc dependency on by default" pattern
# as pango/gdk-pixbuf/json-c/popt in earlier tiers. Fixed with -D tests=false.
set -e

mkdir build
cd build

meson setup --prefix=/usr \
  --buildtype=release \
  -D tests=false \
  -D gtk_doc=false \
  -D man=false \
  ..
ninja

ninja install
if [ -e /usr/share/doc/libnotify ]; then
  rm -rf /usr/share/doc/libnotify-0.8.8
  mv -v /usr/share/doc/libnotify /usr/share/doc/libnotify-0.8.8
fi

echo "### pkg-config"
pkg-config --modversion libnotify 2>&1 || true
