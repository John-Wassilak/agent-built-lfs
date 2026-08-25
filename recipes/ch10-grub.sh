#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter10/grub.html
# title  : 10.4. Using GRUB to Set Up the Boot Process
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: LFS system. You may just want to modify your current boot loader, e.g. Grub-Legacy,
#   ctx: GRUB2, or LILO. Ensure that an emergency boot disk is ready to “rescue” the computer if
#   ctx: the computer becomes unusable (un-bootable). If you do not already have a boot device,
#   ctx: you can create one. In order for the procedure below to work, you need to jump ahead to
#   ctx: BLFS and install xorriso from the libisoburn package.
cd /tmp
grub-mkrescue --output=grub-img.iso
xorriso -as cdrecord -v dev=/dev/cdrw blank=as_needed grub-img.iso

# --- block 1 --------------------------------------------------
#   ctx: tition, if a separate one is used). For the following example, it is assumed that the
#   ctx: root (or separate boot) partition is sda2. Install the GRUB files into /boot/grub and
#   ctx: set up the boot track: Warning The following command will overwrite the current boot
#   ctx: loader. Do not run the command if this is not desired, for example, if using a third
#   ctx: party boot manager to manage the Master Boot Record (MBR).
grub-install /dev/sda

# --- block 2 --------------------------------------------------
#   ctx: Note If the system has been booted using UEFI, grub-install will try to install files
#   ctx: for the x86_64-efi target, but those files have not been installed in Chapter 8. If this
#   ctx: is the case, add --target i386-pc to the command above. 10.4.4. Creating the GRUB
#   ctx: Configuration File Generate /boot/grub/grub.cfg:
cat > /boot/grub/grub.cfg << "EOF"
# Begin /boot/grub/grub.cfg
set default=0
set timeout=5

insmod part_gpt
insmod ext2
set root=(hd0,2)
set gfxpayload=1024x768x32

menuentry "GNU/Linux, Linux 6.18.10-lfs-13.0-systemd" {
        linux   /boot/vmlinuz-6.18.10-lfs-13.0-systemd root=/dev/sda2 ro
}
EOF

