#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/expect.html
# title  : 8.18. Expect-5.45.4
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: also useful for testing these same applications as well as easing all sorts of tasks
#   ctx: that are prohibitively difficult with anything else. The DejaGnu framework is written in
#   ctx: Expect. Approximate build time: 0.2 SBU Required disk space: 3.9 MB 8.18.1. Installation
#   ctx: of Expect Expect needs PTYs to work. Verify that the PTYs are working properly inside
#   ctx: the chroot environment by performing a simple test:
python3 -c 'from pty import spawn; spawn(["echo", "ok"])'

# --- block 1 --------------------------------------------------
#   ctx: nter the chroot environment following Section 7.4, “Entering the Chroot Environment”.
#   ctx: This issue needs to be resolved before continuing, or the test suites requiring Expect
#   ctx: (for example the test suites of Bash, Binutils, GCC, GDBM, and of course Expect itself)
#   ctx: will fail catastrophically, and other subtle breakages may also happen. Now, make some
#   ctx: changes to allow the package with gcc-15.1 or later:
patch -Np1 -i ../expect-5.45.4-gcc15-1.patch

# --- block 2 --------------------------------------------------
#   ctx: Prepare Expect for compilation:
./configure --prefix=/usr           \
            --with-tcl=/usr/lib     \
            --enable-shared         \
            --disable-rpath         \
            --mandir=/usr/share/man \
            --with-tclinclude=/usr/include

# --- block 3 --------------------------------------------------
#   ctx: The meaning of the configure options: --with-tcl=/usr/lib This parameter is needed to
#   ctx: tell configure where the tclConfig.sh script is located. --with-tclinclude=/usr/include
#   ctx: This explicitly tells Expect where to find Tcl's internal headers. Build the package:
make

# --- block 4 --------------------------------------------------
#   ctx: To test the results, issue:
#   TAGS: testsuite   [DISABLED - review]
# make test

# --- block 5 --------------------------------------------------
#   ctx: Install the package:
make install
ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib

