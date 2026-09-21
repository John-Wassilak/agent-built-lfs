#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libtasn1.html
# title  : libtasn1-4.21.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: kage Information Download (HTTP):
#   ctx: https://ftpmirror.gnu.org/libtasn1/libtasn1-4.21.0.tar.gz Download MD5 sum:
#   ctx: 2ee1d9f3aa66f1e308c46a283aa9a8c2 Download size: 1.7 MB Estimated disk space required: 16
#   ctx: MB (with tests) Estimated build time: 0.5 SBU (with tests) libtasn1 Dependencies
#   ctx: Optional GTK-Doc-1.35.1 and Valgrind-3.26.0 Installation of libtasn1 Install libtasn1 by
#   ctx: running the following commands:
./configure --prefix=/usr --disable-static &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

# --- block 2 --------------------------------------------------
#   ctx: If you did not pass the --enable-gtk-doc parameter to the configure script, you can
#   ctx: install the API documentation using the following command as the root user:
#   REVIEWED [drop]: Installs the GTK-Doc API documentation ('If you did not pass --enable-gtk-doc ... you can install the API documentation'). GTK-Doc is not installed and the docs are not needed.
# make -C doc/reference install-data-local

