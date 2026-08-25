#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/procps-ng.html
# title  : 8.81. Procps-ng-4.0.6
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Procps-ng package contains programs for monitoring processes. Approximate build
#   ctx: time: 0.1 SBU Required disk space: 28 MB 8.81.1. Installation of Procps-ng Prepare
#   ctx: Procps-ng for compilation:
./configure --prefix=/usr                           \
            --docdir=/usr/share/doc/procps-ng-4.0.6 \
            --disable-static                        \
            --disable-kill                          \
            --enable-watch8bit                      \
            --with-systemd

# --- block 1 --------------------------------------------------
#   ctx: The meaning of the configure option: --disable-kill This switch disables building the
#   ctx: kill command; it will be installed from the Util-linux package. --enable-watch8bit This
#   ctx: switch enables the ncursesw support for the watch command, so it can handle 8-bit
#   ctx: characters. Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: To run the test suite, run:
chown -R tester .
su tester -c "PATH=$PATH make check"

# --- block 3 --------------------------------------------------
#   ctx: One test named ps with output flag bsdtime,cputime,etime,etimes is known to fail if the
#   ctx: host kernel is not built with CONFIG_BSD_PROCESS_ACCT enabled. Install the package:
make install

