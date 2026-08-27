#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/x7driver.html (Xorg Libinput Driver section)
# title  : Xorg-Libinput-Driver-1.5.0
set -e

./configure $XORG_CONFIG
make
make install
