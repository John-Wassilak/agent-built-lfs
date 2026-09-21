#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter04/creatingminlayout.html
# title  : 4.2. Creating a Limited Directory Layout in the LFS Filesystem
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: the final Linux system. The first step is to create a limited directory hierarchy, so
#   ctx: that the programs compiled in Chapter 6 (as well as glibc and libstdc++ in Chapter 5)
#   ctx: can be installed in their final location. We do this so those temporary programs will be
#   ctx: overwritten when the final versions are built in Chapter 8. Create the required
#   ctx: directory layout by issuing the following commands as root:
mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}

for i in bin lib sbin; do
  ln -sv usr/$i $LFS/$i
done

case $(uname -m) in
  x86_64) mkdir -pv $LFS/lib64 ;;
esac

# --- block 1 --------------------------------------------------
#   ctx: Programs in Chapter 6 will be compiled with a cross-compiler (more details can be found
#   ctx: in section Toolchain Technical Notes). This cross-compiler will be installed in a
#   ctx: special directory, to separate it from the other programs. Still acting as root, create
#   ctx: that directory with this command:
mkdir -pv $LFS/tools

