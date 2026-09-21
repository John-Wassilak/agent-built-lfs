#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/bzip2.html
# title  : 8.7. Bzip2-1.0.8
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Bzip2 package contains programs for compressing and decompressing files. Compressing
#   ctx: text files with bzip2 yields a much better compression percentage than with the
#   ctx: traditional gzip. Approximate build time: less than 0.1 SBU Required disk space: 7.3 MB
#   ctx: 8.7.1. Installation of Bzip2 Apply a patch that will install the documentation for this
#   ctx: package:
patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch

# --- block 1 --------------------------------------------------
#   ctx: The following command ensures installation of symbolic links are relative:
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile

# --- block 2 --------------------------------------------------
#   ctx: Ensure the man pages are installed into the correct location:
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile

# --- block 3 --------------------------------------------------
#   ctx: Prepare Bzip2 for compilation with:
make -f Makefile-libbz2_so
make clean

# --- block 4 --------------------------------------------------
#   ctx: The meaning of the make parameter: -f Makefile-libbz2_so This will cause Bzip2 to be
#   ctx: built using a different Makefile file, in this case the Makefile-libbz2_so file, which
#   ctx: creates a dynamic libbz2.so library and links the Bzip2 utilities against it. Compile
#   ctx: and test the package:
make

# --- block 5 --------------------------------------------------
#   ctx: Install the programs:
make PREFIX=/usr install

# --- block 6 --------------------------------------------------
#   ctx: Install the shared library:
cp -av libbz2.so.* /usr/lib
ln -sfv libbz2.so.1.0.8 /usr/lib/libbz2.so

# --- block 7 --------------------------------------------------
#   ctx: The name of the shared library isn't standardized and it varies among distros. The
#   ctx: instruction above has installed libbz2.so.1.0, but some applications, for example Kbd,
#   ctx: expects a different name libbz2.so.1 that some other distros are using. Create a
#   ctx: compatibility symlink for them:
ln -sfv libbz2.so.1.0.8 /usr/lib/libbz2.so.1

# --- block 8 --------------------------------------------------
#   ctx: views of the distro maintainers, not real ABI incompatibilities. In general a library
#   ctx: name difference most likely indicates an ABI incompatibility and it would be very likely
#   ctx: invalid to “hide” the difference via a symlink. Read Section 8.2.1, “Upgrade Issues” for
#   ctx: details about library names. Install the shared bzip2 binary into the /usr/bin
#   ctx: directory, and replace two copies of bzip2 with symlinks:
cp -v bzip2-shared /usr/bin/bzip2
for i in /usr/bin/{bzcat,bunzip2}; do
  ln -sfv bzip2 $i
done

# --- block 9 --------------------------------------------------
#   ctx: Remove a useless static library:
rm -fv /usr/lib/libbz2.a

