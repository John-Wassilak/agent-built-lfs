#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/bash.html
# title  : 8.37. Bash-5.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Bash package contains the Bourne-Again Shell. Approximate build time: 1.5 SBU
#   ctx: Required disk space: 56 MB 8.37.1. Installation of Bash Prepare Bash for compilation:
./configure --prefix=/usr             \
            --without-bash-malloc     \
            --with-installed-readline \
            --docdir=/usr/share/doc/bash-5.3

# --- block 1 --------------------------------------------------
#   ctx: The meaning of the new configure option: --with-installed-readline This option tells
#   ctx: Bash to use the readline library that is already installed on the system rather than
#   ctx: using its own readline version. Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: Skip down to “Install the package” if not running the test suite. To prepare the tests,
#   ctx: ensure that the tester user can write to the sources tree:
chown -R tester .

# --- block 3 --------------------------------------------------
#   ctx: The test suite of this package is designed to be run as a non-root user who owns the
#   ctx: terminal connected to standard input. To satisfy the requirement, spawn a new pseudo
#   ctx: terminal using Expect and run the tests as the tester user:
LC_ALL=C.UTF-8 su -s /usr/bin/expect tester << "EOF"
set timeout -1
spawn make tests
expect eof
lassign [wait] _ _ _ value
exit $value
EOF

# --- block 4 --------------------------------------------------
#   ctx: Any output from diff (prefixed with < and >) indicates a test failure, unless there is
#   ctx: a message saying the difference can be ignored. The test named run-builtins is known to
#   ctx: fail on some host distros with a difference on the 479 and 480 lines of the output. Some
#   ctx: other tests need the zh_TW.BIG5 and ja_JP.SJIS locales, they are known to fail unless
#   ctx: those locales are installed. Install the package:
make install

# --- block 5 --------------------------------------------------
#   ctx: Run the newly compiled bash program (replacing the one that is currently being
#   ctx: executed):
exec /usr/bin/bash --login

