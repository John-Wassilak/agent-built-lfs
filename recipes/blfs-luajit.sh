#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/luajit.html
# title  : luajit-20260213
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: e This package is known to build and work properly using an LFS 13.0 platform. Package
#   ctx: Information Download (HTTP):
#   ctx: https://anduin.linuxfromscratch.org/BLFS/luajit/luajit-20260213.tar.xz Download MD5 sum:
#   ctx: 6459b2696188b74edf950926cb3bacd1 Download size: 736 KB Estimated disk space required:
#   ctx: 9.1 MB Estimated build time: 0.2 SBU Installation of luajit Install luajit by running
#   ctx: the following commands:
make PREFIX=/usr amalg

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make PREFIX=/usr install &&
rm -v /usr/lib/libluajit-5.1.a

