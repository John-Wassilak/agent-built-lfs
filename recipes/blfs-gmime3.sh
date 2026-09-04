#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/gmime3.html
# title  : GMime-3.2.15
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 617 Download size: 2.1 MB Estimated disk space required: 23 MB (with tests) Estimated
#   ctx: build time: 0.2 SBU (with tests) GMime Dependencies Required GLib-2.86.4 (GObject
#   ctx: Introspection recommended) and libgpg-error-1.59 Optional DocBook-utils-0.6.14,
#   ctx: gpgme-2.0.1, GTK-Doc-1.35.1, libnsl-2.0.1, Vala-0.56.18, and Gtk# (requires Mono)
#   ctx: Installation of GMime Install GMime by running the following commands:
./configure --prefix=/usr --disable-static &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Two tests, test-pgp and test-pgpmime, are known
#   ctx: to fail. Now, as the root user:
make install

