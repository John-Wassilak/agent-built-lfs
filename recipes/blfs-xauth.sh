#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/x7app.html (xauth section)
# title  : xauth-1.1.5
# Built 2026-08-26 -- real, direct blocker for startx: `startx` calls
# xauth internally to manage the X11 auth cookie, and fails outright
# without it (confirmed via a live test: "xauth: command not found"
# in the startx log, immediately before the actual VT-permission
# failure -- see BUILD-REPORT.md's Phase 4 testing section). Needed
# libXmu (blfs-libxmu.sh -> blfs-libxt.sh) first.
set -e

./configure $XORG_CONFIG
make
make install
