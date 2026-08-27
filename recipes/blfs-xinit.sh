#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/xinit.html
# title  : xinit-1.4.4
set -e

./configure $XORG_CONFIG --with-xinitdir=/etc/X11/app-defaults
make
make install
ldconfig
