#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/gawk.html
# title  : 8.63. Gawk-5.3.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Gawk package contains programs for manipulating text files. Approximate build time:
#   ctx: 0.2 SBU Required disk space: 45 MB 8.63.1. Installation of Gawk First, ensure some
#   ctx: unneeded files are not installed:
sed -i 's/extras//' Makefile.in

# --- block 1 --------------------------------------------------
#   ctx: Prepare Gawk for compilation:
./configure --prefix=/usr

# --- block 2 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 3 --------------------------------------------------
#   ctx: To test the results, issue:
#   REVIEWED [drop]: Test suite outside the critical three (glibc/gcc/binutils), so out of scope per the tests policy. It also cannot run any more: ch08-cleanup deleted the 'tester' account it needs, so a re-run fails with "chown: invalid user: 'tester'". These tests did run and pass during the original build, while tester still existed.
# chown -R tester .
# su tester -c "PATH=$PATH make check"

# --- block 4 --------------------------------------------------
#   ctx: Install the package:
rm -f /usr/bin/gawk-5.3.2
make install

# --- block 5 --------------------------------------------------
#   ctx: The meaning of the command: rm -f /usr/bin/gawk-5.3.2 The building system will not
#   ctx: recreate the hard link gawk-5.3.2 if it already exists. Remove it to ensure that the
#   ctx: previous hard link installed in Section 6.9, “Gawk-5.3.2” is updated here. The
#   ctx: installation process already created awk as a symlink to gawk, create its man page as a
#   ctx: symlink as well:
ln -sv gawk.1 /usr/share/man/man1/awk.1

# --- block 6 --------------------------------------------------
#   ctx: If desired, install the documentation:
install -vDm644 doc/{awkforai.txt,*.{eps,pdf,jpg}} -t /usr/share/doc/gawk-5.3.2

