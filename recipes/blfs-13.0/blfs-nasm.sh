#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/nasm.html
# title  : NASM-3.01
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 6dfcc550 Download size: 1.4 MB Estimated disk space required: 70 MB Estimated build
#   ctx: time: 0.2 SBU Additional Downloads Optional documentation:
#   ctx: https://www.nasm.us/pub/nasm/releasebuilds/3.01/nasm-3.01-xdoc.tar.xz NASM Dependencies
#   ctx: Optional (for generating documentation): asciidoc-10.2.1 and xmlto-0.0.29 Installation
#   ctx: of NASM If you downloaded the optional documentation, put it into the source tree:
#   REVIEWED [drop]: Optional xdoc tarball not fetched (docs only).
# tar -xf ../nasm-3.01-xdoc.tar.xz --strip-components=1

# --- block 1 --------------------------------------------------
#   ctx: Install NASM by running the following commands:
./configure --prefix=/usr &&
make

# --- block 2 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make install

# --- block 3 --------------------------------------------------
#   ctx: If you downloaded the optional documentation, install it with the following instructions
#   ctx: as the root user:
#   REVIEWED [drop]: Installs the docs from block 0, which was dropped.
# install -m755 -d         /usr/share/doc/nasm-3.01/html  &&
# cp -v doc/html/*.html    /usr/share/doc/nasm-3.01/html  &&
# cp -v doc/*.{txt,ps,pdf} /usr/share/doc/nasm-3.01

