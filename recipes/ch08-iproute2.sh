#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/iproute2.html
# title  : 8.68. IPRoute2-6.18.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: contains programs for basic and advanced IPV4-based networking. Approximate build time:
#   ctx: 0.1 SBU Required disk space: 17 MB 8.68.1. Installation of IPRoute2 The arpd program
#   ctx: included in this package will not be built since it depends on Berkeley DB, which is not
#   ctx: installed in LFS. However, a directory and a man page for arpd will still be installed.
#   ctx: Prevent this by running the commands shown below.
sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8

# --- block 1 --------------------------------------------------
#   ctx: Compile the package:
make NETNS_RUN_DIR=/run/netns

# --- block 2 --------------------------------------------------
#   ctx: This package does not have a working test suite. Install the package:
make SBINDIR=/usr/sbin install

# --- block 3 --------------------------------------------------
#   ctx: If desired, install the documentation:
install -vDm644 COPYING README* -t /usr/share/doc/iproute2-6.18.0

