#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/npth.html
# title  : npth-1.8
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: known to build and work properly using an LFS 13.0 platform. Package Information
#   ctx: Download (HTTP): https://www.gnupg.org/ftp/gcrypt/npth/npth-1.8.tar.bz2 Download MD5
#   ctx: sum: cb4fc0402be5ba67544e499cb2c1a74d Download size: 312 KB Estimated disk space
#   ctx: required: 2.9 MB (with checks) Estimated build time: less than 0.1 SBU (with checks)
#   ctx: Installation of NPth Install NPth by running the following commands:
./configure --prefix=/usr &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

