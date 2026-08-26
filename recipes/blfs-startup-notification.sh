#!/bin/bash
# HAND-AUTHORED recipe from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/startup-notification.html
# title  : startup-notification-0.12
# rationale: Firefox Required dependency. Required: Xorg Libraries,
# xcb-util (both already built, tiers 5/10).
set -e

./configure --prefix=/usr --disable-static
make

make install
install -v -m644 -D doc/startup-notification.txt \
  /usr/share/doc/startup-notification-0.12/startup-notification.txt

echo "### pkg-config"
pkg-config --modversion libstartup-notification-1.0 2>&1 || true
