#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/vala.html
# title  : Vala-0.56.18
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: _13_fix-1.patch Vala Dependencies Required GLib-2.86.4 (GObject Introspection required
#   ctx: for the tests) Recommended Graphviz-14.1.2 (Required for valadoc) Optional dbus-1.16.2
#   ctx: (Required for the tests), libxslt-1.1.45 (Required for generating the documentation),
#   ctx: help2man, jing, and weasyprint Installation of Vala First, fix an issue causing valadoc
#   ctx: to crash when compiled against graphviz-13 or later:
patch -Np1 -i ../vala-0.56.18-graphviz_13_fix-1.patch

# --- block 1 --------------------------------------------------
#   ctx: Install Vala by running the following commands:
./configure --prefix=/usr &&
make bootstrap

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

