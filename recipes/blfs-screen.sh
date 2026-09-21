#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/screen.html
# title  : Screen-5.0.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: build and work properly using an LFS 13.1 platform. Package Information Download
#   ctx: (HTTP): https://ftpmirror.gnu.org/screen/screen-5.0.2.tar.gz Download MD5 sum:
#   ctx: 76c4f967284c1879f0a1423d318471b3 Download size: 872 KB Estimated disk space required: 11
#   ctx: MB Estimated build time: 0.1 SBU Screen Dependencies Optional Linux-PAM-1.7.2
#   ctx: Installation of Screen Install Screen by running the following commands:
./configure --prefix=/usr                   \
            --infodir=/usr/share/info       \
            --mandir=/usr/share/man         \
            --disable-pam                   \
            --enable-socket-dir=/run/screen \
            --with-pty-group=5              \
            --with-system_screenrc=/etc/screenrc &&

sed -i -e "s%/usr/local/etc/screenrc%/etc/screenrc%" {etc,doc}/* &&
make

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make install &&
install -m 644 etc/etcscreenrc /etc/screenrc

