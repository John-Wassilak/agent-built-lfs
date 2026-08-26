#!/bin/bash
# HAND-AUTHORED recipe from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/postlfs/nss.html
# title  : NSS-3.120.1
# rationale: Firefox Recommended dependency (--with-system-nss/nspr in the
# book's mozconfig). Required: NSPR (just built, previous step in this
# tier). Recommended: p11-kit (already built, tier 6). USE_SYSTEM_ZLIB and
# NSS_USE_SYSTEM_SQLITE both rely on zlib/sqlite already present from the
# base LFS build (ch08). Tests skipped (needs network + a long run, no
# verification value here -- same policy as every other test suite in this
# project).
set -e

patch -Np1 -i ../nss-standalone-1.patch

cd nss

make BUILD_OPT=1 \
  NSPR_INCLUDE_DIR=/usr/include/nspr \
  USE_SYSTEM_ZLIB=1 \
  ZLIB_LIBS=-lz \
  NSS_ENABLE_WERROR=0 \
  NSS_USE_SYSTEM_SQLITE=1 \
  $([ "$(uname -m)" = x86_64 ] && echo USE_64=1)

cd ../dist

install -v -m755 Linux*/lib/*.so /usr/lib
install -v -m644 Linux*/lib/{*.chk,libcrmf.a} /usr/lib

install -v -m755 -d /usr/include/nss
cp -v -RL {public,private}/nss/* /usr/include/nss

install -v -m755 Linux*/bin/{certutil,nss-config,pk12util} /usr/bin

install -v -m644 Linux*/lib/pkgconfig/nss.pc /usr/lib/pkgconfig

echo "### pkg-config"
pkg-config --modversion nss 2>&1 || true
