#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/x7lib.html (libXt section)
# title  : libXt-1.3.1
# Built 2026-08-26 -- libXmu dependency (see blfs-libxmu.sh), itself
# needed for xauth (see blfs-xauth.sh), needed for startx to work at all.
set -e

./configure $XORG_CONFIG
make
make install
