#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/pst/gs.html
# title  : ghostscript-10.06.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ilities, but others of these copies are less-well maintained. To ensure that any future
#   ctx: fixes are applied throughout the whole system, it is recommended that you first install
#   ctx: the released versions of these libraries and then configure Ghostscript to link to them.
#   ctx: If you have installed the recommended dependencies on your system, remove the copies of
#   ctx: freetype, lcms2, libjpeg, libpng, and openjpeg:
rm -rf freetype lcms2mt jpeg libpng openjpeg

# --- block 1 --------------------------------------------------
#   ctx: Compile Ghostscript:
rm -rf zlib &&

./configure --prefix=/usr           \
            --disable-compile-inits \
            --with-system-libtiff   \
            CFLAGS="${CFLAGS:--g -O3} -fPIC" &&
make

# --- block 2 --------------------------------------------------
#   ctx: Note The shared library depends on GTK-3.24.51. It is only used by external programs
#   ctx: like asymptote-3.09, dvisvgm-3.6, and ImageMagick-7.1.2-13. To compile the shared
#   ctx: library libgs.so, run the following additional command as an unprivileged user:
make so

# --- block 3 --------------------------------------------------
#   ctx: This package does not come with a test suite. A set of example files may be used for
#   ctx: testing, but it is only possible after installation of the package. Now, as the root
#   ctx: user:
make install

# --- block 4 --------------------------------------------------
#   ctx: If you built the shared library, install it with:
make soinstall                                     &&
install -v -m644 base/*.h /usr/include/ghostscript &&
ln -sfvn ghostscript /usr/include/ps

# --- block 5 --------------------------------------------------
#   ctx: Now make the documentation accessible from a standard place:
mv -v /usr/share/doc/ghostscript/10.06.0 /usr/share/doc/ghostscript-10.06.0 &&
rmdir /usr/share/doc/ghostscript                                            &&
cp -r examples/ -T /usr/share/ghostscript/10.06.0/examples

# --- block 6 --------------------------------------------------
#   ctx: If you have downloaded the fonts, unpack them to /usr/share/ghostscript and ensure the
#   ctx: ownership of the files are root: root.
tar -xvf ../ghostscript-fonts-std-8.11.tar.gz -C /usr/share/ghostscript --no-same-owner &&
tar -xvf ../gnu-gs-fonts-other-6.0.tar.gz     -C /usr/share/ghostscript --no-same-owner &&
fc-cache -v /usr/share/ghostscript/fonts/

# --- block 7 --------------------------------------------------
#   ctx: You can now test the rendering of various postscript and pdf files from the
#   ctx: /usr/share/ghostscript/10.06.0/examples . To do this, run the following command (in a
#   ctx: X11 session):
#   REVIEWED [drop]: The book's condition: 'run the following command (in a X11 session)'. It opens a viewer window on tiger.eps and waits; lfsbuild runs as root with no display, so on any host it fails or blocks. A check to run by hand after install, not an install step.
# gs -q -dBATCH /usr/share/ghostscript/10.06.0/examples/tiger.eps

