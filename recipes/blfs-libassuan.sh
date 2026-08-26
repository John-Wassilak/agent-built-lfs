#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libassuan.html
# title  : libassuan-3.0.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 2 Download MD5 sum: c6f1bf4bd2aaa79cd1635dcc070ba51a Download size: 580 KB Estimated
#   ctx: disk space required: 6.5 MB (with tests, add 3.4 MB for pdf documentation) Estimated
#   ctx: build time: 0.1 SBU (with tests and html documentation) libassuan Dependencies Required
#   ctx: libgpg-error-1.59 Optional texlive-20250308 (or install-tl-unx) Installation of
#   ctx: libassuan Install libassuan by running the following commands:
./configure --prefix=/usr &&
make                      &&

make -C doc html                                                       &&
makeinfo --html --no-split -o doc/assuan_nochunks.html doc/assuan.texi &&
makeinfo --plaintext       -o doc/assuan.txt           doc/assuan.texi

# --- block 1 --------------------------------------------------
#   ctx: The above commands build the documentation in html and plaintext formats. If you wish to
#   ctx: build alternate formats of the documentation, you must have texlive-20250308 installed
#   ctx: and issue the following commands:
#   REVIEWED [drop]: Optional PDF/PS docs need texlive, not installed.
# make -C doc pdf ps

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install &&

install -v -dm755   /usr/share/doc/libassuan-3.0.2/html &&
install -v -m644 doc/assuan.html/* \
                    /usr/share/doc/libassuan-3.0.2/html &&
install -v -m644 doc/assuan_nochunks.html \
                    /usr/share/doc/libassuan-3.0.2      &&
install -v -m644 doc/assuan.{txt,texi} \
                    /usr/share/doc/libassuan-3.0.2

# --- block 3 --------------------------------------------------
#   ctx: If you built alternate formats of the documentation, install them by running the
#   ctx: following commands as the root user:
#   REVIEWED [drop]: Installs the PDF/PS/DVI docs from block 1, which was dropped.
# install -v -m644  doc/assuan.{pdf,ps,dvi} \
#                   /usr/share/doc/libassuan-3.0.2

