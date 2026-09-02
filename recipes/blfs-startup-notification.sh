#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/startup-notification.html
# title  : startup-notification-0.12
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: g/software/startup-notification/releases/startup-notification-0.12.tar.gz Download MD5
#   ctx: sum: 2cd77326d4dcaed9a5a23a1232fb38e9 Download size: 347 KB Estimated disk space
#   ctx: required: 4 MB Estimated build time: less than 0.1 SBU startup-notification Dependencies
#   ctx: Required Xorg Libraries and xcb-util-0.4.1 Installation of startup-notification Install
#   ctx: startup-notification by running the following commands:
./configure --prefix=/usr --disable-static &&
make

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make install &&
install -v -m644 -D doc/startup-notification.txt \
    /usr/share/doc/startup-notification-0.12/startup-notification.txt

