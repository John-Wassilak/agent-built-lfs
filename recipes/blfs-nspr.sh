#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/nspr.html
# title  : NSPR-4.38.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ckage is known to build and work properly using an LFS 13.0 platform. Package
#   ctx: Information Download (HTTP):
#   ctx: https://archive.mozilla.org/pub/nspr/releases/v4.38.2/src/nspr-4.38.2.tar.gz Download
#   ctx: MD5 sum: c1b2e2b3f63774bbbec25af84567135b Download size: 1 MB Estimated disk space
#   ctx: required: 11 MB Estimated build time: less than 0.1 SBU Installation of NSPR Install
#   ctx: NSPR by running the following commands:
cd nspr &&

sed -i '/^RELEASE/s|^|#|' pr/src/misc/Makefile.in &&
sed -i 's|$(LIBRARY) ||'  config/rules.mk         &&

./configure --prefix=/usr   \
            --with-mozilla  \
            --with-pthreads \
            $([ $(uname -m) = x86_64 ] && echo --enable-64bit) &&
make

# --- block 1 --------------------------------------------------
#   ctx: The test suite is designed for testing changes to nss or nspr and is not particularly
#   ctx: useful for checking a released version (e.g. it needs to be run on a non-optimized build
#   ctx: with both nss and nspr directories existing alongside each other). For further details,
#   ctx: see the Editor Notes for nss at https://wiki.linuxfromscratch.org/blfs/wiki/nss Now, as
#   ctx: the root user:
make install

