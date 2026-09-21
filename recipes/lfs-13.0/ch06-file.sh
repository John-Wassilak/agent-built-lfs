#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter06/file.html
# title  : 6.7. File-5.46
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The File package contains a utility for determining the type of a given file or files.
#   ctx: Approximate build time: 0.1 SBU Required disk space: 43 MB 6.7.1. Installation of File
#   ctx: The file command on the build host needs to be the same version as the one we are
#   ctx: building in order to create the signature file. Run the following commands to make a
#   ctx: temporary copy of the file command:
mkdir build
pushd build
  ../configure --disable-bzlib      \
               --disable-libseccomp \
               --disable-xzlib      \
               --disable-zlib
  make
popd

# --- block 1 --------------------------------------------------
#   ctx: The meaning of the new configure option: --disable-* The configuration script attempts
#   ctx: to use some packages from the host distribution if the corresponding library files
#   ctx: exist. It may cause compilation failure if a library file exists, but the corresponding
#   ctx: header files do not. These options prevent using these unneeded capabilities from the
#   ctx: host. Prepare File for compilation:
./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)

# --- block 2 --------------------------------------------------
#   ctx: Compile the package:
make FILE_COMPILE=$(pwd)/build/src/file

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make DESTDIR=$LFS install

# --- block 4 --------------------------------------------------
#   ctx: Remove the libtool archive file because it is harmful for cross compilation:
rm -v $LFS/usr/lib/libmagic.la

