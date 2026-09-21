#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter11/theend.html
# title  : 11.1. The End
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Well done! The new LFS system is installed! We wish you much success with your shiny new
#   ctx: custom-built Linux system. It may be a good idea to create an /etc/lfs-release file. By
#   ctx: having this file, it is very easy for you (and for us if you need to ask for help at
#   ctx: some point) to find out which LFS version is installed on the system. Create this file
#   ctx: by running:
echo 13.0-systemd > /etc/lfs-release

# --- block 1 --------------------------------------------------
#   ctx: Two files describing the installed system may be used by packages that can be installed
#   ctx: on the system later, either in binary form or by building them. The first one shows the
#   ctx: status of your new system with respect to the Linux Standards Base (LSB). To create this
#   ctx: file, run:
cat > /etc/lsb-release << "EOF"
DISTRIB_ID="Linux From Scratch"
DISTRIB_RELEASE="13.0-systemd"
DISTRIB_CODENAME="claude-managed"
DISTRIB_DESCRIPTION="Linux From Scratch"
EOF

# --- block 2 --------------------------------------------------
#   ctx: The second one contains roughly the same information, and is used by systemd and some
#   ctx: graphical desktop environments. To create this file, run:
cat > /etc/os-release << "EOF"
NAME="Linux From Scratch"
VERSION="13.0-systemd"
ID=lfs
PRETTY_NAME="Linux From Scratch 13.0-systemd"
VERSION_CODENAME="claude-managed"
HOME_URL="https://www.linuxfromscratch.org/lfs/"
RELEASE_TYPE="stable"
EOF

