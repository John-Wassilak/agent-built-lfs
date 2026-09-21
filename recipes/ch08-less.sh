#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.1-systemd book.
# source : book/13.1/chapter08/less.html
# title  : 8.45 Less-704
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Less package contains a text file viewer. Approximate build time: 0.1 SBU Required
#   ctx: disk space: 17 MB 8.45.1 Installation of Less Prepare Less for compilation:
./configure --prefix=/usr --sysconfdir=/etc

# --- block 1 --------------------------------------------------
#   ctx: The meaning of the configure options: --sysconfdir=/etc This option tells the programs
#   ctx: created by the package to look in /etc for the configuration files. Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue:
#   TAGS: testsuite   [DISABLED - review]
# make check

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make install

