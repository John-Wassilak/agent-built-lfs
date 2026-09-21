#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/graphene.html
# title  : Graphene-1.10.8
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ownload (HTTP): https://download.gnome.org/sources/graphene/1.10/graphene-1.10.8.tar.xz
#   ctx: Download MD5 sum: 169e3c507b5a5c26e9af492412070b81 Download size: 328 KB Estimated disk
#   ctx: space required: 7.6 MB Estimated build time: less than 0.1 SBU (with tests) Graphene
#   ctx: Dependencies Required GLib-2.86.4 (with GObject Introspection) Installation of Graphene
#   ctx: Install Graphene by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install

