#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.1-systemd book.
# source : book/13.1/chapter08/grub.html
# title  : 8.65 GRUB-2.14
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: hod you need. If in doubt, you may follow all of the sections at the cost of extra build
#   ctx: time. After you have installed support for your boot method, then continue building the
#   ctx: rest of the packages in this chapter. Making your LFS system bootable with GRUB will be
#   ctx: discussed in Section 10.4, “Using GRUB to Set Up the Boot Process.” Warning Unset any
#   ctx: environment variables which may affect the build:
unset {C,CPP,CXX,LD}FLAGS

# --- block 1 --------------------------------------------------
#   ctx: Don't try “tuning” this package with custom compilation flags. This package is a
#   ctx: bootloader. The low-level operations in the source code may be broken by aggressive
#   ctx: optimization. Approximate build time: 1.0 SBU Required disk space: 245 MB 8.65.1
#   ctx: Installation of GRUB for BIOS First fix a bug introduced in grub-2.14:
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

# --- block 5 --------------------------------------------------
#   ctx: 8.65.2 Installation of GRUB for 64-bit UEFI If you want to boot with 64-bit UEFI, you
#   ctx: should build support for it. First, if you built GRUB from the section above, clean the
#   ctx: source tree:
#   REVIEWED [drop]: New in LFS 13.1 (2026-09-07 bump): builds a second, UEFI-targeted GRUB (--target=x86_64-efi, then --target=i386, both --with-platform=efi). This host boots BIOS/MBR only (host.toml's [hardware].boot); the BIOS-targeted build a few blocks up is the one server actually uses. Blocks 5-12 are this whole UEFI-target build-clean-build sequence -- dropped as a set, not selectively, since none of it produces anything this host installs.
# make clean

# --- block 6 --------------------------------------------------
#   ctx: Now configure GRUB for 64-bit UEFI support:
#   REVIEWED [drop]: Part of the UEFI-target GRUB build -- see block 5's reason.
# ./configure --prefix=/usr       \
#             --sysconfdir=/etc   \
#             --target=x86_64     \
#             --with-platform=efi \
#             --disable-efiemu    \
#             --disable-werror

# --- block 7 --------------------------------------------------
#   ctx: The meaning of the new configure options: --target=x86_64 This defines that the UEFI
#   ctx: firmware architecture is x86_64, which GRUB should target. --with-platform=efi This
#   ctx: specifies that EFI is a platform GRUB should target. In combination with
#   ctx: --target=x86_64, GRUB will have the ability to target the x86_64-efi platform. Compile
#   ctx: the package for 64-bit UEFI support:
#   REVIEWED [drop]: Part of the UEFI-target GRUB build -- see block 5's reason.
# make

# --- block 8 --------------------------------------------------
#   ctx: Install support for 64-bit UEFI:
#   REVIEWED [drop]: Part of the UEFI-target GRUB build -- see block 5's reason.
# make install

# --- block 9 --------------------------------------------------
#   ctx: 8.65.3 Installation of GRUB for 32-bit UEFI If you want to boot with 32-bit UEFI, which
#   ctx: is very rare, you should build support for it. First, if you built GRUB from any of the
#   ctx: sections above, clean the source tree:
#   REVIEWED [drop]: Part of the UEFI-target GRUB build -- see block 5's reason.
# make clean

# --- block 10 --------------------------------------------------
#   ctx: Now configure GRUB for 32-bit UEFI support:
#   REVIEWED [drop]: Part of the UEFI-target GRUB build -- see block 5's reason.
# ./configure --prefix=/usr       \
#             --sysconfdir=/etc   \
#             --target=i386       \
#             --with-platform=efi \
#             --disable-efiemu    \
#             --disable-werror

# --- block 11 --------------------------------------------------
#   ctx: The meaning of the new configure options: --target=i386 This defines that the UEFI
#   ctx: firmware architecture is i386/32-bit, which GRUB should target. In combination with
#   ctx: --with-platform=efi, GRUB will have the ability to target the i386-efi platform. Compile
#   ctx: the package for 32-bit UEFI support:
#   REVIEWED [drop]: Part of the UEFI-target GRUB build -- see block 5's reason.
# make

# --- block 12 --------------------------------------------------
#   ctx: Install support for 32-bit UEFI:
#   REVIEWED [drop]: Part of the UEFI-target GRUB build -- see block 5's reason.
# make install

