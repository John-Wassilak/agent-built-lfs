#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/jansson.html
# title  : Jansson-2.15.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: properly using an LFS 13.0 platform. Package Information Download (HTTP):
#   ctx: https://github.com/akheron/jansson/releases/download/v2.15.0/jansson-2.15.0.tar.bz2
#   ctx: Download MD5 sum: 6077c52677206a84304979b226322283 Download size: 476 KB Estimated disk
#   ctx: space required: 8.4 MB (with tests) Estimated build time: 0.1 SBU (with tests)
#   ctx: Installation of Jansson Install jansson by running the following commands:
./configure --prefix=/usr --disable-static &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

