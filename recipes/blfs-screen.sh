#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/screen.html
# title  : Screen-5.0.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ld and work properly using an LFS 13.0 platform. Package Information Download (HTTP):
#   ctx: https://ftpmirror.gnu.org/screen/screen-5.0.1.tar.gz Download MD5 sum:
#   ctx: fb5e5dfc9353225c2d6929777344b1a6 Download size: 880 KB Estimated disk space required:
#   ctx: 8.9 MB Estimated build time: 0.1 SBU Screen Dependencies Optional Linux-PAM-1.7.2
#   ctx: Installation of Screen Fix an issue causing the info page to fail to build:
sed 's/\([a-z]\)@opensuse/\1@@opensuse/' -i doc/screen.texinfo

# --- block 1 --------------------------------------------------
#   ctx: Install Screen by running the following commands:
./configure --prefix=/usr                   \
            --infodir=/usr/share/info       \
            --mandir=/usr/share/man         \
            --disable-pam                   \
            --enable-socket-dir=/run/screen \
            --with-pty-group=5              \
            --with-system_screenrc=/etc/screenrc &&

sed -i -e "s%/usr/local/etc/screenrc%/etc/screenrc%" {etc,doc}/* &&
make

# --- block 2 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make install &&
install -m 644 etc/etcscreenrc /etc/screenrc

