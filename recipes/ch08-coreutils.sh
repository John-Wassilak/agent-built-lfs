#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/coreutils.html
# title  : 8.61. Coreutils-9.10
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Coreutils package contains the basic utility programs needed by every operating
#   ctx: system. Approximate build time: 1.2 SBU Required disk space: 188 MB 8.61.1. Installation
#   ctx: of Coreutils POSIX requires that programs from Coreutils recognize character boundaries
#   ctx: correctly even in multibyte locales. The following patch fixes this non-compliance and
#   ctx: other internationalization-related bugs.
patch -Np1 -i ../coreutils-9.10-i18n-1.patch

# --- block 1 --------------------------------------------------
#   ctx: Note Many bugs have been found in this patch. When reporting new bugs to the Coreutils
#   ctx: maintainers, please check first to see if those bugs are reproducible without this
#   ctx: patch. Now prepare Coreutils for compilation:
autoreconf -fv
automake -af
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr

# --- block 2 --------------------------------------------------
#   ctx: the standard auxiliary files, but for this package it does not work because configure.ac
#   ctx: specified an old gettext version. automake -af The automake auxiliary files were not
#   ctx: updated by autoreconf due to the missing -i option. This command updates them to prevent
#   ctx: a build failure. FORCE_UNSAFE_CONFIGURE=1 This environment variable allows the package
#   ctx: to be built by the root user. Compile the package:
make

# --- block 3 --------------------------------------------------
#   ctx: Skip down to “Install the package” if not running the test suite. Now the test suite is
#   ctx: ready to be run. First, run the tests that are meant to be run as user root:
#   TAGS: testsuite   [DISABLED - review]
# make NON_ROOT_USERNAME=tester check-root

# --- block 4 --------------------------------------------------
#   ctx: We're going to run the remainder of the tests as the tester user. Certain tests require
#   ctx: that the user be a member of more than one group. So that these tests are not skipped,
#   ctx: add a temporary group and make the user tester a part of it:
groupadd -g 102 dummy -U tester

# --- block 5 --------------------------------------------------
#   ctx: Fix some of the permissions so that the non-root user can compile and run the tests:
chown -R tester . 

# --- block 6 --------------------------------------------------
#   ctx: Now run the tests (using /dev/null for the standard input, or two tests may be broken if
#   ctx: building LFS in a graphical terminal or a session in SSH or GNU Screen because the
#   ctx: standard input is connected to a PTY from host distro, and the device node for such a
#   ctx: PTY cannot be accessed from the LFS chroot environment):
su tester -c "PATH=$PATH make -k RUN_EXPENSIVE_TESTS=yes check" \
   < /dev/null

# --- block 7 --------------------------------------------------
#   ctx: Remove the temporary group:
groupdel dummy

# --- block 8 --------------------------------------------------
#   ctx: Install the package:
make install

# --- block 9 --------------------------------------------------
#   ctx: Move programs to the locations specified by the FHS:
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8

