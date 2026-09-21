#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter06/ncurses.html
# title  : 6.3. Ncurses-6.6
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Ncurses package contains libraries for terminal-independent handling of character
#   ctx: screens. Approximate build time: 0.4 SBU Required disk space: 54 MB 6.3.1. Installation
#   ctx: of Ncurses First, run the following commands to build the tic program on the build host.
#   ctx: We install it in $LFS/tools, so that it is found in the PATH when needed:
mkdir build
pushd build
  ../configure --prefix=$LFS/tools AWK=gawk
  make -C include
  make -C progs tic
  install progs/tic $LFS/tools/bin
popd

# --- block 1 --------------------------------------------------
#   ctx: Prepare Ncurses for compilation:
./configure --prefix=/usr                \
            --host=$LFS_TGT              \
            --build=$(./config.guess)    \
            --mandir=/usr/share/man      \
            --with-manpage-format=normal \
            --with-shared                \
            --without-normal             \
            --with-cxx-shared            \
            --without-debug              \
            --without-ada                \
            --disable-stripping          \
            AWK=gawk

# --- block 2 --------------------------------------------------
#   ctx: not be available once we enter the chroot environment. --disable-stripping This switch
#   ctx: prevents the building system from using the strip program from the host. Using host
#   ctx: tools on cross-compiled programs can cause failure. AWK=gawk This switch prevents the
#   ctx: building system from using the mawk program from the host. Some versions of mawk can
#   ctx: cause this package to fail to build. Compile the package:
make

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make DESTDIR=$LFS install
ln -sv libncursesw.so $LFS/usr/lib/libncurses.so
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i $LFS/usr/include/curses.h

