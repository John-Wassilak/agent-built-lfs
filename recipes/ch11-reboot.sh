#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter11/reboot.html
# title  : 11.3. Rebooting the System
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: es some firmware files to function properly. Ensure a password is set for the root user.
#   ctx: A review of the following configuration files is also appropriate at this point.
#   ctx: /etc/fstab /etc/hosts /etc/inputrc /etc/profile /etc/resolv.conf (optional) /etc/vimrc
#   ctx: Now that we have said that, let's move on to booting our shiny new LFS installation for
#   ctx: the first time! First exit from the chroot environment:
logout

# --- block 1 --------------------------------------------------
#   ctx: Then unmount the virtual file systems:
umount -v $LFS/dev/pts
mountpoint -q $LFS/dev/shm && umount -v $LFS/dev/shm
umount -v $LFS/dev
umount -v $LFS/run
umount -v $LFS/proc
umount -v $LFS/sys

# --- block 2 --------------------------------------------------
#   ctx: If multiple partitions were created, unmount the other partitions before unmounting the
#   ctx: main one, like this:
umount -v $LFS/home
umount -v $LFS

# --- block 3 --------------------------------------------------
#   ctx: Unmount the LFS file system itself:
umount -v $LFS

