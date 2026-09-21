#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/glibmm2.html
# title  : GLibmm-2.86.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 0899c4d4a47d Download size: 9.1 MB Estimated disk space required: 95 MB (with tests)
#   ctx: Estimated build time: 0.4 SBU (Using parallelism=4; with tests) GLibmm Dependencies
#   ctx: Required GLib-2.86.4 and libsigc++-3.6.0 Optional Doxygen-1.16.1, glib-networking-2.80.1
#   ctx: (for tests), GnuTLS-3.8.12 (for tests), libxslt-1.1.45, and mm-common Installation of
#   ctx: GLibmm Install GLibmm by running the following commands:
mkdir bld &&
cd    bld &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install

