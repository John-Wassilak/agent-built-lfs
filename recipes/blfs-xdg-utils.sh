#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/xsoft/xdg-utils.html
# title  : xdg-utils-1.2.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: r.gz Download MD5 sum: 4c72585a98ba8f775cb9e72b066cc0df Download size: 304 KB Estimated
#   ctx: disk space required: 3.3 MB (with tests) Estimated build time: 2.5 SBU (with tests)
#   ctx: xdg-utils Dependencies Required xmlto-0.0.29 with one of Lynx-2.9.2, Links-2.30, or W3m
#   ctx: Required (runtime) Xorg Applications Optional (runtime) dbus-1.16.2 Installation of
#   ctx: xdg-utils Compile xdg-utils with the following commands:
./configure --prefix=/usr &&
for d in scripts/desc/*.xml; do
    b=$(basename "$d" .xml)
    echo "See \`man $b\` or https://gitlab.freedesktop.org/xdg/xdg-utils for full usage." > "scripts/$b.txt"
done &&
make -C scripts scripts

# --- block 1 --------------------------------------------------
#   ctx: Caution The tests for the scripts must be made from an X-Window based session. There are
#   ctx: several run-time requirements to run the tests including a browser and an MTA. Running
#   ctx: the tests as root user is not recommended. To run the tests, issue: make -k test. Now
#   ctx: install it as the root user:
make install

