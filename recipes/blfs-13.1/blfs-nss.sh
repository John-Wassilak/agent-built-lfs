#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/postlfs/nss.html
# title  : NSS-3.126
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: /13.1/nss-standalone-1.patch NSS Dependencies Required NSPR-4.40 Recommended
#   ctx: p11-kit-0.26.5 (runtime) Note An Internet connection is needed for some tests of this
#   ctx: package. The system certificate store may need to be set up with make-ca-1.16.1 before
#   ctx: testing this package. Editor Notes: https://wiki.linuxfromscratch.org/blfs/wiki/nss
#   ctx: Installation of NSS Install NSS by running the following commands:
patch -Np1 -i ../nss-standalone-1.patch &&

cd nss &&

make BUILD_OPT=1                      \
  NSPR_INCLUDE_DIR=/usr/include/nspr  \
  USE_SYSTEM_ZLIB=1                   \
  ZLIB_LIBS=-lz                       \
  NSS_ENABLE_WERROR=0                 \
  NSS_USE_SYSTEM_SQLITE=1             \
  $([ "$(uname -m)" = x86_64 ] && echo USE_64=1)

# --- block 1 --------------------------------------------------
#   ctx: The test suite is known to hang indefinitely so the BLFS editors don't recommend to run
#   ctx: it. Now, as the root user:
cd ../dist                                         &&

install -v -m755 Linux*/lib/*.so  /usr/lib         &&
install -v -m644 Linux*/lib/*.chk /usr/lib         &&

install -v -m755 -d               /usr/include/nss &&
cp -v -RL {public,private}/nss/*  /usr/include/nss &&

install -v -m755 Linux*/bin/{certutil,nss-config,pk12util} /usr/bin &&

install -v -m644 Linux*/lib/pkgconfig/nss.pc  /usr/lib/pkgconfig

# --- block 2 --------------------------------------------------
#   ctx: ion of tests and save some build time. Configuring NSS If p11-kit-0.26.5 is installed,
#   ctx: the p11-kit trust module (/usr/lib/pkcs11/p11-kit-trust.so) can be used as a drop-in
#   ctx: replacement for /usr/lib/libnssckbi.so to transparently make the system CAs available to
#   ctx: NSS aware applications, rather than the static library provided by
#   ctx: /usr/lib/libnssckbi.so. As the root user, execute the following command:
ln -sfv ./pkcs11/p11-kit-trust.so /usr/lib/libnssckbi.so

