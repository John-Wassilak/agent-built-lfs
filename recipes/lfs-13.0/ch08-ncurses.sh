#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/ncurses.html
# title  : 8.31. Ncurses-6.6
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Ncurses package contains libraries for terminal-independent handling of character
#   ctx: screens. Approximate build time: 0.2 SBU Required disk space: 47 MB 8.31.1. Installation
#   ctx: of Ncurses Prepare Ncurses for compilation:
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --with-cxx-shared       \
            --enable-pc-files       \
            --with-pkg-config-libdir=/usr/lib/pkgconfig

# --- block 1 --------------------------------------------------
#   ctx: without-normal This prevents Ncurses building and installing static C libraries.
#   ctx: --without-debug This prevents Ncurses building and installing debug libraries.
#   ctx: --with-cxx-shared This makes Ncurses build and install shared C++ bindings. It also
#   ctx: prevents it building and installing static C++ bindings. --enable-pc-files This switch
#   ctx: generates and installs .pc files for pkg-config. Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: tallation of this package will overwrite libncursesw.so.6.6 in-place. It may crash the
#   ctx: shell process which is using code and data from the library file. Install the package
#   ctx: with DESTDIR, and replace the library file correctly using the --remove-destination
#   ctx: option of cp (the header curses.h is also edited to ensure the wide-character ABI to be
#   ctx: used as what we've done in Section 6.3, “Ncurses-6.6”):
make DESTDIR=$PWD/dest install
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i dest/usr/include/curses.h
cp --remove-destination -av dest/* /

# --- block 3 --------------------------------------------------
#   ctx: Many applications still expect the linker to be able to find non-wide-character Ncurses
#   ctx: libraries. Trick such applications into linking with wide-character libraries by means
#   ctx: of symlinks (note that the .so links are only safe with curses.h edited to always use
#   ctx: the wide-character ABI):
for lib in ncurses form panel menu ; do
    ln -sfv lib${lib}w.so /usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc    /usr/lib/pkgconfig/${lib}.pc
done

# --- block 4 --------------------------------------------------
#   ctx: Finally, make sure that old applications that look for -lcurses at build time are still
#   ctx: buildable:
ln -sfv libncursesw.so /usr/lib/libcurses.so

# --- block 5 --------------------------------------------------
#   ctx: If desired, install the Ncurses documentation:
cp -v -R doc -T /usr/share/doc/ncurses-6.6

# --- block 6 --------------------------------------------------
#   ctx: n-wide-character Ncurses libraries since no package installed by compiling from sources
#   ctx: would link against them at runtime. However, the only known binary-only applications
#   ctx: that link against non-wide-character Ncurses libraries require version 5. If you must
#   ctx: have such libraries because of some binary-only application or to be compliant with LSB,
#   ctx: build the package again with the following commands:
#   REVIEWED [drop]: Optional rebuild providing ABI 5 libraries for binary-only applications or LSB compliance. Not needed.
# make distclean
# ./configure --prefix=/usr    \
#             --with-shared    \
#             --without-normal \
#             --without-debug  \
#             --without-cxx-binding \
#             --with-abi-version=5
# make sources libs
# cp -av lib/lib*.so.5* /usr/lib

