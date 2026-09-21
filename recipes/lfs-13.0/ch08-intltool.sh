#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/intltool.html
# title  : 8.46. Intltool-0.51.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Intltool is an internationalization tool used for extracting translatable strings
#   ctx: from source files. Approximate build time: less than 0.1 SBU Required disk space: 1.5 MB
#   ctx: 8.46.1. Installation of Intltool First fix a warning that is caused by perl-5.22 and
#   ctx: later:
sed -i 's:\\\${:\\\$\\{:' intltool-update.in

# --- block 1 --------------------------------------------------
#   ctx: Note The above regular expression looks unusual because of all the backslashes. What it
#   ctx: does is add a backslash before the right brace character in the sequence '\${' resulting
#   ctx: in '\$\{'. Prepare Intltool for compilation:
./configure --prefix=/usr

# --- block 2 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 3 --------------------------------------------------
#   ctx: To test the results, issue:
#   TAGS: testsuite   [DISABLED - review]
# make check

# --- block 4 --------------------------------------------------
#   ctx: Install the package:
make install
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO

