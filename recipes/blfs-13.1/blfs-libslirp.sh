#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/basicnet/libslirp.html
# title  : libslirp-4.9.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: form. Package Information Download (HTTP):
#   ctx: https://gitlab.freedesktop.org/slirp/libslirp/-/archive/v4.9.3/libslirp-v4.9.3.tar.bz2
#   ctx: Download MD5 sum: bf2162cee75eef0faf0eb3fe60ec0da3 Download size: 132 KB Estimated disk
#   ctx: space required: 2.4 MB Estimated build time: less than 0.1 SBU libslirp Dependencies
#   ctx: Required GLib-2.88.3 Installation of Libslirp Install libslirp by running the following
#   ctx: commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&

ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test Now, as the root user:
ninja install

