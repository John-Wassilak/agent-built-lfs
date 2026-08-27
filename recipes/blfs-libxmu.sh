#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/x7lib.html (libXmu section)
# title  : libXmu-1.3.1
# Built 2026-08-26 -- xauth dependency (via libXmuu, a sub-library of
# this package), needed for startx to work at all. Required libXt
# first (blfs-libxt.sh).
set -e

./configure $XORG_CONFIG
make
make install
