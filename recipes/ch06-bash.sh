#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter06/bash.html
# title  : 6.4. Bash-5.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Bash package contains the Bourne-Again Shell. Approximate build time: 0.2 SBU
#   ctx: Required disk space: 72 MB 6.4.1. Installation of Bash Prepare Bash for compilation:
./configure --prefix=/usr                      \
            --build=$(sh support/config.guess) \
            --host=$LFS_TGT                    \
            --without-bash-malloc

# --- block 1 --------------------------------------------------
#   ctx: The meaning of the configure options: --without-bash-malloc This option turns off the
#   ctx: use of Bash's memory allocation (malloc) function which is known to cause segmentation
#   ctx: faults. By turning this option off, Bash will use the malloc functions from Glibc which
#   ctx: are more stable. Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: Install the package:
make DESTDIR=$LFS install

# --- block 3 --------------------------------------------------
#   ctx: Make a link for the programs that use sh for a shell:
ln -sv bash $LFS/bin/sh

