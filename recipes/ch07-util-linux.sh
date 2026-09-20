#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.1-systemd book.
# source : book/13.1/chapter07/util-linux.html
# title  : 7.14 Util-linux-2.42.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Util-linux package contains miscellaneous utility programs. Approximate build time:
#   ctx: 0.2 SBU Required disk space: 211 MB 7.14.1 Installation of Util-linux The FHS recommends
#   ctx: using the /var/lib/hwclock directory instead of the usual /etc directory as the location
#   ctx: for the adjtime file. Create this directory with:
mkdir -pv /var/lib/hwclock

# --- block 1 --------------------------------------------------
#   ctx: Prepare Util-linux for compilation:
./configure --libdir=/usr/lib     \
            --runstatedir=/run    \
            --disable-chfn-chsh   \
            --disable-login       \
            --disable-nologin     \
            --disable-su          \
            --disable-setpriv     \
            --disable-runuser     \
            --disable-pylibmount  \
            --disable-static      \
            --disable-liblastlog2 \
            --without-python      \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.42.2

# --- block 2 --------------------------------------------------
#   ctx: red library file in the same directory (/usr/lib) directly. --disable-* These switches
#   ctx: prevent warnings about building components that require packages not in LFS or not
#   ctx: installed yet. --without-python This switch disables using Python. It avoids trying to
#   ctx: build unneeded bindings. runstatedir=/run This switch sets the location of the socket
#   ctx: used by uuidd and libuuid correctly. Compile the package:
make

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make install

