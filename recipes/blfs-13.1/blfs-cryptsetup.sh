#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/postlfs/cryptsetup.html
# title  : cryptsetup-2.8.7
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Installation of cryptsetup Install cryptsetup by running the following commands:
./configure --prefix=/usr       \
            --disable-ssh-token \
            --disable-asciidoc  &&
make

# --- block 1 --------------------------------------------------
#   ctx: Now, as the root user:
make install

