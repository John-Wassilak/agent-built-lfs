#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/basicnet/libnl.html
# title  : libnl-3.12.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: load size: 1.1 MB Estimated disk space required: 32 MB (with API documentation)
#   ctx: Estimated build time: 0.2 SBU (with API documentation) Optional Download Download
#   ctx: (HTTP):
#   ctx: https://github.com/thom311/libnl/releases/download/libnl3_12_0/libnl-doc-3.12.0.tar.gz
#   ctx: Download MD5 sum: befe7b001c82640f8e937c603afc7edc Download size: 4.3 MB Installation of
#   ctx: libnl Install libnl by running the following commands:
./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --disable-static  &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

# --- block 2 --------------------------------------------------
#   ctx: If you wish to install the API documentation, as the root user:
#   REVIEWED [drop]: Optional API documentation, installed from a separate libnl-doc-3.12.0.tar.gz tarball that is not part of this build (not fetched -- same skip as every other doc-tool trap in this project).
# mkdir -vp /usr/share/doc/libnl-3.12.0 &&
# tar -xf ../libnl-doc-3.12.0.tar.gz --strip-components=1 --no-same-owner \
#     -C  /usr/share/doc/libnl-3.12.0

