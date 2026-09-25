#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/basicnet/libpcap.html
# title  : libpcap-1.10.6
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: p-1.10.6.tar.gz Download MD5 sum: f49b1c1877dcbb3b7f5147429aa047f9 Download size: 968 KB
#   ctx: Estimated disk space required: 11 MB Estimated build time: less than 0.1 SBU libpcap
#   ctx: Dependencies Optional BlueZ-5.86, libnl-3.12.0, libusb-1.0.29, Software distribution for
#   ctx: the DAG, and Septel range of passive network monitoring cards. Installation of libpcap
#   ctx: Install libpcap by running the following commands:
./configure --prefix=/usr &&
make

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. If you want to disable installing the
#   ctx: static library, use this sed:
sed -i '/INSTALL_DATA.*libpcap.a\|RANLIB.*libpcap.a/ s/^/#/' Makefile

# --- block 2 --------------------------------------------------
#   ctx: Now, as the root user:
make install

