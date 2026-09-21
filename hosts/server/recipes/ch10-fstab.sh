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
# file system   mount-point    type      options             dump  fsck
#                                                                  order

LABEL=LFSROOT   /              ext4      defaults            1     1
LABEL=LFSSWAP   swap           swap      pri=1               0     0

proc            /proc          proc      nosuid,noexec,nodev 0     0
sysfs           /sys           sysfs     nosuid,noexec,nodev 0     0
devpts          /dev/pts       devpts    gid=5,mode=620      0     0
tmpfs           /run           tmpfs     defaults            0     0
devtmpfs        /dev           devtmpfs  mode=0755,nosuid    0     0
tmpfs           /dev/shm       tmpfs     nosuid,nodev        0     0
cgroup2         /sys/fs/cgroup cgroup2   nosuid,noexec,nodev 0     0
EOF

# --- block 1 --------------------------------------------------
#   ctx: rnel to convert the file names using UTF-8 so they can be interpreted in the UTF-8
#   ctx: locale. When installing GRUB with UEFI, the ESP must be formatted as a FAT file system
#   ctx: (EXFAT should not be considered one). In the Linux kernel the VFAT driver handles all
#   ctx: the FAT file systems, so this file will contain vfat regardless. An example of how you
#   ctx: would go about an entry for the ESP would look like this:
#   REVIEWED [drop]: New in LFS 13.1 (2026-09-07 bump): an /boot/efi vfat fstab line for a UEFI system. This host boots GRUB BIOS/MBR on sdb with no separate EFI System Partition (host.toml's [hardware].boot), so there is nothing at /dev/<zzz> for this line to name. True of this machine's disk layout, not of LFS in general -- a UEFI host would want it, hence the drop lives here rather than in the shared file.
# cat >> /etc/fstab << "EOF"
# /dev/<zzz>  /boot/efi  vfat  rw,relatime,codepage=437,iocharset=iso8859-1   0   2
# EOF

