#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libxslt.html
# title  : libxslt-1.1.45
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Recommended (at runtime) docbook-xml-4.5 and docbook-xsl-nons-1.79.2 Note Although it
#   ctx: is not a direct dependency, many applications using libxslt will expect docbook-xml-4.5
#   ctx: and docbook-xsl-nons-1.79.2 to be present. Optional libgcrypt-1.12.0 (only needed for
#   ctx: the deprecated EXSLT crypto extension, see Command Explanations) Installation of libxslt
#   ctx: Install libxslt by running the following commands:
./configure --prefix=/usr    \
            --disable-static \
            --without-python \
            --docdir=/usr/share/doc/libxslt-1.1.45 &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

