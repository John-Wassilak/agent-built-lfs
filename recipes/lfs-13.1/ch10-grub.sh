#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.1-systemd book.
# source : book/13.1/chapter10/grub.html
# title  : 10.4 Using GRUB to Set Up the Boot Process
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: t your LFS system. You may just want to modify your current boot loader, e.g.
#   ctx: Grub-Legacy or GRUB2. Ensure that an emergency boot disk is ready to “rescue” the
#   ctx: computer if the computer becomes unusable (un-bootable). If you do not already have a
#   ctx: boot device, you can create one. In order for the procedure below to work, you need to
#   ctx: jump ahead to BLFS and install xorriso from the libisoburn package.
cd /tmp
grub-mkrescue --output=grub-img.iso
xorriso -as cdrecord -v dev=/dev/cdrw blank=as_needed grub-img.iso

# --- block 1 --------------------------------------------------
#   ctx: ng With BIOS For booting with BIOS, make sure the boot partition is mounted (if using a
#   ctx: separate one) and the BIOS Boot partition exists. After that, install the GRUB files
#   ctx: into /boot/grub and set up the boot track: Warning The following command will overwrite
#   ctx: the current boot loader. Do not run the command if this is not desired, for example, if
#   ctx: using a third party boot manager to manage the MBR.
grub-install /dev/sda --target=i386-pc

# --- block 2 --------------------------------------------------
#   ctx: boot/efi/EFI/BOOT/BOOTX64.EFI: Warning The following command will overwrite the
#   ctx: /boot/efi/EFI/BOOT/BOOTX64.EFI file. If it already exists, it's likely that it's the
#   ctx: entry of another boot loader (for example the GRUB installation from the host distro, or
#   ctx: the Windows Boot Manager). Backup the file so it can be restored later or loaded as a
#   ctx: secondary boot loader by the new GRUB installation from LFS.
grub-install --target=x86_64-efi --removable

# --- block 3 --------------------------------------------------
#   ctx: install the BLFS package efibootmgr to create a boot entry for UEFI. If it's easier, the
#   ctx: package can be installed via the distribution's package manager, if applicable, and used
#   ctx: on the host instead of on the LFS system. This can prevent the need for downloading more
#   ctx: tarballs onto the LFS system for now. First install the package, then mount the EFI
#   ctx: variable file system if it isn't already mounted:
#   TAGS: admon:note   [DISABLED - review]
# mountpoint /sys/firmware/efi/efivars ||
#   mount -v -t efivarfs efivarfs /sys/firmware/efi/efivars

# --- block 4 --------------------------------------------------
#   ctx: Now create a boot entry for the EFI:
#   TAGS: admon:note   [DISABLED - review]
# efibootmgr -c -d /dev/sd<x> \
#   -p <y> -L "LFS" -l '\EFI\BOOT\BOOT<X64>.EFI'

# --- block 5 --------------------------------------------------
#   ctx: isk where the ESP exists. The <y> partition number should match the number of the ESP.
#   ctx: If the ESP is on /dev/sda2, then the partition number would be 2. If you are using
#   ctx: 32-bit UEFI, replace <X64> with IA32. Some (broken) firmware may require additional
#   ctx: parameters for efibootmgr, like --full-dev-path or -e 1 -E. Read the man page
#   ctx: efibootmgr(8) for details. Now unmount the EFI variable file system:
#   TAGS: admon:note   [DISABLED - review]
# umount -v /sys/firmware/efi/efivars

# --- block 6 --------------------------------------------------
#   ctx: 10.4.5 Creating the GRUB Configuration File Generate /boot/grub/grub.cfg:
cat > /boot/grub/grub.cfg << "EOF"
# Begin /boot/grub/grub.cfg
set default=0
set timeout=5

insmod part_gpt
insmod ext2

set root=(hd0,2)
set gfxpayload=1024x768x32

menuentry "GNU/Linux, Linux 7.1.8-lfs-13.1-systemd" {
        linux   /boot/vmlinuz-7.1.8-lfs-13.1-systemd root=/dev/sda2 ro
}
EOF

