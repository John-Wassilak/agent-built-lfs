#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/unixodbc.html
# title  : unixODBC-2.3.14
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: platform. Package Information Download (HTTP):
#   ctx: https://github.com/lurcher/unixODBC/archive/v2.3.14/unixODBC-2.3.14.tar.gz Download MD5
#   ctx: sum: 2de94476f9aa78a8e0f9b6bb4b9acc90 Download size: 836 KB Estimated disk space
#   ctx: required: 30 MB Estimated build time: 0.2 SBU (using parallelism=4) unixODBC
#   ctx: Dependencies Optional Mini SQL Installation of unixODBC Install unixODBC by running the
#   ctx: following commands:
autoreconf -fiv &&
./configure --prefix=/usr --sysconfdir=/etc/unixODBC &&
make

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make install &&

find doc -name "Makefile*" -delete                &&
chmod 644 doc/{lst,ProgrammerManual/Tutorial}/*   &&

install -v -m755 -d /usr/share/doc/unixODBC-2.3.14 &&
cp      -v -R doc/* /usr/share/doc/unixODBC-2.3.14

