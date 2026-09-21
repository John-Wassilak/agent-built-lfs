#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/hwdata.html
# title  : hwdata-0.404
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ackage is known to build and work properly using an LFS 13.0 platform. Package
#   ctx: Information Download (HTTP):
#   ctx: https://github.com/vcrhonek/hwdata/archive/v0.404/hwdata-0.404.tar.gz Download MD5 sum:
#   ctx: 272bc44afc686355c17ef5d726cfe191 Download size: 2.5 MB Estimated disk space required: 10
#   ctx: MB Estimated build time: less than 0.1 SBU Installation of hwdata Install hwdata by
#   ctx: running the following commands:
./configure --prefix=/usr --disable-blacklist

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make install

