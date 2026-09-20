#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.1-systemd book.
# source : book/13.1/chapter08/iproute2.html
# title  : 8.67 IPRoute2-7.1.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: e contains programs for basic and advanced IPV4-based networking. Approximate build
#   ctx: time: 0.1 SBU Required disk space: 18 MB 8.67.1 Installation of IPRoute2 The arpd
#   ctx: program included in this package will not be built since it depends on Berkeley DB,
#   ctx: which is not installed in LFS. However, a directory and a man page for arpd will still
#   ctx: be installed. Prevent this by running the commands shown below.
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
install -vDm644 COPYING README* -t /usr/share/doc/iproute2-7.1.0

