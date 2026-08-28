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
# Begin /etc/fstab

# file system  mount-point  type     options             dump  fsck
#                                                              order

/dev/<xxx>     /            <fff>    defaults            1     1
/dev/<yyy>     swap         swap     pri=1               0     0

# End /etc/fstab
EOF

