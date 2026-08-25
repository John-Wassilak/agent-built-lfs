#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/grub.html
# title  : 8.66. GRUB-2.14
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: r system has UEFI support and you wish to boot LFS with UEFI, you need to install GRUB
#   ctx: with UEFI support (and its dependencies) by following the instructions on the BLFS page.
#   ctx: You may skip this package, or install this package and the BLFS GRUB for UEFI package
#   ctx: without conflict (the BLFS page provides instructions for both cases). Warning Unset any
#   ctx: environment variables which may affect the build:
unset {C,CPP,CXX,LD}FLAGS

# --- block 1 --------------------------------------------------
#   ctx: Don't try “tuning” this package with custom compilation flags. This package is a
#   ctx: bootloader. The low-level operations in the source code may be broken by aggressive
#   ctx: optimization. First fix a bug introduced in grub-2.14:
sed 's/--image-base/--nonexist-linker-option/' -i configure

# --- block 2 --------------------------------------------------
#   ctx: Prepare GRUB for compilation:
./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --disable-efiemu  \
            --disable-werror

# --- block 3 --------------------------------------------------
#   ctx: The meaning of the new configure options: --disable-werror This allows the build to
#   ctx: complete with warnings introduced by more recent versions of Flex. --disable-efiemu This
#   ctx: option minimizes what is built by disabling a feature and eliminating some test programs
#   ctx: not needed for LFS. Compile the package:
make

# --- block 4 --------------------------------------------------
#   ctx: The test suite for this packages is not recommended. Most of the tests depend on
#   ctx: packages that are not available in the limited LFS environment. To run the tests anyway,
#   ctx: run make check. Install the package:
make install

