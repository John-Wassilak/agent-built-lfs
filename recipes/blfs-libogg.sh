#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/libogg.html
# title  : libogg-1.3.6
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: o build and work properly using an LFS 13.0 platform. Package Information Download
#   ctx: (HTTP): https://downloads.xiph.org/releases/ogg/libogg-1.3.6.tar.xz Download MD5 sum:
#   ctx: 529275432dff072f63d4ed0f1f961384 Download size: 432 KB Estimated disk space required:
#   ctx: 3.5 MB (with tests) Estimated build time: less than 0.1 SBU (with tests) Installation of
#   ctx: libogg Install libogg by running the following commands:
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/libogg-1.3.6 &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

