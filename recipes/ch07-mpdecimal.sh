#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.1-systemd book.
# source : book/13.1/chapter07/mpdecimal.html
# title  : 7.11 mpdecimal-4.0.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The mpdecimal package contains fast C/C++ libraries for correctly-rounded arbitrary
#   ctx: precision decimal floating point arithmetic. Approximate build time: less than 0.1 SBU
#   ctx: Required disk space: 3.3 MB 7.11.1 Installation of mpdecimal Prepare mpdecimal for
#   ctx: compilation:
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpdecimal-4.0.1

# --- block 1 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: Install the package:
make install

