#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.1-systemd book.
# source : book/13.1/chapter08/mpdecimal.html
# title  : 8.53 mpdecimal-4.0.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The mpdecimal package contains fast C/C++ libraries for correctly-rounded arbitrary
#   ctx: precision decimal floating point arithmetic. Approximate build time: 0.1 SBU Required
#   ctx: disk space: 4.4 MB 8.53.1 Installation of mpdecimal Prepare mpdecimal for compilation:
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpdecimal-4.0.1

# --- block 1 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue:
make check_local

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make install

