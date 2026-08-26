#!/bin/bash
# HAND-AUTHORED recipe from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libarchive.html
# title  : libarchive-3.8.5
# rationale: Firefox Required dependency. No Required deps of its own
# (libxml2/lzo/nettle all Optional, skipped -- none of them add anything
# Firefox needs from libarchive specifically).
set -e

./configure --prefix=/usr --disable-static
make

make install
ln -sfv bsdunzip /usr/bin/unzip

echo "### pkg-config"
pkg-config --modversion libarchive 2>&1 || true
