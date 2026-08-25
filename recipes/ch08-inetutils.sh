#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/inetutils.html
# title  : 8.42. Inetutils-2.7
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Inetutils package contains programs for basic networking. Approximate build time:
#   ctx: 0.3 SBU Required disk space: 38 MB 8.42.1. Installation of Inetutils First, make the
#   ctx: package build with gcc-14.1 or later:
sed -i 's/def HAVE_TERMCAP_TGETENT/ 1/' telnet/telnet.c

# --- block 1 --------------------------------------------------
#   ctx: Prepare Inetutils for compilation:
./configure --prefix=/usr        \
            --bindir=/usr/bin    \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers

# --- block 2 --------------------------------------------------
#   ctx: ed by the openssh package in the BLFS book. --disable-servers This disables the
#   ctx: installation of the various network servers included as part of the Inetutils package.
#   ctx: These servers are deemed not appropriate in a basic LFS system. Some are insecure by
#   ctx: nature and are only considered safe on trusted networks. Note that better replacements
#   ctx: are available for many of these servers. Compile the package:
make

# --- block 3 --------------------------------------------------
#   ctx: To test the results, issue:
#   TAGS: testsuite   [DISABLED - review]
# make check

# --- block 4 --------------------------------------------------
#   ctx: Install the package:
make install

# --- block 5 --------------------------------------------------
#   ctx: Move a program to the proper location:
mv -v /usr/{,s}bin/ifconfig

