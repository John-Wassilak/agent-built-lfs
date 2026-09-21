#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.1-systemd book.
# source : book/13.1/chapter10/fstab.html
# title  : 10.2 Creating the /etc/fstab File
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The /etc/fstab file is used by some programs to determine where file systems are to be
#   ctx: mounted by default, in which order, and which must be checked (for integrity errors)
#   ctx: prior to mounting. Create a new file systems table like this:
cat > /etc/fstab << "EOF"
# Begin /etc/fstab

# file system  mount-point  type     options             dump  fsck
#                                                              order

/dev/<xxx>     /            <fff>    defaults            1     1
/dev/<yyy>     swap         swap     pri=1               0     0

# End /etc/fstab
EOF

# --- block 1 --------------------------------------------------
#   ctx: rnel to convert the file names using UTF-8 so they can be interpreted in the UTF-8
#   ctx: locale. When installing GRUB with UEFI, the ESP must be formatted as a FAT file system
#   ctx: (EXFAT should not be considered one). In the Linux kernel the VFAT driver handles all
#   ctx: the FAT file systems, so this file will contain vfat regardless. An example of how you
#   ctx: would go about an entry for the ESP would look like this:
cat >> /etc/fstab << "EOF"
/dev/<zzz>  /boot/efi  vfat  rw,relatime,codepage=437,iocharset=iso8859-1   0   2
EOF

