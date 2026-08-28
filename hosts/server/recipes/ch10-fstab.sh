#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter10/fstab.html
# title  : 10.2. Creating the /etc/fstab File
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

