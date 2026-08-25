#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/flex.html
# title  : 8.16. Flex-2.6.4
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Flex package contains a utility for generating programs that recognize patterns in
#   ctx: text. Approximate build time: 0.1 SBU Required disk space: 33 MB 8.16.1. Installation of
#   ctx: Flex Prepare Flex for compilation:
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/flex-2.6.4

# --- block 1 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue:
#   TAGS: testsuite   [DISABLED - review]
# make check

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make install

# --- block 4 --------------------------------------------------
#   ctx: A few programs do not know about flex yet and try to run its predecessor, lex. To
#   ctx: support those programs, create a symbolic link named lex that runs flex in lex emulation
#   ctx: mode, and also create the man page of lex as a symlink:
ln -sv flex   /usr/bin/lex
ln -sv flex.1 /usr/share/man/man1/lex.1

