#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/tcl.html
# title  : 8.17. Tcl-8.6.17
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: .9 SBU Required disk space: 91 MB 8.17.1. Installation of Tcl This package and the next
#   ctx: two (Expect and DejaGNU) are installed to support running the test suites for Binutils,
#   ctx: GCC and other packages. Installing three packages for testing purposes may seem
#   ctx: excessive, but it is very reassuring, if not essential, to know that the most important
#   ctx: tools are working properly. Prepare Tcl for compilation:
SRCDIR=$(pwd)
cd unix
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --disable-rpath

# --- block 1 --------------------------------------------------
#   ctx: The meaning of the new configure parameters: --disable-rpath This parameter prevents
#   ctx: hard coding library search paths (rpath) into the binary executable files and shared
#   ctx: libraries. This package does not need rpath for an installation into the standard
#   ctx: location, and rpath may sometimes cause unwanted effects or even security issues. Build
#   ctx: the package:
make

sed -e "s|$SRCDIR/unix|/usr/lib|" \
    -e "s|$SRCDIR|/usr/include|"  \
    -i tclConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.12|/usr/lib/tdbc1.1.12|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.12/generic|/usr/include|"     \
    -e "s|$SRCDIR/pkgs/tdbc1.1.12/library|/usr/lib/tcl8.6|"  \
    -e "s|$SRCDIR/pkgs/tdbc1.1.12|/usr/include|"             \
    -i pkgs/tdbc1.1.12/tdbcConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/itcl4.3.4|/usr/lib/itcl4.3.4|" \
    -e "s|$SRCDIR/pkgs/itcl4.3.4/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/itcl4.3.4|/usr/include|"            \
    -i pkgs/itcl4.3.4/itclConfig.sh

unset SRCDIR

# --- block 2 --------------------------------------------------
#   ctx: The various “sed” instructions after the “make” command remove references to the build
#   ctx: directory from the configuration files and replace them with the install directory. This
#   ctx: is not mandatory for the remainder of LFS, but may be needed if a package built later
#   ctx: uses Tcl. To test the results, issue:
LC_ALL=C.UTF-8 make test

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make install 
chmod 644 /usr/lib/libtclstub8.6.a

# --- block 4 --------------------------------------------------
#   ctx: Make the installed library writable so debugging symbols can be removed later:
chmod -v u+w /usr/lib/libtcl8.6.so

# --- block 5 --------------------------------------------------
#   ctx: Install Tcl's headers. The next package, Expect, requires them.
make install-private-headers

# --- block 6 --------------------------------------------------
#   ctx: Now make a necessary symbolic link:
ln -sfv tclsh8.6 /usr/bin/tclsh

# --- block 7 --------------------------------------------------
#   ctx: Rename a man page that conflicts with a Perl man page:
mv -v /usr/share/man/man3/{Thread,Tcl_Thread}.3

# --- block 8 --------------------------------------------------
#   ctx: Optionally, install the documentation by issuing the following commands:
cd ..
tar -xf ../tcl8.6.17-html.tar.gz --strip-components=1
mkdir -v -p /usr/share/doc/tcl-8.6.17
cp -v -r  ./html/* /usr/share/doc/tcl-8.6.17

