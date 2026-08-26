#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libgcrypt.html
# title  : libgcrypt-1.12.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: pt/libgcrypt-1.12.0.tar.bz2 Download MD5 sum: f43a87fa7d779fbfb7a0985567521850 Download
#   ctx: size: 4.3 MB Estimated disk space required: 158 MB (with tests) Estimated build time:
#   ctx: 0.2 SBU (with documentation; add 0.9 SBU for tests) libgcrypt Dependencies Required
#   ctx: libgpg-error-1.59 Optional texlive-20250308 (or install-tl-unx) Installation of
#   ctx: libgcrypt Install libgcrypt by running the following commands:
./configure --prefix=/usr &&
make                      &&

make -C doc html                                                       &&
makeinfo --html --no-split -o doc/gcrypt_nochunks.html doc/gcrypt.texi &&
makeinfo --plaintext       -o doc/gcrypt.txt           doc/gcrypt.texi

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install &&
install -v -dm755   /usr/share/doc/libgcrypt-1.12.0 &&
install -v -m644    README doc/{README.apichanges,fips*,libgcrypt*} \
                    /usr/share/doc/libgcrypt-1.12.0 &&

install -v -dm755   /usr/share/doc/libgcrypt-1.12.0/html &&
install -v -m644 doc/gcrypt.html/* \
                    /usr/share/doc/libgcrypt-1.12.0/html &&
install -v -m644 doc/gcrypt_nochunks.html \
                    /usr/share/doc/libgcrypt-1.12.0      &&
install -v -m644 doc/gcrypt.{txt,texi} \
                    /usr/share/doc/libgcrypt-1.12.0

