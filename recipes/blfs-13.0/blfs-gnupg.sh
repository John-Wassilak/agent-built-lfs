#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/postlfs/gnupg.html
# title  : GnuPG-2.5.17
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: s protocol) and pinentry-1.3.2 (Run-time requirement for most of the package's
#   ctx: functionality) Optional cURL-8.18.0, Fuse-3.18.1, ImageMagick-7.1.2-13 (for the convert
#   ctx: utility, used for generating the documentation), libusb-1.0.29, an MTA, texlive-20250308
#   ctx: (or install-tl-unx), fig2dev (for generating documentation), and GNU adns Installation
#   ctx: of GnuPG Install GnuPG by running the following commands:
mkdir build &&
cd    build &&

../configure --prefix=/usr        \
             --localstatedir=/var \
             --sysconfdir=/etc    \
             --docdir=/usr/share/doc/gnupg-2.5.17 &&
make &&

makeinfo --html --no-split -I doc -o doc/gnupg_nochunks.html ../doc/gnupg.texi &&
makeinfo --plaintext       -I doc -o doc/gnupg.txt           ../doc/gnupg.texi &&
make -C doc html

# --- block 1 --------------------------------------------------
#   ctx: If you have texlive-20250308 installed and you wish to create documentation in the pdf
#   ctx: format, issue the following command:
#   REVIEWED [drop]: Optional PDF docs need texlive, not installed.
# make -C doc pdf

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install &&

install -v -m755 -d /usr/share/doc/gnupg-2.5.17/html            &&
install -v -m644    doc/gnupg_nochunks.html \
                    /usr/share/doc/gnupg-2.5.17/html/gnupg.html &&
install -v -m644    ../doc/*.texi doc/gnupg.txt \
                    /usr/share/doc/gnupg-2.5.17 &&
install -v -m644    doc/gnupg.html/* \
                    /usr/share/doc/gnupg-2.5.17/html

# --- block 3 --------------------------------------------------
#   ctx: If you created the pdf format of the documentation, install them using the following
#   ctx: command as the root user:
#   REVIEWED [drop]: Installs the PDF docs from block 1, which was dropped.
# install -v -m644 doc/gnupg.pdf \
#                  /usr/share/doc/gnupg-2.5.17

