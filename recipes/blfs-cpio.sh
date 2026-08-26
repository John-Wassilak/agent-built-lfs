#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/cpio.html
# title  : cpio-2.15
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Package Information Download (HTTP): https://ftpmirror.gnu.org/cpio/cpio-2.15.tar.bz2
#   ctx: Download MD5 sum: 3394d444ca1905ea56c94b628b706a0b Download size: 1.6 MB Estimated disk
#   ctx: space required: 21 MB (with tests and docs) Estimated build time: 0.3 SBU (with tests
#   ctx: and docs) CPIO Dependencies Optional texlive-20250308 (or install-tl-unx) Installation
#   ctx: of cpio Add a workaround for an issue shown by gcc15:
sed -e "/^extern int (\*xstat)/s/()/(const char * restrict,  struct stat * restrict)/" \
    -i src/extern.h
sed -e "/^int (\*xstat)/s/()/(const char * restrict,  struct stat * restrict)/" \
    -i src/global.c

# --- block 1 --------------------------------------------------
#   ctx: Install cpio by running the following commands:
./configure --prefix=/usr \
            --enable-mt   \
            --with-rmt=/usr/libexec/rmt &&
make &&
makeinfo --html            -o doc/html      doc/cpio.texi &&
makeinfo --html --no-split -o doc/cpio.html doc/cpio.texi &&
makeinfo --plaintext       -o doc/cpio.txt  doc/cpio.texi

# --- block 2 --------------------------------------------------
#   ctx: If you have texlive-20250308 installed and wish to create PDF or Postscript
#   ctx: documentation, issue one or both of the following commands:
#   REVIEWED [drop]: 'make -C doc pdf && make -C doc ps', gated on 'If you have texlive-20250308 installed'. texlive is not installed.
# make -C doc pdf &&
# make -C doc ps

# --- block 3 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install &&
install -v -m755 -d /usr/share/doc/cpio-2.15/html &&
install -v -m644    doc/html/* \
                    /usr/share/doc/cpio-2.15/html &&
install -v -m644    doc/cpio.{html,txt} \
                    /usr/share/doc/cpio-2.15

# --- block 4 --------------------------------------------------
#   ctx: If you built PDF or Postscript documentation, install it by issuing the following
#   ctx: commands as the root user:
#   REVIEWED [drop]: Installs the pdf/ps/dvi docs built by block 2. Not built, so nothing to install and the install would fail.
# install -v -m644 doc/cpio.{pdf,ps,dvi} \
#                  /usr/share/doc/cpio-2.15

