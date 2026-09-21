#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter06/coreutils.html
# title  : 6.5. Coreutils-9.10
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Coreutils package contains the basic utility programs needed by every operating
#   ctx: system. Approximate build time: 0.3 SBU Required disk space: 185 MB 6.5.1. Installation
#   ctx: of Coreutils Prepare Coreutils for compilation:
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime

# --- block 1 --------------------------------------------------
#   ctx: The meaning of the configure options: --enable-install-program=hostname This enables the
#   ctx: hostname binary to be built and installed – it is disabled by default but is required by
#   ctx: the Perl test suite. Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: Install the package:
make DESTDIR=$LFS install

# --- block 3 --------------------------------------------------
#   ctx: Move programs to their final expected locations. Although this is not necessary in this
#   ctx: temporary environment, we must do so because some programs hardcode executable
#   ctx: locations:
mv -v $LFS/usr/bin/chroot              $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/'                    $LFS/usr/share/man/man8/chroot.8

