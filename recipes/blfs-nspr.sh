#!/bin/bash
# HAND-AUTHORED recipe from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/nspr.html
# title  : NSPR-4.38.2
# rationale: Required by NSS (next in this tier), itself a Firefox
# Recommended dependency (--with-system-nss/nspr in the book's mozconfig).
set -e

cd nspr

sed -i '/^RELEASE/s|^|#|' pr/src/misc/Makefile.in
sed -i 's|$(LIBRARY) ||' config/rules.mk

./configure --prefix=/usr \
  --with-mozilla \
  --with-pthreads \
  $([ "$(uname -m)" = x86_64 ] && echo --enable-64bit)
make

make install

echo "### pkg-config"
pkg-config --modversion nspr 2>&1 || true
