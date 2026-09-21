#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/duktape.html
# title  : duktape-2.7.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: y and compact footprint. Note This package is known to build and work properly using an
#   ctx: LFS 13.0 platform. Package Information Download (HTTP):
#   ctx: https://duktape.org/duktape-2.7.0.tar.xz Download MD5 sum:
#   ctx: b3200b02ab80125b694bae887d7c1ca6 Download size: 1003 KB Estimated disk space required:
#   ctx: 25 MB Estimated build time: 0.3 SBU Installation of duktape Install duktape by running
#   ctx: the following commands:
sed -i 's/-Os/-O2/' Makefile.sharedlibrary
make -f Makefile.sharedlibrary INSTALL_PREFIX=/usr

# --- block 1 --------------------------------------------------
#   ctx: Now, as the root user:
make -f Makefile.sharedlibrary INSTALL_PREFIX=/usr install

