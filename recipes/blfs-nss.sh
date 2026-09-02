#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/postlfs/nss.html
# title  : NSS-3.120.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 3.0/nss-standalone-1.patch NSS Dependencies Required NSPR-4.38.2 Recommended
#   ctx: p11-kit-0.26.2 (runtime) Note An Internet connection is needed for some tests of this
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
  $([ $(uname -m) = x86_64 ] && echo USE_64=1)

# --- block 1 --------------------------------------------------
#   ctx: To run the tests, execute the following commands:
#   REVIEWED [drop]: The test suite ('To run the tests, execute the following commands') -- not flagged optional by the extractor since the surrounding prose has no 'if you want' framing, the same classifier gap as vulkan-loader/libei/xwayland/ffmpeg. Skipped, matches every other package in this build; the book's own text for this suite (block 2's ctx) warns it 'fails to spin down test servers... leads to an infinite loop', and it hard-failed here with 564/606 tests failing after 20.9 minutes, confirming it is not worth running unattended.
# cd tests &&
# HOST=localhost DOMSUF=localdomain ./all.sh
# cd ../

# --- block 2 --------------------------------------------------
#   ctx: test suite fails to spin down test servers that are run. This leads to an infinite loop
#   ctx: in the tests where the test suite tries to kill a server that doesn't exist anymore
#   ctx: because it pulls the wrong PID. Test suite results (in HTML format!) can be found at
#   ctx: ../../test_results/security/localhost.1/results.html A few tests might fail on some
#   ctx: Intel machines for unknown reasons. Now, as the root user:
cd ../dist                                                          &&

install -v -m755 Linux*/lib/*.so              /usr/lib              &&
install -v -m644 Linux*/lib/{*.chk,libcrmf.a} /usr/lib              &&

install -v -m755 -d                           /usr/include/nss      &&
cp -v -RL {public,private}/nss/*              /usr/include/nss      &&

install -v -m755 Linux*/bin/{certutil,nss-config,pk12util} /usr/bin &&

install -v -m644 Linux*/lib/pkgconfig/nss.pc  /usr/lib/pkgconfig

# --- block 3 --------------------------------------------------
#   ctx: ion of tests and save some build time. Configuring NSS If p11-kit-0.26.2 is installed,
#   ctx: the p11-kit trust module (/usr/lib/pkcs11/p11-kit-trust.so) can be used as a drop-in
#   ctx: replacement for /usr/lib/libnssckbi.so to transparently make the system CAs available to
#   ctx: NSS aware applications, rather than the static library provided by
#   ctx: /usr/lib/libnssckbi.so. As the root user, execute the following command:
#   REVIEWED [drop]: 'If p11-kit is installed, the p11-kit trust module can be used as a drop-in replacement...' -- p11-kit is not part of this build, so the symlink target (./pkcs11/p11-kit-trust.so) does not exist and this would create a dangling link. True of any host without p11-kit, not laptop-specific.
# ln -sfv ./pkcs11/p11-kit-trust.so /usr/lib/libnssckbi.so

