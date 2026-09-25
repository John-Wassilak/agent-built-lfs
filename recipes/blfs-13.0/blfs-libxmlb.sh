#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libxmlb.html
# title  : libxmlb-0.3.25
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ses/download/0.3.25/libxmlb-0.3.25.tar.xz Download MD5 sum:
#   ctx: 7c8e042d5305aad7a9d739410bbb6e13 Download size: 104 KB Estimated disk space required:
#   ctx: 5.0 MB (with tests) Estimated build time: 0.1 SBU (With tests) libxmlb Dependencies
#   ctx: Required GLib-2.86.4 (GObject Introspection recommended) Optional GTK-Doc-1.35.1 and
#   ctx: libstemmer Installation of libxmlb Install libxmlb by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release -D gtkdoc=false .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install

