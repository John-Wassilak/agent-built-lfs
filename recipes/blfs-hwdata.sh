#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/hwdata.html
# title  : hwdata-0.410
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ackage is known to build and work properly using an LFS 13.1 platform. Package
#   ctx: Information Download (HTTP):
#   ctx: https://github.com/vcrhonek/hwdata/archive/v0.410/hwdata-0.410.tar.gz Download MD5 sum:
#   ctx: 07f1de937ff5b830280f6157221164eb Download size: 2.6 MB Estimated disk space required: 21
#   ctx: MB Estimated build time: less than 0.1 SBU Installation of hwdata Install hwdata by
#   ctx: running the following commands:
./configure --prefix=/usr --disable-blacklist

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make install

